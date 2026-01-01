# Pathwalker
Files and documentation for my implementation of Mario Kart DS' "Pathwalker" system into Dr. Robotnik's Ring Racers

In Ring Racers, very few objects travel along a path, and anything that might need to is often left to the modder's vices to figure out, using varying solutions to varying success.

No more of that; say hello to the **Pathwalker**, a system ported from Mario Kart DS that lets _any object imaginable_ follow their own dedicated path (with some work, of course)!

This is a robust system optimized for both efficiency and more "natural" path-tracing. Paths are allocated on map load, and all the Pathwalkers do is trace themselves along these pre-allocated paths; no need to worry about lag or excessive mapthing checks!
Using path interpolation based on Cubic Hermite splines, objects smoothly ease over to--and steer along--paths of any shape and size.
You can let objects interpolate linearly, as well, along with being able to interpolate in a 3D (X, Y, Z) or 2D (X, Y only) space.

_WARNING: Some functions, for the sake of completion, are provided in this library. Be warned that I have no idea what they do, and you're on your own in regards to implementation and bugfixing._

All relevant Pathwalker assets are grouped into "pathwalker" folders within DL_Pathwalker.pk3, for easy plug-and-play style implementation of the systems into your addons.

Along with that, you can also download a Pathwalker_Extras.zip file, containing a Tutorial area demonstrating the functionality of Pathwalkers, and a RingRacers_pathwalker.cfg file you can implement in HVR, for better information while editing maps.

Have fun, and happy pathwalking!

## Credits
Katsuhisa Sato, Yusuke Shiraiwa, Shunsaku Kato:
- Original Mario Kart DS programming

[Haroohie Pals](https://github.com/HaroohiePals):
- Decompiled headers and given names for MKDS code and data structures (https://github.com/HaroohiePals/MKDS-decomp-headers)
- C# conversions of decompiled MKDS Pathwalker and traffic object code, used in Mario Kart Toolbox (https://github.com/HaroohiePals/MarioKartToolbox)

Cheariisan (me lol):
- Pathwalker path point sprite asset
- Conversions of both personally-decompiled Pathwalker C code, and Mario Kart Toolbox's C# conversions of Pathwalker and traffic object code, to Lua
- "Pathwalkers" Tutorial room
- HVR config file for Pathwalker points


## Disclaimer
This system uses elements of decompiled (reverse engineered) code from Mario Kart DS, reworked to both use the Lua language, and to be reliant on Ring Racers' internal systems, and not any internal Nintendo DS systems.
All potentailly reliant systems have been, to the best of my ability (and extent of my knowledge), reworked to use Ring Racers systems, or use unique ways of getting the same result (clean-room code). **No assets from Mario Kart DS have been included in this addon, nor will they be.**

Mario Kart Toolbox is licensed under the MIT license; to adhere to the permissions of the MIT license, the license file (MKTOOLBOX_LICENSE) has been included in DL_Pathwalker.pk3.
