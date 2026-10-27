shader_type canvas_item;
render_mode unshaded;
uniform bool reverse = true;
uniform float art_scale = 0.72;
void fragment() {
	vec2 uv = UV;
	float mirrored = abs(mod(UV.x/art_scale,2.0)-1.0);
	uv.x = reverse ? mirrored : 1.0-mirrored;
	uv.y = min(UV.y/art_scale,0.999);
	vec4 source = texture(TEXTURE,uv);
	float depth = smoothstep(art_scale,0.98,UV.y);
	COLOR = mix(source,vec4(0.08,0.025,0.14,1.0),depth);
}
