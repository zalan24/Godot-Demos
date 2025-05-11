# Exponential Height Fog Demo

This is a demo project. The feature itself is implemented in my Godot fork as a feature branch: [feature-exp-height-fog](https://github.com/zalan24/godot/tree/feature-exp-height-fog)

## Current State

This feature is currently in a prototype/demo state. It demonstrates achievable results, but the implementation is not final.

### Features (implemented):

* Analytical exp height fog calculations for correct fog density
* Applied to scenes
* Applied to skies
* Good performance (fog is calculated with a simple closed formula, no sampling or iterations required)

### Missing:

* Deciding how it should interact with existing fog options:
  * Replace the original height fog and complement constant fog (currently implemented)
  * Add as a new fog type, preserving all existing functionality (all can be active simultaneously)
  * Other possible options...
* Cleaning up and finalizing the code

## Running the Project

You’ll need to set up a dev environment for building Godot. Follow [this guide](https://docs.godotengine.org/en/stable/contributing/development/compiling/index.html) for instructions.

Then, run the following commands:

```bash
$ git clone -b exp-height-fog --recurse-submodules https://github.com/zalan24/Godot-Demos.git
$ cd Godot-Demos/godot
$ scons target=editor
$ cd bin
$ ./godot.<build-variant>
```

From the Godot editor, open the `Godot-Demos/test-content` directory.

## What is Exponential Height Fog?

It's a simple type of fog where density is calculated based on the world-space Y position. As we move along the Y-axis (up), the fog density decreases exponentially, resembling how atmospheric density decreases with altitude.

Simplified density model:
```math
simple\_fog\_density\left(pos\right) = e^{-pos_y}*base\_density
```

It is a very useful and simple technique that can achieve really nice results at a very low performance cost.

Godot can only achieve the same effect using volumetric fog, but that comes with a high performance cost and strict limitations (fog volume size).

Considering how effective and widely useful the exponential height fog is, it should be a built-in feature in any 3D game engine.

## Why This Change?

Godot does have a built in exp height fog already, but it behaves differently and produces distinct results. The original and proposed fog types do look surprisingly similar from a distance as long as the camera is above the dense part of the fog. On the other hand, close-ups of the original fog look quite bad.

In a nutshell, the proposed solution integrates fog density along the ray from the camera to the pixel's world position, making the fog appear stronger with distance. This is calculated using a simple closed-form expression, so barely any performance is sacrificed for a significant visual impact (check the screenshots and the performance results later in this document).

This approach is similar to [Unreal Engine's implementation](https://dev.epicgames.com/documentation/en-us/unreal-engine/exponential-height-fog-user-guide?application_version=4.27).

## Math

Exponential height fog density:
```math
\text{fog\_density}(p) = e^{-(p_y - \text{base\_height}) \cdot h\_falloff} \cdot \text{base\_density}
```

Where:

* `p` is a world-space position
* `base_density` is the fog density at `base_height`
* `h_falloff` controls how rapidly density changes along the Y-axis. It can be negative for an inverted effect, or zero for constant density.

1 unit of *density* over a meter (unit distance) reduces transparency (percentage of light that gets through) to the fraction of *1/e = exp(-1)* or *~36.78794412%*. This definition is consistent with the built-in exponential fog.

**Fog transparency** along a view ray from origin `o` in direction `v` of length `L`:

```math
\text{fog\_transparency}(o, v, L) = \exp\left(-\int_0^L \text{fog\_density}(o + v \cdot t) \,dt\right) =
```
```math
\exp\left(-\text{base\_density} \cdot \frac{e^{(base\_height - o_y) \cdot h\_falloff} - e^{(base\_height - o_y - v_y \cdot L) \cdot h\_falloff}}{v_y \cdot h\_falloff}\right)
```

If `v_y * h_falloff == 0` (horizontal ray or zero falloff), the density is constant:

```math
\text{fog\_transparency}(o, v, L) = \exp(-\text{base\_density} \cdot L \cdot \text{const\_density})
```

Where:

```math
\text{const\_density} = e^{-(o_y - \text{base\_height}) \cdot h\_falloff}
```

### Sky

For sky rendering, the view ray extends to infinity. The previous calculation do work as long as the fog exponentially decreases along the ray. Otherwise, the inner integral would be infinite &#8594; the the transparency as a whole converges to 0.

```math
fog\_transparency(o, v, \infty) = exp(-\int_0^\infty fog\_density\left(o+v \cdot t\right) \,dt) =
```
```math
exp(-\int_0^\infty e^{-(o_y+v_y \cdot t-base\_height) \cdot h\_falloff} \cdot base\_density \,dt) =
```
```math
exp(-base\_density \cdot \int_0^\infty e^{(base\_height-o_y-v_y \cdot t) \cdot h\_falloff} \,dt) =
```
```math
exp(-base\_density \cdot \frac{e^{(base\_height-o_y-v_y \cdot 0) \cdot h\_falloff}}{v_y \cdot h\_falloff}) =
```
```math
exp(-base\_density \cdot \frac{e^{(base\_height-o_y) \cdot h\_falloff}}{v_y \cdot h\_falloff})
```

The above expression is only valid if *v_y\*h\_falloff > 0*, that is, the density decreases exponentially along the ray. Otherwise:

```math
fog\_transparency(o, v, \infty) = 0
```

## Screenshots

### From Above

* **No Fog**
  ![No fog](screenshots/no_fog.webp)
* **Original Fog**
  ![Old fog](screenshots/old_fog.webp)
* **Proposed Implementation**
  ![New fog](screenshots/new_fog.webp)

**Notes:**

Close terrain shows low amount of fog in both cases, so differences are subtle.

The fog's effect on the sky is very different. Both option use full sky effect multiplier, but the proposed implementation takes into account the exponential nature of the fog in these calculations. The sky does get hidden by it if the camera is deep inside the fog, but as the camera emerges, the sky becomes visible.

The proposed solution also looks more natural in this situation.

### From Below

* **No Fog**
  ![No fog (below)](screenshots/low_no_fog.webp)
* **Original Fog**
  ![Old fog (below)](screenshots/low_old_fog.webp)
* **Proposed Implementation**
  ![New fog (below)](screenshots/low_new_fog.webp)

**Notes:**

This is the scenario that better shows the problems with the existing implementation.

The fog is exactly as strong on the terrain close to the camera as it is on the terrain far away. In fact, it doesn't matter how close we move the camera to the terrain, the fog remains the same.

Compare that to the proposed solution: fog is weak in the foreground and gets quite strong in the background.

The proposed solution also affects the sky more on this image, then in the previous one, because the camera is deeper in the fog.

## Parameters

To replicate the screenshots, run this demo project with the default scene and using on of the two provided camera as *current camera*. Use the following parameters:

### Original Fog (in unmodified Godot):

```
fog_enabled = true
fog_light_color = Color(0.517647, 0.635294, 0.607843, 1)
fog_sun_scatter = 0.48
fog_density = 0.0
fog_height = 197.74
fog_height_density = 0.005
```

### New Fog:

```
fog_enabled = true
fog_light_color = Color(0.517647, 0.635294, 0.607843, 1)
fog_sun_scatter = 0.48
fog_density = 0.0
fog_height = 42.37
fog_height_density = 0.01
fog_height_falloff = 0.02
```

## Performance

| Testing equipment |                             |
| ----------------- | --------------------------- |
| OS                | Ubuntu 24.04 LTS            |
| GPU               | NVIDIA GeForce RTX™ 4060 Ti |
| CPU               | AMD Ryzen™ 9 7900X          |
| RAM               | 32 GiB                      |

Measured from the upper camera position (using the Camera3D node placed on the scene), in maximized windowed mode with VSync off. I've used SSAA (×2) to make the pixel shaders slower in order to reduce noise in the measurements.

### Results (Full HD with SSAA ×2)

| Configuration       | Frame Time | Notes                  |
| ------------------- | ---------- | ---------------------- |
| No fog              | 2.824 ms   | Reference baseline     |
| Normal fog only     | +33 µs     |                        |
| Original height fog | +40 µs     |                        |
| New height fog      | +49 µs     | **+9 µs** vs. original |

**Without SSAA**, the overhead of the new implementation is around **2–3 µs** higher than the original implementation.
