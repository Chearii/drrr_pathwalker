-- A_pw_core
-- the bare essentials of the pathwalker system; everything in here gets reused several functions over

if (pathwalker_modload) then
    -- tell the server "don't load me twice"
    print("\x82".."Some mod's already running the Pathwalker system.".."\x80")
    return
end

local PW_DEBUG_MODE = 0

if (PW_DEBUG_MODE) then
    print("\x82".."[RUNNING IN DEBUG MODE, EXPECT LAG]".."\x80")
end

local FRACBITS = FRACBITS
local FRACUNIT = FRACUNIT

local FRAC_1div3 = (FRACUNIT / 3)
local FRAC_1div3neg = (FRAC_1div3 * -1)

-- LONGFRACUNIT, for path progress
local LONGFRACBITS = 24
local FRACTOLONGBITS = LONGFRACBITS - FRACBITS
local LONGFRACUNIT = (1 << LONGFRACBITS)
local FRACTOLONGMUL = (1 << FRACTOLONGBITS)

local function pw_progressMul(a, b)
    return FixedMul(a / FRACTOLONGMUL, b)
end

local function pw_longtofrac(x)
    return x / FRACTOLONGMUL
end

local function pw_longtofracshift(x)
    return x >> FRACTOLONGBITS
end

-- objectdef

freeslot("MT_PATHWALKERPOINT", "S_PATHWALKERPOINT", "SPR_PWPP")

states[S_PATHWALKERPOINT] = {SPR_NULL, A, -1, nil, 0, 0, 0}

mobjinfo[MT_PATHWALKERPOINT] = {
    doomednum = 12405,
    spawnstate = S_PATHWALKERPOINT,
    spawnhealth = 1000,
    radius = 1*FRACUNIT,
    height = 1*FRACUNIT,
    flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIP|MF_NOBLOCKMAP|MF_NOTHINK,
}

local MAPTHING_PWPOINT = 12405

-- mapthing flags
local PWF_CONTROL = 1 -- enables flag setting/overriding for this point
local PWF_DONTLOOP = 2 -- sets this path's "loop" boolean to false
local PWF_REVERSE = 4 -- pathwalkers will initially travel this path backwards
local PWF_SHOWPATH = 8 -- visualizes the path in full

-- global pathwalker struct
local pathwalker = {}
local pw_internal = {}

-- set on map load; tells pw_internal to handle path allocation
pathwalker.polling_ready = false

-- set to "true" when polling finishes and paths exist in the map
pathwalker.ready = false

-- stores all mdat_path structs for the given map (see: C_pw_struct.lua for more info)
pathwalker.map_paths = {}

-- stores all nkm_path_entry structs for the given map
pathwalker.nkm_paths = {}

-- stores all *actual* paths into (temporary) memory; cleared out on map change
pathwalker.path_cache = {}

-- depending on the value, this handles various elements of the path allocation process
pw_internal.polling = 0

-- set up coefficient metatable
local coef_atable_size = 10
local hermite_coef = {}

function hermite_coef.new()
    local self = {}

    self.a = {}

    for i = 1, coef_atable_size do
        self.a[i] = 0
    end

    self.tpow3 = 0

    if (PW_DEBUG_MODE == 2) then
        local struct_safe = true

        if (self.tpow3 == nil) then
            struct_safe = false
            print("tpow3 = NULL")
        end

        if (self.a == nil) then
            struct_safe = false
            print("a = NULL")
        else
            for i = 1, coef_atable_size do
                if (self.a[i] == nil) then
                    struct_safe = false
                end
            end
        end



        assert(struct_safe, "setmetatable created NULL struct!")
    end

    return self
end

/*--------------------------------------------------------------------------
    hooks
--------------------------------------------------------------------------*/

local function pw_internal_sortMapPoints(a, b)
    return (a.pointIndex < b.pointIndex)
end

local function pw_internal_mapLoadHook()
    if (pathwalker.ready) then
        -- probably netsaves; not our problem!
        print("hello gorgeous")
        return
    end

    for t in mapthings.iterate do
        if (t.type == MAPTHING_PWPOINT) then
            --print("X: "..tostring(t.mobj.x)..", Y: "..tostring(t.mobj.y)..", Z: "..tostring(t.mobj.z))
            --print("tid (path id): "..tostring(t.tid)..", point id: "..tostring(t.args[0]))

            local nkm_path = pathwalker.nkm_paths[t.tid & 0xFFFF]
            local path_data = pathwalker.map_paths[t.tid & 0xFFFF]

            local made_new_nkm_path, made_new_path_data, sort_this_path

            if (nkm_path == nil) then
                nkm_path = nkm_path_entry.new()
                nkm_path.id = t.tid
                nkm_path.parent_id = t.tid
                nkm_path.loop = true
                --print("allocated new nkm_path_entry at index "..tostring(t.tid))
                made_new_nkm_path = true
            end

            if (path_data == nil) then
                path_data = mdat_path.new()
                path_data.path_id = t.tid
                --print("allocated new path data struct at index "..tostring(t.tid))
                made_new_path_data = true
            end

            local my_point = path_data.poit[t.args[0] & 0xFFFF]

            if ((my_point ~= nil) and my_point.pointIndex ~= (t.args[0] & 0xFFFF)) then
                my_point = nil
            end

            if (my_point == nil) then
                my_point = nkm_poit_entry.new()

                my_point.position = FV3_Init(t.mobj.x, t.mobj.z, t.mobj.y)

                -- need to add an ID field for sorting
                my_point.pointIndex = t.args[0] & 0xFFFF

                if (t.args[1] & PWF_CONTROL) then
                    -- control point; set path data here
                    nkm_path.loop = ((t.args[1] & PWF_DONTLOOP) != PWF_DONTLOOP)
                    nkm_path.isForwards = ((t.args[1] & PWF_REVERSE) != PWF_REVERSE)

                    path_data.make_thoks = ((t.args[1] & PWF_SHOWPATH) == PWF_SHOWPATH)

                    --local loop_string = (nkm_path.loop) and "looping" or "not looping"
                    --local dir_string = (nkm_path.isForwards) and "forwards" or "backwards"

                    --print("path is "..(loop_string).." and "..(dir_string))
                end

                table.insert(path_data.poit, my_point)
                --print("allocated "..tostring(#path_data.poit).." points into the path")
            end

            if (made_new_nkm_path) then
                pathwalker.nkm_paths[t.tid & 0xFFFF] = nkm_path
            end

            if (made_new_path_data) then
                pathwalker.map_paths[t.tid & 0xFFFF] = path_data
            end

            pathwalker.polling_ready = true

        end
    end

    for i = 1, #pathwalker.map_paths do
        table.sort(pathwalker.map_paths[i].poit, pw_internal_sortMapPoints)

        if (pathwalker.map_paths[i].make_thoks) then
            local thok
            for j = 1, #pathwalker.map_paths[i].poit do
                thok = P_SpawnMobj(pathwalker.map_paths[i].poit[j].position.x,pathwalker.map_paths[i].poit[j].position.z,pathwalker.map_paths[i].poit[j].position.y,MT_THOK)
                thok.tics = -1
                thok.fuse = -1
                thok.sprite = SPR_PWPP
            end
        end

        pathwalker.map_paths[i].make_thoks = nil

        pathwalker.nkm_paths[i].pointCount = #pathwalker.map_paths[i].poit
        --print("[Pathwalker] allocated path "..tostring(i).." with "..tostring(#pathwalker.map_paths[i].poit).." points")
    end
end

local function pw_internal_polling()
    if (not pathwalker.polling_ready) then return end

    local path

    if (pw_internal.polling < 1) then

        for i = 1, #pathwalker.map_paths do
            path = pw_path.new()

            path:setup(i, pathwalker.nkm_paths[pathwalker.map_paths[i].path_id])

            pathwalker.path_cache[pathwalker.nkm_paths[i].id] = path
        end

        pw_internal.polling = 1
    end

    if (pw_internal.polling >= 1) then
        pw_internal.polling = 0
        pathwalker.polling_ready = false
        pathwalker.ready = true
    end
end

local function pw_internal_post_think()
    pw_internal_polling()

    pathwalker.netsync = false
end

local function pw_internal_mapChangeHook()
    -- clean up our mess on mapchange

    pathwalker.nkm_paths = nil
    pathwalker.map_paths = nil
    pathwalker.path_cache = nil

    pathwalker.nkm_paths = {}
    pathwalker.map_paths = {}
    pathwalker.path_cache = {}
    pathwalker.ready = false
    pathwalker.netsync = false
end

/*--------------------------------------------------------------------------
    test routines
--------------------------------------------------------------------------*/

local test_herm = hermite_coef.new()

print("test_herm.tpow3: "..tostring(test_herm.tpow3))

print("hermite_coef OK!")

-- assert this stuff works

local mul = FixedMul(LONGFRACUNIT, FRACUNIT)
print("FixedMul(1.0L, 1.0): "..tostring(mul))
assert(mul == LONGFRACUNIT, "FixedMul(LONGFRACUNIT, FRACUNIT) is not LONGFRACUNIT!")

mul = pw_progressMul(LONGFRACUNIT, FRACUNIT)
print("pw_progressMul(1.0L, 1.0): "..tostring(mul))
assert(mul == FRACUNIT, "pw_progressMul(LONGFRACUNIT, FRACUNIT) is not FRACUNIT!")

mul = pw_progressMul(LONGFRACUNIT, LONGFRACUNIT)
print("pw_progressMul(1.0L, 1.0L): "..tostring(mul))
assert(mul == LONGFRACUNIT, "pw_progressMul(LONGFRACUNIT, LONGFRACUNIT) is not LONGFRACUNIT!")

print("pw_progressMul OK!")

-- ok, we gucci; let's get things set up
addHook("MapLoad", pw_internal_mapLoadHook)
addHook("PostThinkFrame", pw_internal_post_think)
addHook("MapChange", pw_internal_mapChangeHook)

-- rawset nearly everything here

-- constants
rawset(_G, "FRAC_1div3", FRAC_1div3)
rawset(_G, "FRAC_1div3neg", FRAC_1div3neg)

rawset(_G, "LONGFRACBITS", LONGFRACBITS)
rawset(_G, "LONGFRACUNIT", LONGFRACUNIT)

rawset(_G, "FRACTOLONGBITS", FRACTOLONGBITS)
rawset(_G, "FRACTOLONGMUL", FRACTOLONGMUL)

rawset(_G, "PWF_CONTROL", PWF_CONTROL)
rawset(_G, "PWF_DONTLOOP", PWF_DONTLOOP)
rawset(_G, "PWF_REVERSE", PWF_REVERSE)

-- functions
rawset(_G, "pw_progressMul", pw_progressMul)
rawset(_G, "pw_longtofrac", pw_longtofrac)
rawset(_G, "pw_longtofracshift", pw_longtofracshift)

-- structs and metatables
rawset(_G, "pathwalker", pathwalker)
rawset(_G, "hermite_coef", hermite_coef)

-- debug mode
rawset(_G, "PW_DEBUG_MODE", PW_DEBUG_MODE)

print("rawsets OK!")

print("[A] Core OK!")
