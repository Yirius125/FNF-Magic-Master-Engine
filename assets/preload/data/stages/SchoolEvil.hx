import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;
import flixel.FlxG;

preset("initChar", 1);
preset("camP_1", [330, 370]);
preset("camP_2", [970, 620]);
preset("zoom", 1.1);

var sky:FlxSprite = null;

function cache(list:Array<Dynamic>):Void {
	list.push({ type: "IMAGE", instance: Paths.image('stages/schoolEvil/animatedEvilSchool') });
}

function create():Void {
	sky = new FlxSprite(-900, -1050);
	sky.frames = Files.getAtlas(Paths.image('stages/schoolEvil/animatedEvilSchool'));
	sky.animation.addByPrefix('idle', 'background 2 instance 1');
	if (Settings.get('Animated', 'GraphicSettings')) { sky.animation.play('idle'); }
	sky.scale.set(6, 6);
	sky.updateHitbox();
	sky.antialiasing = false;
	push(sky);
}