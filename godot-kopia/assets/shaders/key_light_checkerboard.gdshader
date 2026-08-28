shader_type canvas_item;

void fragment() {
	vec4 color = texture(TEXTURE, UV);
	float darkest = min(color.r, min(color.g, color.b));
	float brightest = max(color.r, max(color.g, color.b));
	float chroma = brightest - darkest;
	if (color.a < 0.01 || (darkest > 0.78 && chroma < 0.08)) {
		discard;
	}
	COLOR = color;
}

