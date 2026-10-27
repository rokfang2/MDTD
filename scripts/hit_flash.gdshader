shader_type canvas_item;
uniform float flash : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    COLOR.rgb = mix(COLOR.rgb, vec3(0.90, 1.0, 0.95), flash);
}
