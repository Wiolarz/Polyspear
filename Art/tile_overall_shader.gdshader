shader_type canvas_item;

uniform float highlight_intensity = 0.0;

const vec3 highlight_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 start_color = texture(TEXTURE, UV);
	vec3 color = start_color.xyz;
	color = mix(color.xyz, highlight_color, highlight_intensity);
	COLOR = vec4(color.xyz, start_color.w);
}
