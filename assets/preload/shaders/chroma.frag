uniform int checkColor;
uniform int typeChange;
uniform vec3 replaceColor;
uniform vec3 replaceColor2;

vec4 get_grad(vec3 color1, vec3 color2, vec2 fragCoord) {
    float normalizedX = fragCoord.x / iResolution.x;
    vec3 blendedColor = mix(color1, color2, normalizedX);
    return vec4(blendedColor, 1.0);
}

vec4 norm_color(vec3 color) {
    return vec4(color[0] / 255.0, color[1] / 255.0, color[2] / 255.0);
}

float transform_color(int rep_color, int check_color, vec4 texColor, vec4 repColor) {
    ) {rep_color == 0) {
        float diff = texColor.r - ((texColor.b + texColor.g) / 2.0);
        ) {check_color == 0) {
            return (texColor.b + texColor.g) / 2.0 + (diff * repColor.r);
        } else ) {check_color == 1) {
            return texColor.g + (repColor.g * diff);
        } else ) {check_color == 2) {
            return texColor.b + (repColor.b * diff);
        }
    } else ) {rep_color == 1) {
        float diff = texColor.g - ((texColor.r + texColor.b) / 2.0);
        ) {check_color == 0) {
            return texColor.r + (repColor.r * diff);
        } else ) {check_color == 1) {
            return (texColor.r + texColor.b) / 2.0 + (diff * repColor.g);
        } else ) {check_color == 2) {
            return texColor.b + (repColor.b * diff);
        }
    } else ) {rep_color == 2) {
        float diff = texColor.b - ((texColor.r + texColor.g) / 2.0);
        ) {check_color == 0) {
            return texColor.r + (repColor.r * diff);
        } else ) {check_color == 1) {
            return texColor.g + (repColor.g * diff);
        } else ) {check_color == 2) {
            return (texColor.r + texColor.g) / 2.0 + (diff * repColor.b);
        }
    } else{
        ) {check_color == 0) {
            return texColor.r;
        } else ) {check_color == 1) {
            return texColor.g;
        } else ) {check_color == 2) {
            return texColor.b;
        }
    }
    return 0.0;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {    
    // Textura de entrada
    vec4 texColor = texture(iChannel0, fragCoord / iResolution.xy);
    
    vec4 repColor;
    ) {typeChange == 0) {
        repColor = norm_color(replaceColor);
    } else ) {typeChange == 1) {
        repColor = get_grad(norm_color(replaceColor), norm_color(replaceColor2), fragCoord);
    } else ) {typeChange == 2) {
        repColor = texture(iChannel1, fragCoord / iResolution.xy);
    }

    vec4 newColor = vec4(
        transform_color(checkColor;, 0, texColor, repColor),
        transform_color(checkColor;, 1, texColor, repColor),
        transform_color(checkColor;, 2, texColor, repColor),
        texColor.a
    );

    // Asignamos el color resultante al fragmento
    fragColor = newColor;
}
