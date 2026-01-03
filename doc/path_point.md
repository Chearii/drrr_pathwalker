# Pathwalker Path Point (mapthing 12405)

Mapthing 12405; the **Pathwalker Path Point**, represents a vertex in 3D space that's a part of a path a Pathwalker can travel across. This document will describe its overall parameters and usage.

## Disclaimer

This system is very much designed around the mapping system present in Dr. Robotnik's Ring Racers; and thus does not have support for non-UDMF maps without modification. If you were intending to use this in a non-UDMF SRB2 map, for example, you're left to your own vices in terms of figuring that out.

## Tag usage

To determine the path this Pathwalker Path Point will belong to, you should set the mapthing's Tag parameter to the corresponding path number. For example: a Pathwalker Path Point with tag 1 belongs to path 1, as does a Pathwalker Path Point with tag 2 belongs to path 2.

## Arguments

The Arguments fields specify 2 notable parameters that are integral to the Pathwalker's functionality.

### Point ID (Argument 1)

The **Point ID** argument (Argument 1) tells the Pathwalker system of the order in which each point _should be sorted_. It does _not_ specify the actual ID in code space, but can be used to tell the Pathwalker which point it should travel to, especially for initialization. As the system sorts all path points on map load, the point ID and actual index within the path array will be out of sync in most cases. Despite this, you can use `pathwalker.findPointId` to search for a point's index in a path via its Point ID parameter, and then `pathwalker.getPathPoint` to get the point with the found index; see https://github.com/Chearii/drrr_pathwalker/blob/main/doc/documentation.md for more information.

### Flags (Argument 2)

The **Flags** argument (Argument 2) contains a number intended to represent bit-flags for various functions that control the settings of the path the Pathwalker Path Point belongs to:

| Name                                 | Value | Description |
|--------------------------------------|-------|-------------|
| Control point (enables flag reading) | 1     | Tells the path allocation system that this is a "control point", meaning that the flags argument should be read. **Without this flag, the other flags will be ignored by the system.** |
| Non-looping                          | 2     | This path should not loop; when a Pathwalker reaches the end of this path, it will turn around and go the other way, |
| Trace in reverse                     | 4     | This path should initially be followed in reverse. a Pathwalker will begin moving _backwards_ along this path. |
| Display path                         | 8     | This path should have its points displayed in-game. The path allocation system will create an object representing a point along the path. This should primarily be used for debugging and/or showcase purposes. |
