# Pathwalker library

The Pathwalker library contains the following data structures, alongside a general "pathwalker" datatype containing addon-wide systems (such as path allocation, referred to as the Polling system), and useful functions.

_WARNING:_ Some functions, for the sake of completion, are provided in this library. These functions are labeled as "Partially undocumented" due to thorough testing not being done for them. _Use these functions at your own risk._

## Constants

| Name                   | Value | Description |
|------------------------|------ |-------------|
| `LONGFRACUNIT`         | <code>1<<LONGFRACBITS</code><br />(<code>1<<24</code>, or 16777216) | A longer-than-usual unit of measurement used primarily, if not exclusively, for calculating a `pw_pathwalker`'s progress through a `pw_path_part`. Just as `FRACUNIT` is 1.0 at a standard scale, `LONGFRACUNIT` is 1.0 at this larger scale; conversely, `FRACUNIT` becomes `1/256`, or 0.00390625. Can be converted to a standard `FRACUNIT`-scale value with `x / FRACTOLONGMUL`, `x >> FRACTOLONGBITS`, or through the `pw_longtofrac` function. |
| `LONGFRACBITS`         | 24    | The number of bits to shift up to convert integers to fixed-point numbers in `LONGFRACUNIT` scale, or the number of bits to shift down for vice versa. This constant is used to define the value of `LONGFRACUNIT` itself &ndash; modifying the value of `LONGFRACBITS` in the code would also modify `LONGFRACUNIT`'s value. |
| `FRACTOLONGMUL`        | <code>1<<FRACTOLONGBITS</code><br />(<code>1<<8</code>, or 256) | The difference in bitdepth between `LONGFRACUNIT` and `FRACUNIT`. Can be used to convert a `FRACUNIT` to a `LONGFRACUNIT`, and vice-versa. |
| `FRACTOLONGBITS`       | 8     | The number of bits to shift up to convert integers to fixed-point numbers in `FRACTOLONGMUL` scale, or the number of bits to shift down for vice versa. This constant is used to define the value of `FRACTOLONGMUL` itself &ndash; modifying the value of `FRACTOLONGBITS` in the code would also modify `FRACTOLONGMUL`'s value. |
| `PWF_CONTROL`       | 1     | A flag that, when found in a Pathwalker Path Point's `args[1]` variable, signals to the path allocation system that this is a Control Point that controls various settings within the given path. Any other point found with this flag will override the settings of the prior. |
| `PWF_DONTLOOP`      | 2     | A flag that, when found in a Control Point's `args[1]` variable, signals to the path allocation system that the path should not loop, and that any Pathwalkers that have reached the end of this path should turn around and move the other way. |
| `PWF_REVERSE`       | 4     | A flag that, when found in a Control Point's `args[1]` variable, signals to the path allocation system that this path should initially be traveled in reverse. |
| `PWF_SHOWPATH`      | 8     | A flag that, when found in a Control Point's `args[1]` variable, signals to the path allocation system that this path should display its points visually. Should be primarily used for debug and/or demonstration purposes. |
| `PW_DEBUG_MODE`     | 0     | An integer value that toggles on various initial debugging tests for the various components of the Pathwalker system. This value _only_ matters during addon load, and is irrelevant elsewhere. |

## General functions

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**pw_progressMul**(<i>pw_progress_t</i> a, <i>fixed_t</i> b)</code>      | `fixed_t`       | Returns the result of multiplying `a` by `b` in the fixed-point scale. `a` is divided by 256 to rescale it to standard fixed-point scaling (16.16; 1.0 = `FRACUNIT`) from long fixed-point scaling (8.24; 1.0L = `LONGFRACUNIT`). |
| <code>**pw_longtofrac**(<i>fixed_t</i> x)</code>      | `fixed_t`       | Returns `x` divided by `FRACTOLONGMUL`, converting it from `LONGFRACUNIT` scale to `FRACUNIT` scale. |
| <code>**pw_longtofracshift**(<i>fixed_t</i> x)</code>      | `fixed_t`       | Returns `x` shifted down by `FRACTOLONGBITS`, converting it from `LONGFRACUNIT` scale to `FRACUNIT` scale. |

## Global Pathwalker data (`pathwalker.<data>`)

| Name                   | Type | Description |
|------------------------|------|-------------|
| `polling_ready`        | `boolean` | If any Pathwalker Path Points (thing type 12405) are found in a map on map load, this value is set. _This serves as a signal to internal systems to begin the Polling process. Write to at your own risk!_ |
| `ready`                | `boolean` | Signals that the global system is done with path allocation the Polling process, meaning `pw_pathwalker` datatypes can begin to be used. _Write to at your own risk!_ |
| `map_paths`            | `array` | Temporary memory table containing `mdat_path` datatypes, which contain the array of Pathwalker Path Points for the given path ID. `nkm_path_entry` datatypes, and the `pathwalker.getPathPoint` function, link back to this array to get data on path points. This table is always cleared out when the map changes. |
| `nkm_paths`            | `array` | Temporary memory table containing `nkm_path_entry` datatypes, which contain specific data settings for the given path. This table is always cleared out when the map changes. |
| `path_cache`           | `array` | Temporary memory table containing `pw_path` datatypes, which are the actual path datatypes read by `pw_pathwalker`` dataypes. This table is always cleared out when the map changes. | 
| `interp`               | `array` | Data table containing all interpolation functions used by the Pathwalker system. | 
| `netsync`              | `boolean` | Signals that the system has done network synchronization. _Write to at your own risk!_ |

## Global Pathwalker functions (`pathwalker.<func>`)

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**findPointId**(<i>UINT16</i> path, <i>UINT16</i> poit_idx)</code> | `UINT16` | Returns the position in the `mdat_path` found at the `path` index in the `map_paths` array where an `nkm_poit_entry` datatype shares the same ID value as `poit_idx`. |
| <code>**getPathPoint**(<i>UINT16</i> path, <i>UINT16</i> poit_idx)</code> | `nkm_poit_entry` | Returns the point data found at the index `poit_idx` in the `mdat_path` found at the `path` index. |
| <code>**setupPath**(<i>INT32</i> id, <i>nkm_path_entry</i> nkm_path)</code> | `pw_path` | Creates a new `pw_path` datatype at the given ID, using the supplied `nkm_path_entry` (`nkm_path`), and adds the path to the `pathwalker.path_cache` array. Should a path already exist at the given index, it simply returns that path instead. |
| <code>**network**(<i>netsave</i> net)</code> | `nil` | Generic netsync function. Syncs all cached path data, and the `ready` boolean over the Internet, while setting a `netsync` boolean to <code><b>true</b></code>. Called via a NetVars hook. |

## Global Pathwalker interpolation functions (`pathwalker.interp.<func>`)

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**applyCoefXYZ**(<i>pw_path_part</i> part, <i>vector3</i> dst, <i>fixed_t</i> c0, <i>fixed_t</i> c1, <i>fixed_t</i> c2, <i>fixed_t</i> c3)</code> | `vector3` | Returns the interpolated position as a vector given the `pw_path_part` datatype and four coefficients (`c0, c1, c2, c3`). |
| <code>**applyCoefXY**(<i>pw_path_part</i> part, <i>vector3</i> dst, <i>fixed_t</i> c0, <i>fixed_t</i> c1, <i>fixed_t</i> c2, <i>fixed_t</i> c3)</code> | `vector3` | Same as `applyCoefXYZ`, but the interpolation results are applied to only the X and Y axes of the destination vector (`dst`). |
| <code>**hermiteSplineCalcCoef**(<i>fixed_t</i> t, <i>hermite_coef</i> coef)</code> | `hermite_coef` | Calculates and returns coefficients for Cubic Hermite spline interpolation, as a `hermite_coef` dataype. Indices 1, 3, 4, and 5 of the datatype's `a` array are written to. |
| <code>**hermiteSplineCalcCoef2**(<i>fixed_t</i> t, <i>hermite_coef</i> coef)</code> | `hermite_coef` | _Partially undocumented._ Calculates and returns coefficients for Cubic Hermite spline interpolation, as a `hermite_coef` dataype. Indices 1, 3, 4, 6, 7, 8, and 9 of the datatype's `a` array are written to. The datatype's `tpow3` variable is written to. |
| <code>**interpolateXYZ**(<i>pw_path_part</i> part, <i>fixed_t</i> t, <i>vector3</i> dst)</code> | `vector3` | Returns a 3D position within a given `pw_path_part`, interpolated with Cubic Hermite spline interpolation depending on the `t` progress value. Applies to the X, Y, and Z axes of the given desination vector (`dst`). |
| <code>**_20D939C**(<i>pw_path_part</i> part, <i>fixed_t</i> a2, <i>fixed_t</i> a3, <i>vector3</i> a4, <i>vector3</i> a5)</code> | `vector3` | _Partially undocumented._ Returns a pair of 3D vectors corresponding to interpolated positions within a given `pw_path_part`, interpolated with Cubic Hermite spline interpolation depending on the `a2` progress value. Vector `a5` is then multiplied via `pw_progressMul` by `a3`. Applies to the X, Y, and Z axes of the given desination vectors (`a4` and `a5`). |
| <code>**interpolateXY**(<i>pw_path_part</i> part, <i>fixed_t</i> t, <i>vector3</i> dst)</code> | `vector3` | Returns a 2D position within a given `pw_path_part`, interpolated with Cubic Hermite spline interpolation depending on the `t` progress value. Applies to the X and Y axes of the given desination vector (`dst`). |
| <code>**interpolateXYLinearZ**(<i>pw_path_part</i> part, <i>fixed_t</i> t, <i>vector3</i> dst)</code> | `vector3` | Returns a 3D position within a given `pw_path_part`. Axes X and Y are interpolated with Cubic Hermite spline interpolation, and axis Z is interpolated linearly. All three interpolations are dependent on the `t` progress value. Applies to the X, Y, and Z axes of the given desination vector (`dst`). |
| <code>**_20D9270_XY**(<i>pw_path_part</i> part, <i>fixed_t</i> a2, <i>fixed_t</i> a3, <i>vector3</i> a4, <i>vector3</i> a5)</code> | `vector3` | _Partially undocumented._ Returns a pair of 2D vectors corresponding to interpolated positions within a given `pw_path_part`, where the X and Y axes are interpolated with Cubic Hermite spline interpolation depending on the `a2` progress value. Vector `a5` is then multiplied via `pw_progressMul` by `a3`. Applies to the X and Y axes of the given desination vectors (`a4` and `a5`). |
| <code>**debugtest**()</code> | `nil` | Generic testing function, called on addon load if the `PW_DEBUG_MODE` constant is a non-zero value. |

## mdat_path datatype

### Userdata

| Name                   | Type | Description |
|------------------------|------|-------------|
| `path_id`              | `UINT16`   | The given path ID, assigned based on a Control Point's tag during path allocation. |
| `poit`                 | `array`    | An array consisting of all `nkm_poit_entry` datatypes for the given path. |
| `new`                  | `function` | Allocation function, automatically assigns all relevant datatype values, and assigns the necessary metadata. |

## nkm_path_entry datatype

### Userdata

| Name                   | Type | Description |
|------------------------|------|-------------|
| `id`                   | `UINT16`   | The `nkm_path_entry`'s ID, assigned based on a Control Point's tag during path allocation. |
| `parent_id`            | `UINT16`   | The ID of the `mdat_path` datatype this `nkm_path_entry` belongs to. |
| `loop`                 | `boolean`  | Determines if the equivalent `pw_path` datatype is a looping path. |
| `isForwards`           | `boolean`  | Determines if the equivalent `pw_path` datatype should be traveled forwards (<b>`true`</b>) or in reverse (<b>`false`</b>). |
| `pointCount`           | `INT32`   | The number of points in the parent `mdat_path` datatype. |
| `new`                  | `function` | Allocation function, automatically assigns all relevant datatype values, and assigns the necessary metadata. |

### Functions (`nkm_path:<func>`)

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**getPoint**(<i>UINT16</i> poit_idx)</code> | `nkm_poit_entry` | Returns the point data found at the index `poit_idx` in the parent `mdat_path`. |

## nkm_poit_entry datatype

### Userdata

| Name                   | Type | Description |
|------------------------|------|-------------|
| `position`             | `vector3 (Y-up)`   | The position in 3D space of this `nkm_poit_entry`. This position is stored "Y-up"; as it is in Mario Kart DS. Compared to Ring Racers, whose 3D space is where X is left-right, Y is forward-back, and Z is up-down (Z-up), Mario Kart DS' 3D space is where X is left-right, y is up-down, and Z is forward-back (Y-up). The function `FV3_Reorder` is used to swap the Y and Z axes of these types of vectors, to allow them to be conveniently used in Ring Racers. |
| `pointIndex`           | `UINT16`   | The ID of this datatype, based on its index in the path. |
| `unknown1`             | `INT32`  | _Unused variable._ |
| `duration`             | `INT32`  | _Unused variable._ |
| `unknown2`             | `INT32`  | _Unused variable._ |
| `new`                  | `function` | Allocation function, automatically assigns all relevant datatype values, and assigns the necessary metadata. |

## pw_path_part datatype

### Userdata

| Name                   | Type | Description |
|------------------------|------|-------------|
| `p0`                   | `vector3 (Y-up)`   | The position in 3D space of the starting point of this path part. |
| `p1`                   | `vector3 (Y-up)`   | The position in 3D space of an in-between point of this path part. |
| `p2`                   | `vector3 (Y-up)`   | The position in 3D space of an in-between point of this path part. |
| `p3`                   | `vector3 (Y-up)`   | The position in 3D space of the end-point of this path part. |
| `length`               | `fixed_t`          | The Cubic Hermite length, in `FRACUNIT` scale. Identical to `hermLength`. |
| `linLength`            | `fixed_t`          | The linear length, in `FRACUNIT` scale. |
| `hermLength`           | `fixed_t`          | The Cubic Hermite length, in `FRACUNIT` scale. Identical to `length`. |
| `oneDivHermLength`     | `fixed_t`          | `LONGFRACUNIT / hermLength`. Identical to `oneDivLength`. |
| `oneDivLength`         | `fixed_t`          | `LONGFRACUNIT / hermLength`. Identical to `oneDivHermLength`. |
| `oneDivLinLength`      | `fixed_t`          | `LONGFRACUNIT / linLength`. |
| `field10_0x48`         | `vector3 (Y-up)`   | _Undocumented variable. Unused within the library._ |
| `new`                  | `function`         | Allocation function, automatically assigns all relevant datatype values, and assigns the necessary metadata. |

### Functions (`path_part:<func>`)

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**setup**(<i>UINT8</i> a2, <i>UINT8</i> a3, <i>vector3 (Y-up)</i> param_4, <i>vector3 (Y-up)</i> param_5, <i>vector3 (Y-up)</i> param_6)</code> | `pw_path_part` | Given 4 vectors, creates a path part. The a2 variable controls whether the part should linearly allocate its point vectors, or use a formula to allocate said vectors. If a3 is set, the normalized distance between `param_5` and `param_6`, multiplied by the dot-product of the resulting normalized vector and a unit-Y (0.0,1.0,0.0) vector, is used to set `field10_0x48`. |

## pw_path datatype

### Userdata

| Name                   | Type                     | Description |
|------------------------|--------------------------|-------------|
| `parts`                | `array (pw_path_part)`   | An array containing `pw_path_part` datatypes. Indexed by `pw_pathwalker` datatypes to trace through paths. |
| `partCount`            | `INT32`                  | The number of `pw_path_part` datatypes in the `parts` array. |
| `loop`                 | `boolean`  | Determines if the datatype is a looping path. |
| `isForwards`           | `boolean`  | Determines if the datatype should be traveled forwards (<b>`true`</b>) or in reverse (<b>`false`</b>). |
| `new`                  | `function`         | Allocation function, automatically assigns all relevant datatype values, and assigns the necessary metadata. |

### Functions (`path:<func>`)

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**setup**(<i>UINT16</i> id, <i>nkm_path_entry</i> nkm_path)</code> | `pw_path` | Given an `nkm_path_entry` datatype, creates a path. This allocates the datatype's `paths` array, and sets the boolean parameters based on `nkm_path`. The `id` value goes unused. |

## pw_pathwalker datatype

### Userdata

| Name                   | Type                     | Description |
|------------------------|--------------------------|-------------|
| `path`                 | `pw_path`                | The pathwalker's given path. |
| `speed`                | `fixed_t`                | The speed at which the pathwalker travels through the path, at `FRACUNIT` scale. |
| `pathId`               | `UINT16`                 | The path's ID, used to index the corresponding `mdat_path` datatype for path points. |
| `partIdx`              | `UINT16`                 | The path part's ID, also used to determine the pathwalker's progress through the path. |
| `partSpeed`            | `fixed_t`                | The speed at which the pathwalker travels through the path part, at `LONGFRACUNIT` scale. |
| `partProgress`         | `fixed_t`                | The overal progress through the current path part, at `LONGFRACUNIT` scale. |
| `isForwards`           | `boolean`                | Determines if the pathwalker is moving forwards (<b>`true`</b>) or in reverse (<b>`false`</b>). |
| `prevPoit`             | `nkm_poit_entry`         | The previous path point. Assigned once the pathwalker progresses onto the next path point. |
| `curPoit`              | `nkm_poit_entry`         | The current path point. Assigned once the pathwalker progresses onto the next path point, which then becomes this point. |
| `new`                  | `function`         | Allocation function, automatically assigns all relevant datatype values, and assigns the necessary metadata. |

### Functions (`pw:<func>`)

| Function                                                                 | Return value(s) | Description |
|--------------------------------------------------------------------------|-----------------|-------------|
| <code>**init**(<i>UINT16</i> initialPoint, <i>boolean</i> forwards)</code> | `nil` | Initializes the pathwalker, taking the parameters of its path into account. This function also sets the `curPoit` and `prevPoit` values based on `initialPoint`, and sets the speed values to a set of default values. |
| <code>**update**()</code> | `boolean` | Attempts to update the pathwalker's travel through the path. Returns true if an update happens, and false if it does not. |
| <code>**getProgress**()</code> | `fixed_t` | Returns the progress through the given path part, at `FRACUNIT` scale. |
| <code>**calcCurrentPointXYZ**(<i>vector3</i> dst)</code> | `vector3` | Returns the Cubic Hermite-interpolated position of the pathwalker, assigning the position to the `dst` vector as well. |
| <code>**calcCurrentPointXY**(<i>vector3</i> dst)</code> | `vector3` | Returns the Cubic Hermite-interpolated position of the X and Y position of the pathwalker, ignoring the Z axis. Assigns the position to the `dst` vector as well. |
| <code>**calcCurrentPointXYLinearZ**(<i>vector3</i> dst)</code> | `vector3` | Returns the Cubic Hermite-interpolated position of the X and Y position of the pathwalker, with the Z axis being interpolated linearly. Assigns the position to the `dst` vector as well. |
| <code>**calcCurrentPointLinearXYZ**(<i>vector3</i> dst)</code> | `vector3` | Returns the linearly-interpolated position of the pathwalker, assigning the position to the `dst` vector as well. |
| <code>**calcCurrentPointLinearXYZSpecial**(<i>vector3</i> a2, <i>vector3</i> a3)</code> | `vector3 pair` | Linearly interpolates the pathwalker's progress, and assigns the results to `a2` and `a3`. The two vectors are also returned by the function. |
| <code>**_20D8BF8_XYZ**(<i>vector3</i> a2, <i>vector3</i> a3)</code> | `vector3 pair` | _Partially undocumented._ Returns a pair of vectors representing the pathwalker's position, interpolated via the `pathwalker.interp._20D939C` function. The `a2` and `a3` values are assigned as well. |
| <code>**_20D8B18_XY**(<i>vector3</i> a2, <i>vector3</i> a3)</code> | `vector3 pair` | _Partially undocumented._ Returns a pair of vectors representing the pathwalker's position, interpolated via the `pathwalker.interp._20D9270_XY` function. The `a2` and `a3` values are assigned as well. The Z axis is ignored by this function. |
| <code>**reverse**()</code> | `nil` | Reverses the pathwalker's movement, making it travel backwards through the path instead of forwards. |
| <code>**gotoPartEnd**()</code> | `nil` | Immediately sets full progress for the given path part, skipping to its end. |
| <code>**setSpeed**(<i>fixed_t</i> _speed)</code> | `nil` | Sets the travel speed of the pathwalker. |
| <code>**hasEnded**()</code> | `boolean` | Returns a boolean signifying if the pathwalker has reached the end of its path or not. |
| <code>**initFromPathId**(<i>UINT16</i> pathId, <i>fixed_t</i> speed, [<i>UINT16</i> poitId])</code> | `nil` | Initializes a pathwalker based on a given path ID, speed value, and, optionally, a point ID. This sets the pathwalker's path and speed. If no `poitId` value is set, the pathwalker starts at the very start of the path isntead. |
| <code>**initFromObject**(<i>mobj_t</i> mo, <i>fixed_t</i> speed, [<i>UINT16</i> poitId])</code> | `nil` | Initializes a pathwalker based on a given object, speed value, and, optionally, a point ID. This sets the pathwalker's path and speed. If no `poitId` value is set, the pathwalker starts at the very start of the path isntead. The object must have a `pw_pathId` number value set before this function is called for it to properly work. |
| <code>**network**(<i>netsave</i> net)</code> | `nil` | Generic netsync function. Syncs all data relevant to a pathwalker's general progress. |
