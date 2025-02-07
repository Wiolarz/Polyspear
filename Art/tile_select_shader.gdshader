shader_type canvas_item;

void fragment() {
	float opacity = 164.0 / 255.0 + 0.2 * sin(TIME * PI);
	COLOR = texture(TEXTURE, UV) * vec4(1.0, 1.0, 1.0, opacity);
}
