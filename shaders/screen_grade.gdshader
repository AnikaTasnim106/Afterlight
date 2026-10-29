shader_type canvas_item;
// Full-screen finishing pass: vignette + film grain + gentle lift of shadows.
// Drawn as a ColorRect on a CanvasLayer above the world, below the UI.

uniform float vignette_strength : hint_range(0.0, 1.5) = 0.85;
uniform float vignette_softness : hint_range(0.1, 1.0) = 0.55;
uniform float grain : hint_range(0.0, 0.2) = 0.035;
uniform vec4 tint : source_color = vec4(0.04, 0.05, 0.09, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - 0.5;
	c.x *= 1.6;
	float d = length(c);
	float v = smoothstep(0.95 - vignette_softness, 1.05, d) * vignette_strength;
	float n = (hash(uv * 900.0 + fract(TIME * 7.13)) - 0.5) * grain;
	COLOR = vec4(tint.rgb + n, clamp(v + abs(n) * 0.6, 0.0, 1.0));
}
