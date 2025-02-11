shader_type canvas_item;

uniform float highlight_intensity = 0.0;
uniform float contrast_boost = 0.0;
uniform float modulate_intensity = 0.0;

uniform vec3 modulate_color : source_color = vec3(1.0, 1.0, 1.0);

const vec3 highlight_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 start_color = texture(TEXTURE, UV);
	vec3 color = start_color.xyz;

	// first, apply simple highlight
	color = mix(color, highlight_color, highlight_intensity);

	// apply contrast boost
	color -= vec3(0.5);
	color *= vec3(1.0 + contrast_boost);
	color += vec3(0.5);

	// apply partial modulation
	color = mix(color, color * modulate_color, modulate_intensity);

	// apply original alpha and write to output
	COLOR = vec4(color.xyz, start_color.w);
}
