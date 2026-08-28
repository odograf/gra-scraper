shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float brightest = max(color.r, max(color.g, color.b));
	if (color.a < 0.01 || brightest < 0.018) {
		discard;
	}
	COLOR = color;
}

