package objects.scripts;

import states.MusicBeatState;
import flixel.FlxBasic;
import hscript.Interp;
import openfl.Lib;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

enum Script_Calls {
    Stop_And_Break;
    Continue;
    Break;
    Stop;
}

class Script extends FlxBasic {
    public var parser = new hscript.Parser();
    public var interp = new hscript.Interp();
    public var program = null;

    public var parent(get, set):Dynamic;
    public function get_parent():Dynamic { return interp.scriptObject; }
    public function set_parent(_parent:Dynamic):Dynamic { return interp.scriptObject = _parent; }

    public var source:String = "";

    public var name:String;
    public var mod:String;

    public override function new():Void {
		parser.allowMetadata = true;
		parser.allowTypes = true;
		parser.allowJSON = true;
        super();

        preset();
    }

    public function force(path:String, ?doExecute:Bool = false):Void {
		#if sys
		if (!FileSystem.exists(path)) { return; }
        setup(File.getContent(path), doExecute);
		#end
    }
    public function load(path:String, ?doExecute:Bool = false):Void {
		if (!Paths.exists(path)) { return; }
        setup(path.getText(), doExecute);
    }

    public function setup(script:String, ?doExecute:Bool = false):Void {
        try {
            source = script;
            this.program = parser.parseString(script);
        } catch(e) {
            trace('[Script Error]: ${e.message}\n${source}');
            Lib.application.window.alert(e.message, "Script Error!");
        }
        
        if (doExecute) { execute(); }
    }

    public function getVar(name:String):Dynamic{ return interp.variables.get(name); }
    public function setVar(name:String, toSet:Dynamic) { interp.variables.set(name, toSet); }
    private function preset():Void {
        setVar('cache', (_list:Array<Dynamic>) -> { });
        setVar('cache_event', () -> { });

        setVar('exit', () -> { });
        setVar('create', () -> { });
        setVar('preload', () -> { });
        setVar('postload', () -> { });
        setVar('preload_event', () -> { });
        
        setVar('update', (elapsed:Float) -> { });
        
        setVar('onClose', () -> { });
        setVar('onFocus', () -> { });
        setVar('onFocusLost', () -> { });        
        setVar('onOpenSubState', () -> { });
        setVar('onCloseSubState', () -> { });
        
        setVar('startSong', (_next) -> { _next(); });
        setVar('endSong', (_next) -> { _next(); });
        
        setVar('songStarted', () -> { });
        setVar('songEnded', () -> { });
        
        setVar('paused', () -> { });

        setVar('beatHit', (curBeat:Int) -> { });
        setVar('stepHit', (curStep:Int) -> { });
        
        setVar('checkScroll', () -> { });

        setVar('dance', () -> { });
        setVar('turnLook', (look:Bool) -> { });
        setVar('scaleCharacter', (scale:Float) -> {});
        setVar('playAnim', (name:String, force:Bool) -> {});

        setVar("preset", (name:String, func:Any) -> { setVar(name, func); });
        setVar("getset", (name:String) -> { return getVar(name); });

        setVar('onDestroy', () -> { });
        setVar('destroy', () -> { this.destroy(); });

        setVar("setGlobal", () -> { MusicBeatState.state.scripts.set(this.name, this); });

        setVar('getParent', () -> { return this.parent; });

        setVar('getMod', () -> { return Mods.get(mod); });
		setVar('getState', () -> { return states.MusicBeatState.state; });
        setVar('getScriptMod', () -> { return Mods.mod_scripts.get(mod); });
        setVar('getScript', (key:String) -> { return states.MusicBeatState.state.scripts.get(key); });

        setVar('Stop_And_Break', Stop_And_Break);
        setVar('Script_Calls', Script_Calls);
        setVar('Continue', Continue);
        setVar('Break', Break);
        setVar('Stop', Stop);
    }
    
    public function execute():Void{ 
        if (program == null) { trace('Null Program'); return; } 
        
        interp.execute(program); 
    }
    
    public function call(name:String, ?args:Array<Any>):Dynamic {
        if (program == null) { trace('${this.name} | {${name}}: Null Script'); return null; }
        if (interp == null) { trace('${this.name} | {${name}}: Null Interp'); return null; }
        if (!interp.variables.exists(name)) { trace('${this.name} | {${name}}: Null Function [${name}]'); return null; }

        var FUNCT = interp.variables.get(name);
        var toReturn = null;
        if (args != null) {
            try { toReturn = Reflect.callMethod(null, FUNCT, args); } 
            catch(e) { trace('${this.name} | {${name}}: [Function Error](${name}): ${e.toString()}'); }
        } else {
            try { toReturn = FUNCT(); } 
            catch(e) { trace('${this.name} | {${name}}: [Function Error](${name}): ${e.toString()}'); }
        }

        return toReturn;
    }

    public override function destroy():Void {
        call("onDestroy");

        if (MusicBeatState.state != null) { MusicBeatState.state.scripts.remove(name); }
        program = null;

        super.destroy();
    }
}