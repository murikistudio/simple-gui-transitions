/*
* Scale and move GUI controls around using uniforms.
* Make materials unique and local to scene to ensure individual transforms.
*/

shader_type canvas_item;

uniform vec2 slide = vec2(0.0, 0.0);
uniform vec2 scale = vec2(1.0, 1.0);

void vertex() {
	vec2 vtx = vec2((VERTEX.x + slide.x) * scale.x, (VERTEX.y + slide.y) * scale.y);
	VERTEX = vtx;
}
