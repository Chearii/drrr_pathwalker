-- D_pw_interp
-- interpolation functions for the pathwalker system

assert(pathwalker ~= nil, "struct 'pathwalker' does not exist!")
assert(pw_pathwalker ~= nil, "struct 'pw_pathwalker' does not exist!")

if (pathwalker_modload) then
    -- duck out
    return
end

-- set up an interpolation struct from inside the pathwalker struct
pathwalker.interp = {}

-- returns vector3_t
function pathwalker.interp.applyCoefXYZ(part, dst, c0, c1, c2, c3)
    FV3_ProgMulEx(part.p0, c0, dst)
    FV3_ProgMulAddEx(part.p1, dst, c1, dst)
    FV3_ProgMulAddEx(part.p2, dst, c2, dst)
    FV3_ProgMulAddEx(part.p3, dst, c3, dst)

    assert(dst ~= nil, "something happened?!")

    FV3_Reorder(dst)

    return dst
end

-- returns vector3_t
function pathwalker.interp.applyCoefXY(part, dst, c0, c1, c2, c3)
    dst.x = pw_progressMul(c0, part.p0.x)
    dst.y = pw_progressMul(c0, part.p0.z)

    dst.x = $ + pw_progressMul(c1, part.p1.x)
    dst.y = $ + pw_progressMul(c1, part.p1.z)

    dst.x = $ + pw_progressMul(c2, part.p2.x)
    dst.y = $ + pw_progressMul(c2, part.p2.z)

    dst.x = $ + pw_progressMul(c3, part.p3.x)
    dst.y = $ + pw_progressMul(c3, part.p3.z)

    return dst
end

-- returns hermite_coef_t
function pathwalker.interp.hermiteSplineCalcCoef(t, coef)
    local one_diff = LONGFRACUNIT - t

    coef.a[1] = pw_progressMul(one_diff, pw_progressMul(one_diff, one_diff))

    coef.a[3] = pw_progressMul(one_diff, t) * 3

    coef.a[4] = pw_progressMul(t, coef.a[3])

    coef.a[5] = pw_progressMul(t, pw_progressMul(t, t))

    coef.a[3] = pw_progressMul(one_diff, coef.a[3])

    return coef;
end

-- returns hermite_coef_t
function pathwalker.interp.hermiteSplineCalcCoef2(t, coef)
    local one_diff = LONGFRACUNIT - t

    coef.a[6] = pw_progressMul(one_diff, one_diff)
    coef.a[1] = pw_progressMul(one_diff, coef.a[6])
    coef.a[9] = pw_progressMul(t, t)
    coef.tpow3 = pw_progressMul(t, coef.a[9])
    coef.a[3] = pw_progressMul(one_diff, t)
    coef.a[6] = $ * 4
    coef.a[9] = $ * 4
    coef.a[8] = coef.a[3] * 3
    coef.a[7] = coef.a[6] - coef.a[8]
    coef.a[8] = coef.a[8] - coef.a[9]
    coef.a[6] = -coef.a[6]

    coef.a[4] = pw_progressMul(t, coef.a[3])
    coef.a[3] = pw_progressMul(one_diff, coef.a[3])

    return coef
end

-- returns vector3_t
function pathwalker.interp.interpolateXYZ(part, t, dst)
    local coef = hermite_coef.new()

    coef = pathwalker.interp.hermiteSplineCalcCoef(t, coef)
    pathwalker.interp.applyCoefXYZ(part, dst, coef.a[1], coef.a[3], coef.a[4], coef.a[5])
    return dst
end

-- returns vector3_t
function pathwalker.interp._20D939C(part, a2, a3, a4, a5)
    local coef = hermite_coef.new()

    coef = pathwalker.interp.hermiteSplineCalcCoef2(a2, coef)

    pathwalker.interp.applyCoefXYZ(part, a4, coef.a[1], coef.a[3], coef.a[4], coef.tpow3)
    pathwalker.interp.applyCoefXYZ(part, a5, coef.a[6], coef.a[7], coef.a[8], coef.a[9])

    FV3_ProgMul(a5, a3)
    return a4, a5
end

-- returns vector3_t
function pathwalker.interp.interpolateXY(part, t, dst)
    local coef = hermite_coef.new()

    coef = pathwalker.interp.hermiteSplineCalcCoef(t, coef)
    pathwalker.interp.applyCoefXY(part, dst, coef.a[1], coef.a[3], coef.a[4], coef.a[5])
    return dst
end

-- returns vector3_t
function pathwalker.interp.interpolateXYLinearZ(part, t, dst)
    local coef = hermite_coef.new()

    coef = pathwalker.interp.hermiteSplineCalcCoef(t, coef)
    pathwalker.interp.applyCoefXY(part, dst, coef.a[1], coef.a[3], coef.a[4], coef.a[5])

    dst.z = pw_progressMul(LONGFRACUNIT - t, part.p0.y)
    dst.z = $ + pw_progressMul(t, part.p3.y)
    return dst
end

-- returns vector3_t
function pathwalker.interp._20D9270_XY(part,a2,a3,a4,a5)
    local coef = hermite_coef.new()

    pathwalker.interp.hermiteSplineCalcCoef2(a2, coef)
    pathwalker.interp.applyCoefXY(part, a4, coef.a[1], coef.a[3], coef.a[4], coef.tpow3)
    pathwalker.interp.applyCoefXY(part, a5, coef.a[6], coef.a[7], coef.a[8], coef.a[9])

    a5.x = pw_progressMul(a3, a5.x)
    a5.y = pw_progressMul(a3, a5.y)
    return a5
end

local INT32_MIN = 0x7FFFFFFF * -1 - 1

function pathwalker.interp.debugtest()
    local part = pw_path_part.new()
    part:setup(1, 0, FV3_Mul(FV3_UnitX(), 5 * FRACUNIT), FV3_Init(FRACUNIT * 10, FRACUNIT * 25, FRACUNIT * 30), FV3_Mul(FV3_UnitY(), -5 * FRACUNIT), nil)

    local dummy = FV3_Init()

    local vec = pathwalker.interp.interpolateXYZ(part, FRACUNIT/2, dummy)

    local a4, a5;

    a4 = FV3_Init(INT32_MIN, INT32_MIN, INT32_MIN)
    a5 = FV3_Init(INT32_MIN, INT32_MIN, INT32_MIN)

    local a4_last, a5_last

    a4_last = FV3_Init()
    a5_last = FV3_Init()
    FV3_Copy(a4_last, a4)
    FV3_Copy(a5_last, a5)

    print("[a4] X: "..tostring(a4.x)..", Y: "..tostring(a4.y)..", Z: "..tostring(a4.z))
    print("[a5] X: "..tostring(a5.x)..", Y: "..tostring(a5.y)..", Z: "..tostring(a5.z))
    pathwalker.interp._20D939C(part, FRACUNIT/2, FRACUNIT/3, a4, a5)
    print("[a4] X: "..tostring(a4.x)..", Y: "..tostring(a4.y)..", Z: "..tostring(a4.z))
    print("[a5] X: "..tostring(a5.x)..", Y: "..tostring(a5.y)..", Z: "..tostring(a5.z))

    -- these should output differently from the init values; something is clearly wrong if not
    if (FV3_Match(a4, a4_last) or FV3_Match(a5, a5_last)) then return false end

    print("X:"..tostring(vec.x)..", Y:"..tostring(vec.y)..", Z:"..tostring(vec.z))
    print("a4:"..tostring(FV3_Magnitude(a4))..", a5:"..tostring(FV3_Magnitude(a5)))

    return true
end

if (PW_DEBUG_MODE) then
    assert(pathwalker.interp.debugtest(), "[D] pw_interp debug test failed!")

    print("[D] pw_interp OK!")
end

-- play a goofy sound to signal everything's OK!
S_StartSound(nil, sfx_mbs54)
print("\x83Pathwalker OK!\x80")

-- and finally... don't let other addons load us again
local pathwalker_modload = 1
rawset(_G, "pathwalker_modload", pathwalker_modload)
