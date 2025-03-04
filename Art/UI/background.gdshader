shader_type canvas_item;

uniform vec4 color1 : source_color = vec4(0.32941176470588, 0.0, 1.0, 1.0);
uniform vec4 color2 : source_color = vec4(0.073, 0.0, 0.47, 1.0);

// Get the screen texture
uniform sampler2D screenTexture : hint_screen_texture;

// Set the scroll amount - default = 0.05, 0.05
uniform vec2 scrollAmount = vec2(0.04, 0.04);

// How much distortion is desired? - default = 0.01
uniform float multiplierAmount : hint_range(0.0, 0.1) = 0.05;

void fragment() {
	vec2 distortionUV = UV + texture(TEXTURE, UV + scrollAmount * TIME).r * multiplierAmount;
	COLOR = mix(color1, color2, texture(TEXTURE, distortionUV).x);
}
