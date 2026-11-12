shader_type canvas_item;
uniform bool warm = false;
void fragment() {
 vec4 c = texture(TEXTURE, UV);
 float l = dot(c.rgb, vec3(0.299,0.587,0.114));
 vec3 muted = mix(vec3(l), c.rgb, 0.55);
 vec3 cool = muted * vec3(0.62,0.78,0.87);
 vec3 shelter = muted * vec3(1.0,0.87,0.66);
 COLOR = vec4(warm ? shelter : cool, c.a);
}
