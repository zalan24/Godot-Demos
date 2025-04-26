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

Godot does have a built in exp height fog already, but it works in a different way. The existing solution computes the strength of the fog on a given pixel based on the world-y position of that pixel. It's completely independent of the pixel's distance from the camera or the direction of the view ray. This solution looks surprisingly well when looked at from above, but falls apart as the camera enters the fog.

In a nutshell, the built-in solution uses the fog density at a pixel's world position directly as the fog strength applied to that pixel on the screen. My solution simply integrates the fog density along the ray between the camera and the pixel's world position to calculate the fog strength. This way, the fog gets stronger with distance.

The solution that I present here is very similar to how [Unreal Engine does it for example](https://dev.epicgames.com/documentation/en-us/unreal-engine/exponential-height-fog-user-guide?application_version=4.27).

## Math

Full fog density:
$$fog\_density\left(p\right) = e^{-(p_y-base\_height)*h\_falloff}*base\_density$$

Where *p* is the world-space position; *base_height* is a parameter of the fog, a reference height to offset the fog along Y; *h_falloff* is a parameter that changes how quickly the density changes as we move along Y; *base_density* determines the density at the *base_height*.

1 unit of *density* reduces transparency (percentage of light that gets through) to *1/e = exp(-1)*.

The distribution of density along the view ray is not important, only the total density (the integral) is.

```math
fog\_transparency(o, v, L) = exp(-\int_0^L fog\_density\left(o+v*t\right) \,dt) =
```
```math
exp(-\int_0^L e^{-(o_y+v_y*t-base\_height)*h\_falloff}*base\_density \,dt) =
```
```math
exp(-base\_density * \int_0^L e^{(base\_height-o_y-v_y*t)*h\_falloff} \,dt) =
```
```math
exp(-base\_density * (-\frac{e^{(base\_height-o_y-v_y*L)*h\_falloff}}{v_y*h\_falloff} + \frac{e^{(base\_height-o_y-v_y*0)*h\_falloff}}{v_y*h\_falloff})) =
```
```math
exp(-base\_density * (\frac{e^{(base\_height-o_y-v_y*0)*h\_falloff} - e^{(base\_height-o_y-v_y*L)*h\_falloff}}{v_y*h\_falloff})) =
```
```math
exp(-base\_density * (\frac{e^{(base\_height-o_y)*h\_falloff} - e^{(base\_height-o_y-v_y*L)*h\_falloff}}{v_y*h\_falloff}))
```

Where *o* is the the origin of the view ray; *v* is the view ray's normalized direction; and *L* is the view ray's length.

The above expression can be used if the *v.y* value is not zero. If it is, meaning that the view ray is horizontal, the fog density is constant over distance, so the simple exponential fog formula can be used (already implemented in Godot).

## Screenshots

### From Above

#### No Fog
![Screenshot from above, No fog](screenshots/no_fog.webp)
#### Original Fog
![Screenshot from above, Old fog](screenshots/old_fog.webp)
#### Proposed Implementation
![Screenshot from above, New fog](screenshots/new_fog.webp)

#### Notes

The terrain close to the camera receives low amount of fog in both cases, so the difference is not apparent.

The fog's effect on the sky is very different. Both option use full sky effect, but the proposed implementation takes into account the exponential nature of the fog in these calculations. The sky does get hidden by it if the camera is deep inside the fog, but as the camera emerges, the sky becomes visible.

The proposed solution also looks more natural in this situation.

### From Below

#### No Fog
![Screenshot from below, No fog](screenshots/low_no_fog.webp)
#### Original Fog
![Screenshot from below, Old fog](screenshots/low_old_fog.webp)
#### Proposed Implementation
![Screenshot from below, New fog](screenshots/low_new_fog.webp)

#### Notes

This is the scenario that better shows the problems with the existing implementation.

The fog is exactly as strong on the terrain close to the camera as it is on the terrain far away. In fact, it doesn't matter how close we move the camera to the terrain, the fog remains the same.

Compare that to the proposed solution: fog is weak in the foreground and gets quite strong in the background.

The proposed solution also affects the sky more on this image, then in the previous one, because the camera is deeper in the fog.

## Parameters

The previous photos can be replicated by running this demo project with the default scene and using on of the two provided camera as *current* camera. Also apply the fog parameters from below.

Fog parameters for old fog:
```
fog_enabled = true
fog_light_color = Color(0.517647, 0.635294, 0.607843, 1)
fog_sun_scatter = 0.48
fog_density = 0.0
fog_height = 197.74
fog_height_density = 0.005
```

Fog parameters for the new fog:
```
fog_enabled = true
fog_light_color = Color(0.517647, 0.635294, 0.607843, 1)
fog_sun_scatter = 0.48
fog_density = 0.0
fog_height = 42.37
fog_height_density = 0.01
```