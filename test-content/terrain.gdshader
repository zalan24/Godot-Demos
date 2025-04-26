shader_type spatial;
render_mode world_vertex_coords;

uniform vec2 world_size = vec2(2000, 2000);
uniform sampler2D perlin_noise_0 : repeat_disable, filter_linear;
uniform float perlin_noise_0_scale = 1;
uniform sampler2D perlin_noise_1 : repeat_disable, filter_linear;
uniform float perlin_noise_1_scale = 1;

uniform float water_level = 10;

uniform vec3 grass_color : source_color = vec3(0, 1, 0);
uniform vec3 water_color : source_color = vec3(0, 0, 1);
uniform vec3 rock_color : source_color = vec3(0.5);

varying float world_height;
varying float steepness;

float get_height_at(vec2 uv)
{
	float baseHeight = texture(perlin_noise_0, uv).x * perlin_noise_0_scale;
	float detailedHeight = texture(perlin_noise_1, uv).x * perlin_noise_1_scale;
	return max(water_level, baseHeight + detailedHeight);
}

mat3 get_normal_at(vec2 uv)
{
	float d = 0.01;
	vec2 world_d = d*world_size;
	float xDiff = get_height_at(uv + vec2(d, 0)) - get_height_at(uv - vec2(d, 0));
	float yDiff = get_height_at(uv + vec2(0, d)) - get_height_at(uv - vec2(0, d));
	
	float dhDx = xDiff/(2.0*world_d.x);
	float dhDy = yDiff/(2.0*world_d.y);
	vec3 xTangent = normalize(vec3(1, dhDx, 0));
	vec3 yTangent = normalize(vec3(0, dhDy, 1));
	vec3 normal = normalize(vec3(-dhDx, 1, -dhDy));
	// dot(xTangent, yTangent) = dhDx*dhDy
	// normal = vec3(-dhDx, 1, -dhDz)

	mat3 surfaceOrientation = mat3(xTangent, normal, yTangent);
	return surfaceOrientation;
}

void vertex() {
	float h = get_height_at(UV);
	world_height = h;
	VERTEX.y += h;
	NORMAL = get_normal_at(UV) * vec3(0, 1, 0);
	steepness = 1.0-NORMAL.y;
}

void fragment() {
	
	const float water_edge = 1.0;
	float wateriness = 0.0;
	if (world_height < water_level+water_edge)
		wateriness = 1.0-(world_height-water_level)/water_edge;
		
	const float rock_limit = 0.1;
	const float rock_edge = 0.05;
	float rockiness = 0.0;
	if (steepness >= rock_limit)
		rockiness = clamp((steepness-rock_limit)/rock_edge, 0.0, 1.0);
	
	ALBEDO = grass_color;
	SPECULAR = 0.0;
	ROUGHNESS = 1.0;
	
	ALBEDO = mix(ALBEDO, rock_color, rockiness);
	SPECULAR = mix(SPECULAR, 0.0, rockiness);
	ROUGHNESS = mix(ROUGHNESS, 1.0, rockiness);
	
	ALBEDO = mix(ALBEDO, water_color, wateriness);
	SPECULAR = mix(SPECULAR, 0.2, wateriness);
	ROUGHNESS = mix(ROUGHNESS, 0.3, wateriness);
}

