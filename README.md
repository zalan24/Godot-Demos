# Exponential Height Fog Demo

The implementation can be found on my Godot-fork as a feature branch: https://github.com/zalan24/godot/tree/feature-exp-height-fog

## What is Exponential Height Fog?

It's a simple type of fog, where the density is calculated based on world-y position. As we move up along the Y (up) axis, the fog exponentially gets lower. It resembles how the atmosphere's density decreases.

Simplified density model:
```math
simple\_fog\_density\left(pos\right) = e^{-pos_y}*base\_density
```

It is a very useful and simple tool, which can achieve really nice results at a very low performance cost.

Exp height fog can be applied to the sky naturally. It won't produce a visible contour between far terrain and the sky behind, but it will also leave the sky visible through the fog.

Exponential height fog is a great alternative to volumetric fog, in case the range or performance is important. It can be especially useful in case of large open world maps. It can render really nice fog at large distances at a very low performance cost.

In order achieve good performance, it has some limitations. It can't use the height-above-terrain, as that would lack a simple analytical solution to the fog density between the camera and a point in the world. Since no iteration or sampling is used, it also can't use shadows. It won't produce godrays.

## Current State

This feature is currently in prototype/demo state. It shows what results can be achieved, but the implementation is not final.

Features (existing):
* Analytical exp height fog calculations for correct fog density
* Applied to scenes (forward+ mode only)
* Applied to skies (forward+ mode only)
* Good performance (fog is calculated with a simple closed formula, no sampling/iterations required)

Missing:
* Implementations for other rendering modes
* Deciding how this feature should be integrated (Should it replace fully the existing exp height fog? Can it be applied at the same time as normal fog?)
* Edit fog parameters based on the previous point
* Clean up the code

## Why This Change?

Godot does have a built in exp height fog already, but it works in a different way. The existing solution computes the strength of the fog on a given pixel based on the world-y position of that pixel. It's completely independent of the pixel's distance from the camera or the direction of the view ray. This solution doesn't seem useful to me.

In a nutshell, the built-in solution uses the fog density at a pixel's world position directly as the fog strength applied to that pixel on the screen. My solution simply integrates the fog density along the ray between the camera and the pixel's world position to calculate the fog strength.

The solution that I present here is very similar to how [Unreal Engine does it for example](https://dev.epicgames.com/documentation/en-us/unreal-engine/exponential-height-fog-user-guide?application_version=4.27).

## Math

Full fog density:
$$fog\_density\left(pos\right) = e^{-(pos_y-base\_height)*h\_falloff}*base\_density$$

Where *base_height* is a parameter of the fog, a reference height to offset the fog along Y; *h_falloff* is a parameter that changes how quickly the density changes as we move along Y; *base_density* determines the density at the *base_height*.

1 unit of *density* reduces transparency (percentage of light that gets through) to *1/e = exp(-1)*.

The distribution of density along the view ray is not important, only the total density (the integral) is.

```math
fog\_transparency(pos, dir, L) = exp(-\int_0^L fog\_density\left(pos+dir*t\right) \,dt) =
```
```math
exp(-\int_0^L e^{-(pos_y+dir_y*t-base\_height)*h\_falloff}*base\_density \,dt) =
```
```math
exp(-base\_density * \int_0^L e^{(base\_height-pos_y-dir_y*t)*h\_falloff} \,dt) =
```
```math
exp(-base\_density * (-\frac{e^{(base\_height-pos_y-dir_y*L)*h\_falloff}}{dir_y*h\_falloff} + \frac{e^{(base\_height-pos_y-dir_y*0)*h\_falloff}}{dir_y*h\_falloff})) =
```
```math
exp(-base\_density * (\frac{e^{(base\_height-pos_y-dir_y*0)*h\_falloff} - e^{(base\_height-pos_y-dir_y*L)*h\_falloff}}{dir_y*h\_falloff})) =
```
```math
exp(-base\_density * (\frac{e^{(base\_height-pos_y)*h\_falloff} - e^{(base\_height-pos_y-dir_y*L)*h\_falloff}}{dir_y*h\_falloff})) =
```

Where *pos* is the the origin of the view ray; *dir* is the view ray's normalized direction; and *L* is the view ray's length.

The above expression can be used if the *dir.y* value is not zero. If it is, meaning that the view ray is horizontal, the fog density is constant over distance, so the simple exponential fog formula can be used (already implemented in Godot).
