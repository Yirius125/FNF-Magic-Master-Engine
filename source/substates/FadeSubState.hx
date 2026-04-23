package substates;

import flixel.group.FlxGroup.FlxTypedGroup;
import objects.scripts.Script;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import states.MusicBeatState;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.FlxSubState;
import flixel.FlxObject;
import flixel.FlxSprite;
import states.VoidState;
import flixel.FlxCamera;
import flixel.FlxState;
import flixel.FlxG;

using utils.Files;

class FadeSubState extends FlxSubState {
	public static var fade:FlxSprite;

    public var TARGET:FlxState;

	public var curCamera:FlxCamera;
    
    public function new(?_target:FlxState) {
        this.TARGET = _target;
        
        super();
	}

    override function create():Void {
		curCamera = new FlxCamera();
		curCamera.bgColor = FlxColor.BLACK;
		curCamera.bgColor.alpha = 0;
		FlxG.cameras.add(curCamera);

        super.create();
		
		this.camera = curCamera;

        fade = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        add(fade);

        var l_transitionScript:Script = null;
        for (l_script in Mods.mod_scripts) { 
            if (l_script.getVar("entryTransition") == null) { continue; }
            if (l_script.getVar("exitTransition") == null) { continue; }
            
            l_transitionScript = l_script;
            l_transitionScript.setVar("transitionSubState", this);

            break; 
        }
        
        if (TARGET != null) {
            if (l_transitionScript != null) { l_transitionScript.call("entryTransition"); } 
            else { startEntryTransition(); }
        } else { 
            if (l_transitionScript != null) { l_transitionScript.call("exitTransition"); } 
            else { startExitTransition(); }
        }
    }

    public function startEntryTransition():Void {
        fade.alpha = 0;

        FlxTween.tween(fade, { alpha: 1 }, 0.5, { onComplete: (_twn:FlxTween) -> { endTransition(); }, ease: FlxEase.linear });
    }
    public function startExitTransition():Void {
        fade.alpha = 1;

        FlxTween.tween(fade, { alpha: 0 }, 0.5, { onComplete: (_twn:FlxTween) -> { endTransition(); }, ease: FlxEase.linear});
    }
    
    public function endTransition():Void {
        if (TARGET != null) {
            MusicBeatState.state.persistentDraw = false;
            FlxG.switchState(new VoidState(TARGET));
        } else {
            MusicBeatState.state.persistentUpdate = true;
            this.close();
        }
    }

	override public function close():Void {
		FlxG.cameras.remove(curCamera);
		curCamera.destroy();

		super.close();
	}
}