package flixel.system;

import flixel.system.FlxCustomShader;
import flixel.util.FlxColor;

#if windows
import sys.FileSystem;
import sys.io.File;
#end

class FlxShaderColorSwap extends FlxCustomShader {
    public static var shaderList:Array<FlxShaderColorSwap> = [];

	public static var HEADER_DEFAULT:String = '
        uniform float checkColor;
        uniform int typeChange;
        uniform vec3 replaceColor;
        uniform vec3 replaceColor2;
        
        vec4 get_grad(vec3 color1, vec3 color2) {
            float normalizedX = openfl_TextureCoordv.x; 
            vec3 blendedColor = mix(color1, color2, normalizedX);
            return vec4(blendedColor, 1.0);
        }
        
        float transform_color(float rep_color, int check_color, vec4 texColor, vec4 repColor) {
            if (rep_color <= 0.5) {
                float diff = texColor.r - ((texColor.b + texColor.g) / 2.0);
                if (check_color == 0) return (texColor.b + texColor.g) / 2.0 + (diff * repColor.r);
                else if (check_color == 1) return texColor.g + (repColor.g * diff);
                else if (check_color == 2) return texColor.b + (repColor.b * diff);
            } else if (rep_color <= 1.5) {
                float diff = texColor.g - ((texColor.r + texColor.b) / 2.0);
                if (check_color == 0) return texColor.r + (repColor.r * diff);
                else if (check_color == 1) return (texColor.r + texColor.b) / 2.0 + (diff * repColor.g);
                else if (check_color == 2) return texColor.b + (repColor.b * diff);
            } else if (rep_color <= 2.5) {
                float diff = texColor.b - ((texColor.r + texColor.g) / 2.0);
                if (check_color == 0) return texColor.r + (repColor.r * diff);
                else if (check_color == 1) return texColor.g + (repColor.g * diff);
                else if (check_color == 2) return (texColor.r + texColor.g) / 2.0 + (diff * repColor.b);
            }
            
            if (check_color == 0) return texColor.r;
            if (check_color == 1) return texColor.g;
            if (check_color == 2) return texColor.b;
            
            return 0.0;
        }
    ';
    
    public static var BODY_DEFAULT:String = '
        void mainImage(out vec4 fragColor, in vec2 fragCoord){    
            vec4 texColor = flixel_texture2D(iChannel0, fragCoord / iResolution.xy);
            
            vec4 repColor;
            if(typeChange == 0){
                repColor = vec4(replaceColor, 1.0);
            }else if(typeChange == 1){
                repColor = get_grad(replaceColor, replaceColor2);
            }
        
            vec4 newColor = vec4(
                transform_color(checkColor, 0, texColor, repColor),
                transform_color(checkColor, 1, texColor, repColor),
                transform_color(checkColor, 2, texColor, repColor),
                texColor.a
            );
        
            fragColor = newColor;
        }
    ';

    public var v_typeChange(default, set):Int = 0;
    public function set_v_typeChange(value:Int):Int {
        setFloat("typeChange", value);

        return v_typeChange = value;
    }

    public var v_checkColor(default, set):String = "Blue";
    public function set_v_checkColor(value:String):String {
        var toSet:Int = 2;

        switch (value) {
            case "Red":{ toSet = 0; }
            case "Green":{ toSet = 1; }
            case "Blue":{ toSet = 2; }
        }
        
        setFloat("checkColor", toSet);
        
        return v_checkColor = value;
    }
    
    public var v_replaceColor(default, set):FlxColor;
    public function set_v_replaceColor(value:FlxColor):FlxColor {
        setFloatArray("replaceColor", [value.red / 255.0, value.green / 255.0, value.blue / 255.0]);

        return v_replaceColor = value;
    }
    public var v_replaceColor2(default, set):FlxColor;
    public function set_v_replaceColor2(value:FlxColor):FlxColor {
        setFloatArray("replaceColor2", [value.red / 255.0, value.green / 255.0, value.blue / 255.0]);

        return v_replaceColor2 = value;
    }

    public static function get_shader(new_checkColor:String = "Blue", new_replaceColor:FlxColor, ?new_secondColor:FlxColor):FlxShaderColorSwap {
        for (s in shaderList) {
            if (s.v_checkColor != new_checkColor) { continue; }
            if (s.v_replaceColor != new_replaceColor) { continue; }
            if (new_secondColor != null && s.v_replaceColor2 != new_secondColor) { continue; }

            return s;
        }

        return new FlxShaderColorSwap(new_checkColor, new_replaceColor, new_secondColor);
    }

    public function new(new_checkColor:String = "Blue", new_replaceColor:FlxColor, ?new_secondColor:FlxColor):Void {
        super({ fragmentsrc: FlxShaderColorSwap.HEADER_DEFAULT + FlxShaderColorSwap.BODY_DEFAULT });

        v_typeChange = 0;
        v_checkColor = new_checkColor;
        v_replaceColor = new_replaceColor;
        
        if (new_secondColor != null) { 
            v_replaceColor2 = new_secondColor; 
            v_typeChange = 1; 
        }

        shaderList.push(this);
    }
}