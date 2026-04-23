void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = vec2(fragCoord.x, iResolution.y - fragCoord.y) / iResolution.xy;
    vec4 originalColor = texture(iChannel0, uv);
    vec4 flippedColor = texture(iChannel0, vec2(uv.x, 1.0 - uv.y));
    fragColor = vec4(originalColor.rgb, flippedColor.a);
}