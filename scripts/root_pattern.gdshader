shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 uv = UV;
	// Só o módulo central: as duas terminações continuam intactas.
	if (abs(TEXTURE_PIXEL_SIZE.x-1.0/212.0)<0.00001) {
		uv.x += 0.10*sin(UV.x*1.617);
		uv.y += 0.018*(sin(UV.x*2.414)+sin(UV.x*0.827));
		uv = 1.0-abs(mod(uv,2.0)-1.0);
	}
	COLOR = texture(TEXTURE,uv);
}
