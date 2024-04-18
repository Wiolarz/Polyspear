shader_type canvas_item;

float sqr(float x) {
	return x * x;
}

vec2 rotate(vec2 vector, float angle) {
	return vec2(
		cos(angle) * vector.x + sin(angle) * vector.y,
		-sin(angle) * vector.x + cos(angle) * vector.y
	);
}


void fragment() {
	bool darken = false;
	vec2 fragcoord = FRAGCOORD.xy;
	float angle = 0.16 * sin(TIME * 0.09);
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	fragcoord -= screen_size / 2.0;
	fragcoord = rotate(fragcoord, angle);
	fragcoord += screen_size / 2.0;
	fragcoord += vec2(0.4, -0.1) * sin(TIME * 0.30);
	vec2 v = fragcoord / 5.0;
	darken = sqr(cos(v.x)) > sqr(tan(v.y));
	if (darken) {
		COLOR.xyz *= 0.6;
	}
	COLOR.xyz *= 0.8;
}
