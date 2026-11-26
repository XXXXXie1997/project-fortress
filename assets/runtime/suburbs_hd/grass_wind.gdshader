shader_type spatial;
render_mode cull_disabled;
uniform vec4 base_color : source_color = vec4(.25,.28,.16,1.);
uniform vec4 tip_color : source_color = vec4(.65,.56,.31,1.);
varying float height_mix;
void vertex() {
	height_mix = clamp(VERTEX.y * 3.0, 0.0, 1.0);
	vec3 p = MODEL_MATRIX[3].xyz;
	VERTEX.x += sin(TIME*1.25 + p.x*.73 + p.z*.42) * height_mix*.048;
}
void fragment() {
	ALBEDO = mix(base_color.rgb,tip_color.rgb,height_mix);
	ROUGHNESS = 1.;
}
