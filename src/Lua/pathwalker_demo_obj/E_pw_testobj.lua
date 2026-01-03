-- E_pw_testobj
-- stupid test object; this can freely be removed, as it serves no purpose beyond being a basic example object

if (pathwalker_testobj_load) then
    -- duck out
    return
end

freeslot("MT_PATHWALKERTEST", "S_PATHWALKERTEST")

states[S_PATHWALKERTEST] = {SPR_KART, A, -1, nil, 0, 0, 0}

mobjinfo[MT_PATHWALKERTEST] = {
    doomednum = 12406,
    spawnstate = S_PATHWALKERTEST,
    spawnhealth = 1000,
    radius = 20*FRACUNIT,
    height = 12*FRACUNIT,
    flags = MF_SCENERY|MF_NOGRAVITY|MF_NOCLIPTHING,
}

local OSCILLATE_SPEEDFRAC = (3 * FRACUNIT / 2)

local function pw_test_thinker(mo)
    if (not pathwalker.ready) then return end

    local pos = FV3_Init(mo.x, mo.z, mo.y)

    if (mo.spawnpoint) then
        if (mo.spawnpoint.args[2] & 1) and (mo.pathwalker) then
            mo.pathwalker:setSpeed(OSCILLATE_SPEEDFRAC + FixedMul(OSCILLATE_SPEEDFRAC, sin(FixedAngle(leveltime * FRACUNIT / 2))))
        end

        if (mo.spawnpoint.stringargs[0]) then
            --print("my skin is "..tostring(mo.spawnpoint.stringargs[0]))
            mo.skin = mo.spawnpoint.stringargs[0]
            mo.sprite = SPR_PLAY
            mo.sprite2 = SPR2_STIN
            mo.color = skins[mo.spawnpoint.stringargs[0]].prefcolor
        end

        if (mo.spawnpoint.args[2] & 2) and (not mo.pw_flying) then
            mo.state = S_MOSQUIIDLE
            mo.color = SKINCOLOR_KETCHUP
            mo.scale = $ * 3 / 2
            mo.pw_flying = true

            if (mo.spawnpoint.args[2] & 4) then
                mo.pw_trace_linear = true
            end
        end
    end

    if (not mo.pathwalker) then
        if (mo.spawnpoint) then
            mo.pw_pathId = mo.spawnpoint.tid

            local poit_id = pathwalker.findPointId(mo.spawnpoint.tid,mo.spawnpoint.args[0])

            mo.pathwalker = pw_pathwalker.new(mo)
            mo.pathwalker:initFromObject(mo, (3 * FRACUNIT) * mo.spawnpoint.args[1] / 100,poit_id)

            mo.pathwalker.curPoit = pathwalker.getPathPoint(mo.spawnpoint.tid,poit_id)
            local path_point = mo.pathwalker.curPoit
            mo.pw_init_z = path_point.position.y
        end
    else
        local prev_pos = FV3_Init(mo.x, mo.y, mo.z)
        local update_result = mo.pathwalker:update() or false

        if (mo.pw_flying) then
            -- fly!!

            if (mo.pw_trace_linear) then
                mo.pathwalker:calcCurrentPointLinearXYZ(pos)
            else
                mo.pathwalker:calcCurrentPointXYZ(pos)
            end
        else
            if (mo.pw_trace_linear) then
                mo.pathwalker:calcCurrentPointLinearXYZ(pos)
            else
                mo.pathwalker:calcCurrentPointXYLinearZ(pos)
            end
        end

        local vel = FV3_Init()
        FV3_SubApply(pos, prev_pos, vel)

        mo.momx = vel.x
        mo.momy = vel.y
        if (mo.pw_flying) then mo.momz = vel.z end

        mo.angle = K_MomentumAngleEx(mo, FRACUNIT * 6 / 100)
    end
end

addHook("MobjThinker", pw_test_thinker, MT_PATHWALKERTEST)

rawset(_G, "pathwalker_testobj_load", 1)
