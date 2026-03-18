package flixel.system;

import flixel.addons.display.FlxRuntimeShader;
import flixel.system.FlxAssets.FlxShader;
import flixel.FlxG;

class FlxCustomShader extends FlxRuntimeShader {
    public static var shaders:Array<FlxCustomShader> = [];

    public static var HEADER_DEFAULT:String = '
        #pragma header

        #define iResolution openfl_TextureSize
        #define iChannel0 bitmap
        
        uniform float iTime;
        uniform float iTimeDelta;

        uniform vec4 iMouse;
        uniform vec2 iScroll;

        uniform vec3 iGlobalResolution;
    ';

    public static var BODY_DEFAULT:String = '
        void main() {
            gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
            
            vec2 coord = openfl_TextureCoordv;
            vec2 fragCoord = (coord * openfl_TextureSize);
            
            mainImage(gl_FragColor, fragCoord);
        }
    ';

    public function new(options:{?fragmentsrc:String, ?vertexsrc:String}) {
        var l_scriptCode:String = '${FlxCustomShader.HEADER_DEFAULT}';
        if (options.fragmentsrc != null) { l_scriptCode += '${options.fragmentsrc}'; }
        l_scriptCode += '${FlxCustomShader.BODY_DEFAULT}';

        super(l_scriptCode, options.vertexsrc);
        
        setFloat("iTime", 0.0);
        setFloat("iFrame", 0.0);
        setFloat("iTimeDelta", 0.0);
        setFloatArray("iScroll", [0.0, 0.0]);
        setFloatArray("iMouse", [0.0, 0.0, 0.0, 0.0]);
        setFloatArray("iGlobalResolution", [FlxG.width, FlxG.height, 0]);

        FlxCustomShader.shaders.push(this);
    }

    public function update(elapsed:Float):Void {
        var l_curTime = getFloat("iTime");
        
        setFloat("iTime", l_curTime + elapsed);
        setFloat("iTimeDelta", elapsed);

        var l_mouseX:Float = FlxG.mouse.screenX;
        var l_mouseY:Float = FlxG.mouse.screenY; 

        setFloatArray("iMouse", [l_mouseX, l_mouseY, FlxG.mouse.pressed ? l_mouseX : 0, FlxG.mouse.pressed ? l_mouseY : 0]);
        setFloatArray("iScroll", [FlxG.camera.scroll.x, FlxG.camera.scroll.y]);
    }
}