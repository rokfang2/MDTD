shader_type canvas_item;
uniform float faith : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    vec4 pixel = texture(TEXTURE, UV);
    // Os tons ciano pertencem aos olhos; a capa creme mantém suas cores.
    float cyan = step(pixel.r * 1.2, pixel.b) * step(0.55, pixel.g) * step(0.55, pixel.b);
    COLOR.rgb *= mix(1.0, faith, cyan);
}
