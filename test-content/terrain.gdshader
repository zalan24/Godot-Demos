shader_type spatial;
render_mode world_vertex_coords;

uniform vec2 world_size = vec2(2000, 2000);
uniform sampler2D perlin_noise_0 : repeat_disable, filter_linear;
uniform float perlin_noise_0_scale = 1;

float get_height_at(vec2 uv)
{
	float baseHeight = texture(perlin_noise_0, uv).x * perlin_noise_0_scale;
	return baseHeight;
}

mat3 get_normal_at(vec2 uv)
{
	float d = 0.001;
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
	
	VERTEX.y += get_height_at(UV);
	NORMAL = get_normal_at(UV) * vec3(0, 1, 0);
}

void fragment() {
	ALBEDO = vec3(0.5);
	// Called for every pixel the material is visible on.
}

