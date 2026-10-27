shader_type canvas_item;
render_mode unshaded;
void fragment() {
	vec2 p = UV;
	// Coordenadas contínuas no mundo: variar os volumes sem criar cortes de tiles.
	p.x += 0.32*sin(UV.y*1.13)+0.18*sin(UV.x*0.47+UV.y*0.31);
	p.y += 0.20*sin(UV.x*1.33)-0.20*cos(UV.y*0.71);
	vec2 mirror_uv = 1.0-abs(mod(p,2.0)-1.0);
	COLOR = texture(TEXTURE,mirror_uv);
}
