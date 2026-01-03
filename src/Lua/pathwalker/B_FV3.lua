if (pathwalker_modload) then
    -- duck out
    return
end

local PW_DEBUG_MODE = PW_DEBUG_MODE

-- B_FV3
-- FV3 funcs, ported from source; very useful for vector3 arrays

--
-- "overflow-safe" multiplier
--

local INT32_MAX = 0x7FFFFFFF

local function OverflowSafeMul(a, b)
    if ((b > 0) and ((INT32_MAX / b) <= a)) then
        -- overflow; return INT32_MAX
        return INT32_MAX, true
    end

    return (a * b), false
end

rawset(_G, "FV3_Init", function(xx, yy, zz)
    local _x, _y, _z

    _x = xx or 0
    _y = yy or 0
    _z = zz or 0

    local newfv3 = {};
    newfv3.x = _x;
    newfv3.y = _y;
    newfv3.z = _z;

    return newfv3;
end)

rawset(_G, "FV3_UnitX", function()
    local newfv3 = {};
    newfv3.x = FRACUNIT;
    newfv3.y = 0;
    newfv3.z = 0;

    return newfv3;
end)

rawset(_G, "FV3_UnitY", function()
    local newfv3 = {};
    newfv3.x = 0;
    newfv3.y = FRACUNIT;
    newfv3.z = 0;

    return newfv3;
end)

rawset(_G, "FV3_UnitZ", function()
    local newfv3 = {};
    newfv3.x = 0;
    newfv3.y = 0;
    newfv3.z = FRACUNIT;

    return newfv3;
end)

rawset(_G, "FV3_Copy", function(a_o, a_i)
    a_o.x = a_i.x;
    a_o.y = a_i.y;
    a_o.z = a_i.z;
end)

rawset(_G, "FV3_AddEx", function(a_i, a_c)
    local a_o = {};

    a_o.x = a_i.x + a_c.x;
    a_o.y = a_i.y + a_c.y;
    a_o.z = a_i.z + a_c.z;
    return a_o;
end)

rawset(_G, "FV3_AddValue", function(a_i, val)
    local a_o = {};

    a_o.x = a_i.x + val;
    a_o.y = a_i.y + val;
    a_o.z = a_i.z + val;
    return a_o;
end)

rawset(_G, "FV3_SubEx", function(a_i, a_c)
    local a_o = {};

    a_o.x = a_i.x - a_c.x;
    a_o.y = a_i.y - a_c.y;
    a_o.z = a_i.z - a_c.z;
    return a_o;
end)

rawset(_G, "FV3_SubApply", function(a_i, a_c, a_o)
    a_o.x = a_i.x - a_c.x;
    a_o.y = a_i.y - a_c.y;
    a_o.z = a_i.z - a_c.z;
    return a_o;
end)

rawset(_G, "FV3_MulEx", function(a_i, a_c, a_o)
    a_o.x = FixedMul(a_i.x, a_c);
    a_o.y = FixedMul(a_i.y, a_c);
    a_o.z = FixedMul(a_i.z, a_c);
    return a_o;
end)


rawset(_G, "FV3_Mul", function(a_i, a_c)
    return FV3_MulEx(a_i, a_c, a_i);
end)

rawset(_G, "FV3_DivideEx", function(a_i, a_c)
    local a_o = {};

    a_o.x = FixedDiv(a_i.x, a_c);
    a_o.y = FixedDiv(a_i.y, a_c);
    a_o.z = FixedDiv(a_i.z, a_c);
    return a_o;
end)

rawset(_G, "FV3_Dot", function(a_1, a_2)
    return (FixedMul(a_1.x, a_2.x) + FixedMul(a_1.y, a_2.y) + FixedMul(a_1.z, a_2.z));
end)

rawset(_G, "FV3_Set", function(a_o, _x, _y, _z)
    a_o.x = _x;
    a_o.y = _y;
    a_o.z = _z;
end)

rawset(_G, "FV3_Scale", function(a_o, scale)
    a_o.x = FixedMul(a_o.x, scale);
    a_o.y = FixedMul(a_o.y, scale);
    a_o.z = FixedMul(a_o.z, scale);
end)

rawset(_G, "FV3_Print", function(a_i)
    print("X: "..tostring(a_i.x)..", Y: "..tostring(a_i.y)..", Z: "..tostring(a_i.z))
end)

rawset(_G, "FV3_PrintInt", function(a_i)
    print("X: "..tostring(a_i.x / FRACUNIT)..", Y: "..tostring(a_i.y / FRACUNIT)..", Z: "..tostring(a_i.z / FRACUNIT))
end)

rawset(_G, "FV3_Magnitude", function(a_normal)
    local xs = FixedMul(a_normal.x, a_normal.x);
    local ys = FixedMul(a_normal.y, a_normal.y);
    local zs = FixedMul(a_normal.z, a_normal.z);
    return FixedSqrt(xs + ys + zs);
end)

-- finds magnitude at an integer level, shaving off precision for flexibility
-- also accounts for potential overflows in the conversion back to fixed-point integers
rawset(_G, "FV3_MagnitudeInt", function(a_normal)
    local xx, yy, zz

    xx = a_normal.x / FRACUNIT
    yy = a_normal.y / FRACUNIT
    zz = a_normal.z / FRACUNIT

    local xs = (xx * xx);
    local ys = (yy * yy);
    local zs = (zz * zz);

    local sqr_mag = xs + ys + zs

    local testmul, test_ovf
    testmul, test_ovf = OverflowSafeMul(sqr_mag, 256)

    if (test_ovf) then
        -- square distance overflow
        return INT32_MAX, true
    end

    return OverflowSafeMul((FixedSqrt(xs + ys + zs) / 256), FRACUNIT);
end)

rawset(_G, "FV3_MagnitudeSqr", function(a_normal)
    local xs = FixedMul(a_normal.x, a_normal.x);
    local ys = FixedMul(a_normal.y, a_normal.y);
    local zs = FixedMul(a_normal.z, a_normal.z);
    return xs + ys + zs;
end)

-- Also returns the magnitude
rawset(_G, "FV3_NormalizeEx", function(a_normal, a_o, check_overflows)
    local magnitude, overflow = FV3_MagnitudeInt(a_normal);

    if ((overflow or (magnitude == 0)) and check_overflows) then
        -- I goddamn give up; use the less precise R_PointToDist2
        magnitude = R_PointToDist2(0,0,R_PointToDist2(0,0,a_normal.x,a_normal.y),a_normal.z)

        if (magnitude == 0) then
            -- still nothing
            return 0
        end
    end

    if (magnitude == 0) then return 0 end

    a_o.x = FixedDiv(a_normal.x, magnitude);
    a_o.y = FixedDiv(a_normal.y, magnitude);
    a_o.z = FixedDiv(a_normal.z, magnitude);
    return magnitude;
end)

rawset(_G, "FV3_Normalize", function(a_normal)
    return FV3_NormalizeEx(a_normal, a_normal);
end)

rawset(_G, "FV3_SqrEx", function(a_i)
    local a_o = {};

    a_o.x = FixedMul(a_i.x, a_i.x);
    a_o.y = FixedMul(a_i.y, a_i.y);
    a_o.z = FixedMul(a_i.z, a_i.z);
    return a_o;
end)

rawset(_G, "FV3_Sqr", function(a_i)
    a_i = FV3_SqrEx(a_i);
    return a_i;
end)

rawset(_G, "FV3_ProgMulEx", function(a_i, a_c, a_o)
    a_o.x = pw_progressMul(a_c, a_i.x);
    a_o.y = pw_progressMul(a_c, a_i.y);
    a_o.z = pw_progressMul(a_c, a_i.z);
    return a_o;
end)

rawset(_G, "FV3_ProgMul", function(a_i, a_c)
    return FV3_ProgMulEx(a_i, a_c, a_i);
end)

rawset(_G, "FV3_Invert", function(a_o)
    a_o.x = -a_o.x;
    a_o.y = -a_o.y;
    a_o.z = -a_o.z;
end)

rawset(_G, "FV3_Match", function(a_1, a_2)
    if ((a_1.x == a_2.x) and (a_1.y == a_2.y) and (a_1.z == a_2.z)) then
        return true
    end

    return false
end)

-- about this function
-- MKDS is y-up, DRRR is z-up
-- I'm a lazy fuck, so let's cheat and just convert the MKDS vector schema to the DRRR vector schema
rawset(_G, "FV3_Reorder", function(a_o)

    assert(a_o ~= nil, "passed nil or non-vector struct")
    local temp = {}

    FV3_Copy(temp, a_o)

    a_o.y = temp.z
    a_o.z = temp.y

    return a_o
end)

-- a_c * a_1 + a_2
rawset(_G, "FV3_MultAddEx", function(a_1, a_2, a_c, a_o)
    a_o.x = a_2.x + FixedMul(a_c, a_1.x)
    a_o.y = a_2.y + FixedMul(a_c, a_1.y)
    a_o.z = a_2.z + FixedMul(a_c, a_1.z)
    return a_o
end)

rawset(_G, "FV3_MultAdd", function(a_1, a_2, a_c)
    return FV3_MultAddEx(a_1, a_2, a_c, a_1)
end)

rawset(_G, "FV3_ProgMulAddEx", function(a_1, a_2, a_c, a_o)
    a_o.x = a_2.x + pw_progressMul(a_c, a_1.x)
    a_o.y = a_2.y + pw_progressMul(a_c, a_1.y)
    a_o.z = a_2.z + pw_progressMul(a_c, a_1.z)
    return a_o
end)

rawset(_G, "FV3_ProgMulAdd", function(a_1, a_2, a_c)
    return FV3_ProgMulAddEx(a_1, a_2, a_c, a_1)
end)

if (PW_DEBUG_MODE) then
    local test_vec_1, test_vec_2, dst

    test_vec_1 = FV3_UnitX()
    test_vec_2 = FV3_UnitX()
    dst = FV3_Init()

    test_vec_2.x = FRACUNIT / 2

    FV3_SubApply(test_vec_1, test_vec_2, dst)

    assert(dst.x == FRACUNIT / 2, "FV3_SubApply failure (dst.x was "..tostring(dst.x)..", expected "..tostring(FRACUNIT / 2)..")")

    print("[B] FV3 OK! dst.x is "..tostring(dst.x))
end
