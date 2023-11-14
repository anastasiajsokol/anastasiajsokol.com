float height(vec2 uv){
    return 0.0;
}

void main() {
    vec4 base = modelMatrix * vec4(position, 1.0);

    vec4 pos = vec4(base.x, height(base.xz), base.z, base.w);

    vec4 viewPosition = viewMatrix * pos;
    vec4 projectedPosition = projectionMatrix * viewPosition;
    gl_Position = projectedPosition;
}