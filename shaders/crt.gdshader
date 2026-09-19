shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.12;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.22;
uniform float curvature : hint_range(0.0, 0.1) = 0.015;
uniform float aberration : hint_range(0.0, 0.01) = 0.0012;

vec2 curve_uv(vec2 uv) {
	vec2 delta = uv - 0.5;
	float delta2 = dot(delta, delta);
	return uv + delta * delta2 * curvature;
}

void fragment() {
	vec2 uv = curve_uv(SCREEN_UV);

	// Edge blackout if curved out of bounds
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		// Chromatic Aberration
		float r = texture(screen_texture, uv + vec2(aberration, 0.0)).r;
		float g = texture(screen_texture, uv).g;
		float b = texture(screen_texture, uv - vec2(aberration, 0.0)).b;
		vec3 col = vec3(r, g, b);

		// Scanlines (vertical screen 640px)
		float scanline = sin(uv.y * 320.0 * 3.14159265);
		col -= scanline * scanline_intensity * col;

		// Vignette (darken corners)
		vec2 v_uv = uv * (1.0 - uv.yx);
		float vig = v_uv.x * v_uv.y * 15.0;
		vig = clamp(pow(vig, vignette_intensity), 0.0, 1.0);
		col *= vig;

		COLOR = vec4(col, 1.0);
	}
}
