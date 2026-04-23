import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;

preset("initChar", 4);
preset("camP_1", [450,360]);
preset("camP_2", [820,520]);
preset("zoom", 1.1);

var window:FlxSprite = null;
var back:FlxSprite = null;
var bars:FlxSprite = null;
var blue:FlxSprite = null;
var radio:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('stages/bus/window')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/bus/back')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/bus/bars')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/bus/filtro')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/bus/Radio')});
}

function create():Void {
	window = new FlxSprite(-600, -50);
	window.frames = Files.getAtlas(Paths.image('stages/bus/window'));
	window.animation.addByPrefix('idle', 'window');
	if (Settings.get('Animated', 'GraphicSettings')) { window.animation.play('idle'); }
	window.scale.set(1.2, 1.2);
	window.updateHitbox();
	window.scrollFactor.set(0.8, 0.8);
	push(window);

	back = new FlxSprite(-200, -50);
	back.loadGraphic(Files.getGraphic(Paths.image('stages/bus/back')));
	back.scrollFactor.set(0.9, 0.9);
	back.scale.set(1.2, 1.2);
	back.updateHitbox();
	push(back);

	bars = new FlxSprite(-70, 0);
	bars.loadGraphic(Files.getGraphic(Paths.image('stages/bus/bars')));
	bars.scale.set(1.2, 1.2);
	bars.updateHitbox();
	push(bars);

	blue = new FlxSprite(0, 0);
	blue.loadGraphic(Files.getGraphic(Paths.image('stages/bus/filtro')));
	blue.scrollFactor.set(1.38777878078145e-16, 1.38777878078145e-16);
	push(blue);

	radio = new FlxSprite(480, 530);
	radio.frames = Files.getAtlas(Paths.image('stages/bus/Radio'));
	radio.animation.addByPrefix('idle', 'RADIO', 24, false);
	if (Settings.get('Animated', 'GraphicSettings')) {radio.animation.play('idle'); }
	push(radio);

	setGlobal();
}

function beatHit(curBeat:Int):Void {
	if (!Settings.get("Animated", "GraphicSettings")) { return; }
	radio.animation.play('idle', true);
}