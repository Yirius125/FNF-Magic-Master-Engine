import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;
import flixel.FlxG;

preset("camP_1", [400,230]);
preset("camP_2", [1300,570]);
preset("initChar", 0);
preset("zoom", 1.1);

var background:FlxSprite = null;

function cache(list:Array<Dynamic>):Void {
	list.push({type: "IMAGE", instance: Paths.image('stages/spooky/halloween_bg')});
	list.push({type: "SOUND", instance: Paths.image('stages/spooky/thunder_1')});
	list.push({type: "SOUND", instance: Paths.image('stages/spooky/thunder_2')});
}

function create():Void {
	background = new FlxSprite(-200, -110);
	background.frames = Files.getAtlas(Paths.image('stages/spooky/halloween_bg'));
	background.animation.addByPrefix('idle', 'halloweem bg lightning strike', 30, false);
	background.animation.play('idle');
	push(background);

	setGlobal();
}

var lightningStrikeBeat:Int = 0;
var lightningOffset:Int = 8;
function beatHit(curBeat:Int):Void {
    if (!Settings.get("Animated", "GraphicSettings")) { return; }
	
    if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) { lightningStrikeShit(curBeat); }
}

function lightningStrikeShit(curBeat:Int):Void {
	FlxG.sound.play(Files.getSound(Paths.soundRandom('stages/spooky/thunder_', 1, 2)));
	background.animation.play('idle');

	lightningStrikeBeat = curBeat;
	lightningOffset = FlxG.random.int(8, 24);

    for (f_i in 0...character_Length) { getCharacterById(f_i).emoteAnim('scared', true); }
}