shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.32941176470588, 0.0, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.073, 0.0, 0.47, 1.0);


void fragment() {
	COLOR = mix(color1, color2, texture(TEXTURE, UV).x);
}
