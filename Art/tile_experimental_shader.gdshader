shader_type canvas_item;

uniform float highlight_intensity = 0.0;
uniform vec3 highlight_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec4 start_color = texture(TEXTURE, UV);
	vec3 color = mix(start_color.xyz, highlight_color, highlight_intensity);
	COLOR = vec4(color.xyz, start_color.w);
}
