-- C_pw_struct
-- path structs, allocation

assert(pathwalker ~= nil, "struct 'pathwalker' does not exist!")

if (pathwalker_modload) then
    -- duck out
    return
end

function pathwalker.findPointId(path, poit_idx)
    local map_path = pathwalker.map_paths[path]

    if (map_path ~= nil) then
        for i = 1, #map_path.poit do
            if (map_path.poit[i].pointIndex == poit_idx) then
                return i
            end
        end
    end

    return poit_idx
end

function pathwalker.getPathPoint(path, poit_idx)
    local map_path = pathwalker.map_paths[path]

    if (map_path ~= nil) then
        return map_path.poit[poit_idx]
    end

    return nil
end

-- map data, stores path points and link IDs to nkm_path_entry structs
local mdat_path = {}
mdat_path.__index = mdat_path

function mdat_path.new()
    local self = setmetatable({}, mdat_path)
    self.path_id = 0 -- our nkm_path_entry's ID
    self.poit = {}

    return self
end

-- NKM paths and points, on map load, these are loaded in from mapthings
local nkm_path_entry = {}
nkm_path_entry.__index = nkm_path_entry

function nkm_path_entry.new()
    local self = setmetatable({}, nkm_path_entry)
    self.id = 0
    self.parent_id = 0 -- the mdat_path we belong to
    self.loop = false
    self.isForwards = true
    self.pointCount = 0

    return self
end

function nkm_path_entry:getPoint(poit_idx)
    local my_path = pathwalker.map_paths[self.parent_id]

    if (my_path ~= nil) then
        return my_path.poit[poit_idx]
    end

    return nil
end

local nkm_poit_entry = {}
nkm_poit_entry.__index = nkm_poit_entry

function nkm_poit_entry.new()
    local self = setmetatable({}, nkm_poit_entry)
    self.position = FV3_Init()
    self.pointIndex = 0
    self.unknown1 = 0
    self.duration = 0
    self.unknown2 = 0 -- union of 2 uint16s into a uint32; not making this an array for sanity reasons

    return self
end

/*--------------------------------------------------------------------------
    pw_path_part
--------------------------------------------------------------------------*/
local pw_path_part = {}
pw_path_part.__index = pw_path_part

function pw_path_part.new()
    local self = setmetatable({}, pw_path_part)
    self.p0 = FV3_Init()
    self.p1 = FV3_Init()
    self.p2 = FV3_Init()
    self.p3 = FV3_Init()
    self.length = 0
    self.oneDivLength = 0
    self.hermLength = 0
    self.oneDivHermLength = 0
    self.linLength = 0
    self.oneDivLinLength = 0
    self.field10_0x48 = FV3_Init()

    return self
end

function pw_path_part:debugtest()
    print(":troll_face:")
    print(tostring(self.length))
end

function pw_path_part:setup(a2,a3,param_4,param_5,param_6,param_7)
    local local_74

    local uVar2, uVar6, uVar7
    local iVar3, fVar4, iVar5

    local VStack_60 = FV3_Init()
    local local_54 = FV3_Init()
    local local_48 = FV3_Init()
    local local_3c = FV3_Init()
    local local_30 = FV3_Init()
    local local_24 = FV3_Init()
  
    uVar6 = 0
    local_74 = 0

    FV3_Copy(self.p0, param_5)
    FV3_Copy(self.p3, param_6)

    VStack_60 = FV3_SubApply(param_6,param_5,VStack_60)
    uVar2 = FV3_NormalizeEx(VStack_60,local_54)

    if (uVar2 == 0) then
        FV3_Copy(self.p1, self.p0)
        FV3_Copy(self.p2, self.p3)

        self.length = 0
        self.oneDivLength = 0
    
        if (a3 != 0) then
            FV3_Copy(self.field10_0x48, FV3_UnitY())
            return
        end
    else
        if (param_4 == nil) then
            FV3_Copy(self.p1, self.p0)
        else
            FV3_SubApply(param_6,param_4,local_48)
            iVar3 = FV3_NormalizeEx(local_48,local_48)
            if (iVar3 == 0) then
                FV3_Copy(self.p1, self.p0)
            else
                fVar4 = FV3_Dot(local_54,local_48)
                uVar6 = FixedMul(uVar2, (FRACUNIT - fVar4) / 2);

                if (a2 == 0) then
                    uVar7 = uVar2 + uVar6
                    FV3_MulEx(local_48,uVar7,local_3c)
                else
                    FV3_MulEx(local_48,uVar2,local_3c)
                end

                FV3_MultAddEx(local_3c,self.p0,FRAC_1div3,self.p1)
            end
        end

        if (param_7 == nil) then
            FV3_Copy(self.p2, self.p3)
        else
            FV3_SubApply(param_7,param_5,local_30)
            iVar3 = FV3_NormalizeEx(local_30,local_30)

            if (iVar3 == 0) then
                FV3_Copy(self.p2, self.p3)
            else
                fVar4 = FV3_Dot(local_54,local_30)
                local_74 = FixedMul(uVar2, (FRACUNIT - fVar4) / 2)

                if (a2 == 0) then
                    uVar7 = uVar2 + local_74
                    FV3_MulEx(local_30,uVar7,local_24)
                else
                    FV3_MulEx(local_30,uVar2,local_24)
                end

                FV3_MultAddEx(local_24,self.p3,FRAC_1div3neg,self.p2)
            end
        end

        self.linLength = uVar2
        fVar4 = FixedDiv(LONGFRACUNIT,self.linLength)
        self.oneDivLinLength = fVar4

        self.hermLength = local_74 + uVar2 + uVar6
        fVar4 = FixedDiv(LONGFRACUNIT,self.hermLength)
        self.oneDivHermLength = fVar4

        self.linLength = uVar2
        self.length = self.hermLength
        self.oneDivLength = self.oneDivHermLength

        if (a3 != 0) then
            uVar2 = FV3_Dot(local_54,FV3_UnitY())
            FV3_MulEx(local_54,uVar2,self.field10_0x48)
            
            iVar5 = FV3_MagnitudeSqr(self.field10_0x48)
            
            if (iVar5 < 2) then
                iVar5 = 0
            else
                iVar5 = FV3_NormalizeEx(self.field10_0x48,self.field10_0x48)
            end

            if (iVar5 == 0) then
                FV3_Copy(self.field10_0x48, FV3_UnitY())
            end
        end
    end
end

/*--------------------------------------------------------------------------
    pw_path
--------------------------------------------------------------------------*/
local pw_path = {}
pw_path.__index = pw_path

function pw_path.new()
    local self = setmetatable({}, pw_path)
    self.parts = {} -- contains pw_path_part
    self.partCount = 0
    self.loop = false
    self.isForwards = true

    return self
end

function pw_path:setup(id, nkm_path)

    local uVar1 = nkm_path.pointCount
    local _pointCount = nkm_path.pointCount
    self.partCount = _pointCount
    self.loop = nkm_path.loop
    self.isForwards = nkm_path.isForwards

    if (not self.loop) then self.partCount = $ - 1 end

    if (self.parts ~= nil) then self.parts = nil end
    self.parts = {}

    local path = id
    local cur_part
    local pnVar3, pnVar4, pnVar5, pnVar6
    if (_pointCount == 2) then
        pnVar3 = nkm_path:getPoint(1) --pathwalker.getPathPoint(path,1)
        pnVar4 = nkm_path:getPoint(2) --pathwalker.getPathPoint(path,2)

        --pw_setupPathPart(pppVar9->parts,0,1,0,pnVar3,pnVar4,0);
        table.insert(self.parts, 1, pw_path_part.new())
        cur_part = self.parts[1]

        assert(cur_part ~= nil, "couldn't find inserted pw_path_part at index 1")

        cur_part:setup(0,1,nil,pnVar3.position,pnVar4.position,nil)

        if (self.loop) then
            pnVar3 = nkm_path:getPoint(2)
            pnVar4 = nkm_path:getPoint(1)

            table.insert(self.parts, 2, pw_path_part.new())
            cur_part = self.parts[2]

            assert(cur_part ~= nil, "couldn't find inserted pw_path_part at index 2")

            cur_part:setup(0,1,nil,pnVar3.position,pnVar4.position,nil)
            return
        end
    else
        if (not self.loop) then
            pnVar3 = nkm_path:getPoint(1)
            pnVar4 = nkm_path:getPoint(2)
            pnVar5 = nkm_path:getPoint(3)

            if (self.parts[1] == nil) then
                table.insert(self.parts, 1, pw_path_part.new())
            end

            assert(self.parts[1] ~= nil, "couldn't find inserted pw_path_part at index 1")

            self.parts[1]:setup(0,1,nil,pnVar3.position,pnVar4.position,pnVar5.position)
        else
            pnVar3 = nkm_path:getPoint(uVar1)
            pnVar4 = nkm_path:getPoint(1)
            pnVar5 = nkm_path:getPoint(2)
            pnVar6 = nkm_path:getPoint(3)

            if (self.parts[1] == nil) then
                table.insert(self.parts, 1, pw_path_part.new())
            end

            assert(self.parts[1] ~= nil, "couldn't find inserted pw_path_part at index 1")

            self.parts[1]:setup(0,1,pnVar3.position,pnVar4.position,pnVar5.position,pnVar6.position)
        end

        local iVar7 = 1;
        if ((_pointCount - 2) > 1) then
            repeat
                uVar1 = iVar7 & 0xFFFF
                pnVar3 = nkm_path:getPoint(uVar1)
                pnVar4 = nkm_path:getPoint(uVar1 + 1)
                pnVar5 = nkm_path:getPoint(uVar1 + 2)
                pnVar6 = nkm_path:getPoint(uVar1 + 3)

                if (pnVar5 ~= nil) then
                    pnVar5 = pnVar5.position
                end

                if (pnVar6 ~= nil) then
                    pnVar6 = pnVar6.position
                end

                if (self.parts[iVar7 + 1] == nil) then
                    table.insert(self.parts, iVar7 + 1, pw_path_part.new())
                end

                assert(self.parts[iVar7 + 1] ~= nil, "couldn't find inserted pw_path_part at index "..tostring(iVar7 + 1))

                self.parts[iVar7 + 1]:setup(0,1,pnVar3.position,pnVar4.position,pnVar5,pnVar6)

                iVar7 = $ + 1
            until (iVar7 >= (_pointCount - 2))
        end

        uVar1 = iVar7 & 0xFFFF
        if (not self.loop) then
            pnVar3 = nkm_path:getPoint(uVar1)
            pnVar4 = nkm_path:getPoint(uVar1 + 1)
            pnVar5 = nkm_path:getPoint(uVar1 + 2)

            if (pnVar4 ~= nil) then
                pnVar4 = pnVar4.position
            end

            if (pnVar5 ~= nil) then
                pnVar5 = pnVar5.position
            end

            if (self.parts[iVar7 + 1] == nil) then
                table.insert(self.parts, iVar7 + 1, pw_path_part.new())
            end

            assert(self.parts[iVar7 + 1] ~= nil, "couldn't find inserted pw_path_part at index "..tostring(iVar7 + 1))

            self.parts[iVar7 + 1]:setup(0,1,pnVar3.position,pnVar4,pnVar5,nil);
        else
            pnVar3 = nkm_path:getPoint(uVar1)
            pnVar4 = nkm_path:getPoint(uVar1 + 1)
            pnVar5 = nkm_path:getPoint(uVar1 + 2)
            pnVar6 = nkm_path:getPoint(1)

            if (pnVar4 ~= nil) then
                pnVar4 = pnVar4.position
            end

            if (pnVar5 ~= nil) then
                pnVar5 = pnVar5.position
            end

            if (self.parts[iVar7 + 17] == nil) then
                table.insert(self.parts, iVar7 + 1, pw_path_part.new())
            end

            assert(self.parts[iVar7 + 1] ~= nil, "couldn't find inserted pw_path_part at index "..tostring(iVar7 + 1))

            self.parts[iVar7 + 1]:setup(0,1,pnVar3.position,pnVar4,pnVar5,pnVar6.position);
        end

        if (self.loop) then
            pnVar3 = nkm_path:getPoint(uVar1 + 1)
            pnVar4 = nkm_path:getPoint(uVar1 + 2)
            pnVar5 = nkm_path:getPoint(1)
            pnVar6 = nkm_path:getPoint(2)

            if (self.parts[iVar7 + 2] == nil) then
                table.insert(self.parts, iVar7 + 2, pw_path_part.new())
            end

            assert(self.parts[iVar7 + 2] ~= nil, "couldn't find inserted pw_path_part at index "..tostring(iVar7 + 2))

            self.parts[iVar7 + 2]:setup(0,1,pnVar3.position,pnVar4.position,pnVar5.position,pnVar6.position)
        end
    end

    if (self.partCount ~= #self.parts) then
        print("[pw_path:setup] partcount ("..tostring(self.partCount)..") mismatches with array size ("..tostring(#self.parts)..")\nideally, this never appears, but partCount has been corrected")
        self.partCount = #self.parts
    end

    --if (PW_DEBUG_MODE) then print("[pw_path:setup] successfuly set-up path; node count: "..tostring(#self.parts)) end
end

function pathwalker.setupPath(id, nkm_path)
    if (pathwalker.path_cache[id] == nil) then
        table.insert(pathwalker.path_cache, id, pw_path.new())

        assert(pathwalker.path_cache[id] ~= nil, "couldn't find inserted pw_path at index "..tostring(id))

        pathwalker.path_cache[id]:setup(id, nkm_path)
    end

    return pathwalker.path_cache[id]
end

/*--------------------------------------------------------------------------
    pw_pathwalker
        controls the actual "path-walking" after all the allocation busywork
        contains several interpolation functions and means of controlling
        how and where an object "walks" through the path
--------------------------------------------------------------------------*/
local pw_pathwalker = {}
pw_pathwalker.__index = pw_pathwalker

function pw_pathwalker.new(parent)
    local self = setmetatable({}, pw_pathwalker)
    self.path = pw_path.new()
    self.speed = 0
    self.pathId = 0
    self.partIdx = 0
    self.partSpeed = 0
    self.partProgress = 0
    self.isForwards = false
    self.prevPoit = nil
    self.curPoit = nil

    return self
end

function pw_pathwalker:init(initialPoint, forwards)
    local use_init_point
    local speed_mul
    local useforwards
    local use_prev_point
    local my_path

    useforwards = forwards

    use_init_point = initialPoint

    my_path = self.path
    if (not my_path.loop) then
        if ((use_init_point <= 1) and (not useforwards)) then
            useforwards = true
        elseif ((use_init_point == my_path.partCount) and (useforwards)) then
            useforwards = false
        end
    elseif ((use_init_point <= 1) and (not useforwards)) then
        use_init_point = my_path.partCount & 0xffff
    end

    if (not useforwards) then
        self.partIdx = use_init_point
    else
        self.partIdx = use_init_point + 1
    end

    -- set part speed based on oneDivLength
    speed_mul = my_path.parts[self.partIdx].oneDivLength
    if (speed_mul ~= 0) then
        self.partSpeed = FixedMul(self.speed, speed_mul)
    else
        self.partSpeed = LONGFRACUNIT
    end

    -- set part progress
    if (not useforwards) then
        self.partProgress = LONGFRACUNIT
    else
        self.partProgress = 0
    end

    self.isForwards = useforwards

    use_prev_point = use_init_point
    if (((not self.isForwards) and (my_path.loop)) and (use_init_point == (my_path.partCount + 1))) then
        use_prev_point = 1
    end

    self.prevPoit = pathwalker.getPathPoint(self.pathId, use_prev_point)

    if (self.isForwards == false) then
        use_init_point = $ - 1
    else
        use_init_point = $ + 1
    end

    use_init_point = use_init_point & 0xffff

    if (((self.isForwards) and (my_path.loop)) and (use_init_point == (my_path.partCount + 1))) then
        use_init_point = 1
    end

    self.curPoit = pathwalker.getPathPoint(self.pathId, use_init_point)
end

function pw_pathwalker:update()
    local onediv_len
    local my_path = self.path

    if (not self.isForwards) then
        self.partProgress = $ - self.partSpeed
        if (self.partProgress < 1) then
            if (self.partIdx == 1) then
                if (not my_path.loop) then -- if we're not looping...
                    -- ...turn around and go the other way
                    self.isForwards = true
                    self.partProgress = 0
                    self.prevPoit = self.curPoit
                    self.curPoit = pathwalker.getPathPoint(self.pathId, 2)
                else
                    self.partProgress = FixedMul(self.partProgress, my_path.parts[1].length)

                    self.partIdx = my_path.partCount
                    self.prevPoit = self.curPoit
                    self.curPoit = pathwalker.getPathPoint(self.pathId, my_path.partCount & 0xFFFF)

                    onediv_len = my_path.parts[self.partIdx].oneDivLength

                    if (onediv_len) then
                        self.partProgress = pw_progressMul(self.partProgress, onediv_len)
                    end

                    self.partProgress = $ + LONGFRACUNIT
                    self.partSpeed = (onediv_len) and FixedMul(self.speed, onediv_len) or LONGFRACUNIT
                end
            else
                self.partProgress = FixedMul(self.partProgress, my_path.parts[self.partIdx].length)
                self.partIdx = $ - 1
                self.prevPoit = self.curPoit
                self.curPoit = pathwalker.getPathPoint(self.pathId, self.partIdx)

                onediv_len = my_path.parts[self.partIdx].oneDivLength

                if (onediv_len) then
                    self.partProgress = pw_progressMul(self.partProgress, onediv_len)
                end

                self.partProgress = $ + LONGFRACUNIT
                self.partSpeed = (onediv_len) and FixedMul(self.speed, onediv_len) or LONGFRACUNIT
            end
            return true
        end
    else
        self.partProgress = $ + self.partSpeed
        if ((LONGFRACUNIT - 1) < self.partProgress) then
            if (self.partIdx == my_path.partCount) then
                if (not my_path.loop) then
                    self.isForwards = false
                    self.partProgress = LONGFRACUNIT
                    self.prevPoit = self.curPoit
                    self.curPoit = pathwalker.getPathPoint(self.pathId, self.partIdx & 0xFFFF)
                else
                    self.partProgress = $ - LONGFRACUNIT
                    self.partProgress =
                        FixedMul(self.partProgress, my_path.parts[self.partIdx].length)
                    self.partIdx = 1
                    self.prevPoit = self.curPoit
                    self.curPoit = pathwalker.getPathPoint(self.pathId, 2)

                    onediv_len = my_path.parts[self.partIdx].oneDivLength

                    if (onediv_len) then
                        self.partProgress = pw_progressMul(self.partProgress, onediv_len)
                    end

                    self.partSpeed = (onediv_len) and FixedMul(self.speed, onediv_len) or LONGFRACUNIT
                end
            else
                self.partProgress = $ - LONGFRACUNIT
                self.partProgress = FixedMul(self.partProgress, my_path.parts[self.partIdx].length)
                self.partIdx = $ + 1
                self.prevPoit = self.curPoit

                if ((self.partIdx == my_path.partCount) and (my_path.loop)) then
                    self.curPoit = pathwalker.getPathPoint(self.pathId, 1)
                else
                    self.curPoit = pathwalker.getPathPoint(self.pathId, (self.partIdx + 1) & 0xFFFF)
                end

                assert(my_path.parts[self.partIdx] ~= nil, "path part at index "..tostring(self.partIdx).." does not exist!")

                onediv_len = my_path.parts[self.partIdx].oneDivLength

                if (onediv_len) then
                    self.partProgress = pw_progressMul(self.partProgress, onediv_len)
                end

                self.partSpeed = (onediv_len) and FixedMul(self.speed, onediv_len) or LONGFRACUNIT
            end
            return true
        end
    end
    return false
end

function pw_pathwalker:getProgress()
    local iVar1

    if (not self.isForwards) then
        iVar1 = LONGFRACUNIT - self.partProgress
    else
        iVar1 = self.partProgress
    end

    return iVar1 / FRACTOLONGMUL
end

function pw_pathwalker:calcCurrentPointXYZ(dst)
    return pathwalker.interp.interpolateXYZ(self.path.parts[self.partIdx],self.partProgress,dst)
end

function pw_pathwalker:_20D8BF8_XYZ(a2,a3)
    pathwalker.interp._20D939C(self.path.parts[self.partIdx],self.partProgress,self.partSpeed,a2,a3)
    if (not self.isForwards) then FV3_Invert(a3) end
    return a2, a3
end

function pw_pathwalker:calcCurrentPointXY(dst)
    return pathwalker.interp.interpolateXY(self.path.parts[self.partIdx],self.partProgress,dst)
end

function pw_pathwalker:calcCurrentPointXYLinearZ(dst)
    return pathwalker.interp.interpolateXYLinearZ(self.path.parts[self.partIdx],self.partProgress,dst)
end

function pw_pathwalker:_20D8B18_XY(a2,a3)
    pathwalker.interp._20D9270_XY(self.path.parts[self.partIdx],self.partProgress,self.partSpeed,a2,a3)
    if (not self.isForwards) then -- not moving forwards?
        -- invert X and Y
        a3.x = -a3.x
        a3.y = -a3.y
    end

    return a2, a3
end

function pw_pathwalker:calcCurrentPointLinearXYZ(dst)
    local idx = self.partIdx
    local part_array = self.path.parts

    local one_sub = LONGFRACUNIT - self.partProgress

    dst.x = pw_progressMul(one_sub, part_array[idx].p0.x)
    dst.y = pw_progressMul(one_sub, part_array[idx].p0.z)
    dst.z = pw_progressMul(one_sub, part_array[idx].p0.y)

    dst.x = $ + pw_progressMul(self.partProgress, part_array[idx].p3.x)
    dst.y = $ + pw_progressMul(self.partProgress, part_array[idx].p3.z)
    dst.z = $ + pw_progressMul(self.partProgress, part_array[idx].p3.y)
    return dst
end

function pw_pathwalker:calcCurrentPointLinearXYZSpecial(a2,a3)
    local path_parts = self.path.parts
    local one_sub_prog = LONGFRACUNIT - self.partProgress

    FV3_ProgMulEx(path_parts[self.partIdx].p0, one_sub_prog, a2)
    FV3_ProgMulAddEx(path_parts[self.partIdx].p3, a2, self.partProgress, a2)

    FV3_SubApply(path_parts[self.partIdx].p3,path_parts[self.partIdx].p0,a3)

    FV3_ProgMulEx(a3, self.partSpeed, a3)

    if (not self.isForwards) then FV3_Invert(a3) end

    return a2, a3
end

function pw_pathwalker:reverse()
    local pnVar1 = self.prevPoit
    self.prevPoit = self.curPoit
    self.curPoit = pnVar1
    self.isForwards = (not self.isForwards)
end

function pw_pathwalker:gotoPartEnd()
    self.partProgress = LONGFRACUNIT
end

function pw_pathwalker:setSpeed(_speed)
    self.speed = _speed
    self.partSpeed = FixedMul(_speed, self.path.parts[self.partIdx].oneDivLength)
end

function pw_pathwalker:hasEnded()
    local endpoint_check = false
    if (self.isForwards) then
        endpoint_check = (self.partIdx == self.path.partCount)
    else
        endpoint_check = (self.partIdx == 1)
    end

    return ((not self.path.loop) and endpoint_check)
end

function pw_pathwalker:initFromPathId(pathId,speed,poitId)

    self.pathId = pathId
    local my_path = pathwalker.path_cache[self.pathId]
    local path_is_new = false

    poitId = $ or 1

    if (my_path == nil) then
        -- no path? make a new one
        path_is_new = true
        table.insert(pathwalker.path_cache, self.pathId, pw_path.new())

        assert(pathwalker.path_cache[self.pathId] ~= nil, "couldn't find inserted pw_path at index "..tostring(self.pathId))

        my_path = pathwalker.path_cache[self.pathId]
    end

    -- find an nkm_path_entry to set up our path with
    local nkm_path = pathwalker.nkm_paths[self.pathId]

    if (nkm_path == nil) then
        -- nothing here; get outta dodge

        if (not self.pw_warnNkmNullPath) then
            print("\x82".."[pw_pathwalker:initFromPathId] No nkm_path_entry for ID "..tostring(self.pathId).." exists in cache memory.".."\x80")

            -- do NOT send this warning again!
            self.pw_warnNkmNullPath = true
        end

        if (path_is_new) then
            -- clean up our mess and empty the uninitialized path from the cache
            pathwalker.path_cache[self.pathId] = nil
        end

        return
    end

    if (path_is_new) then -- no need to re-setup paths otherwise
        -- set up our path
        my_path:setup(self.pathId,nkm_path)
    end

    -- probably redundant, but this is my paranoia speaking
    pathwalker.path_cache[self.pathId] = my_path

    -- set the path and speed
    self.path = pathwalker.path_cache[self.pathId]
    self.speed = speed

    -- initialize ourselves
    self:init(poitId,self.path.isForwards)
end

function pw_pathwalker:initFromObject(mo,speed,poitId)

    poitId = $ or 1
    if (mo.pw_pathId == nil) then
        if (not mo.pw_warnNoPathId) then
            print("\x82".."[pw_pathwalker:initFromObject] Given mobj_t has no 'pw_pathId' variable.".."\x80")

            -- do NOT send this warning again!
            mo.pw_warnNoPathId = true
        end

        -- get out of dodge
        return
    end

    self:initFromPathId(mo.pw_pathId,speed,poitId)
end

function pw_pathwalker:network(net)
    self.path = net($)
    self.speed = net($)
    self.pathId = net($)
    self.partIdx = net($)
    self.partSpeed = net($)
    self.partProgress = net($)
    self.isForwards = net($)
    self.prevPoit = net($)
    self.curPoit = net($)
end

/*--------------------------------------------------------------------------
    struct metatable registration, necessary for netsync
--------------------------------------------------------------------------*/

registerMetatable(mdat_path)
registerMetatable(nkm_path_entry)
registerMetatable(nkm_poit_entry)
registerMetatable(pw_path_part)
registerMetatable(pw_path)
registerMetatable(pw_pathwalker)

/*--------------------------------------------------------------------------
    global struct functions
--------------------------------------------------------------------------*/

-- net-sync function
function pathwalker.network(net)
    pathwalker.map_paths = net($)
    pathwalker.nkm_paths = net($)
    pathwalker.path_cache = net($)
    pathwalker.ready = net($)

    pathwalker.netsync = true
    print("synchronized relevant pathwalker variables")
end

if (PW_DEBUG_MODE) then
    local test_part = pw_path_part.new()

    test_part:debugtest()

    print("[C] structs OK!")
else
    print("[C] structs OK!")
end

-- add netsync hook
addHook("NetVars", function(net)
    pathwalker.network(net)
end)

-- rawset structs
rawset(_G, "mdat_path", mdat_path)
rawset(_G, "nkm_path_entry", nkm_path_entry)
rawset(_G, "nkm_poit_entry", nkm_poit_entry)
rawset(_G, "pw_path_part", pw_path_part)
rawset(_G, "pw_path", pw_path)
rawset(_G, "pw_pathwalker", pw_pathwalker)
