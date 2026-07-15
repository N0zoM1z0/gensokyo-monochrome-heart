shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest, repeat_disable;


void fragment() {
	vec4 sampled = textureLod(screen_texture, SCREEN_UV, 0.0);
	float luminance = dot(sampled.rgb, vec3(0.2126, 0.7152, 0.0722));
	float bit_value = step(0.5, luminance);
	float binary_alpha = step(0.5, sampled.a);
	COLOR = vec4(vec3(bit_value), binary_alpha);
}
