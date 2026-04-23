import flixel.group.FlxTypedGroup;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;
import flixel.FlxG;
import Type;

preset("initChar", 4);
preset("camP_1", [250,-1000]);
preset("camP_2", [900,450]);
preset("zoom", 0.9);

var fastCarCanDrive:Bool = true;
var isLeftDancing:Bool = false;

var sunset:FlxSprite = null;
var backlimo:FlxSprite = null;
var dancers:FlxTypedGroup<FlxSprite> = null;
var fastcar:FlxSprite = null;
var frontlimo:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('stages/limo/limoSunset')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/limo/bgLimo')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/limo/limoDancer')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/limo/fastCarLol')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/limo/limoDrive')});
	temp.push({type: "SOUND", instance: Paths.sound('stages/limo/carPass0')});
	temp.push({type: "SOUND", instance: Paths.sound('stages/limo/carPass1')});
}

function create():Void {
	sunset = new FlxSprite(-350, -300).loadGraphic(Paths.image('stages/limo/limoSunset'));
	sunset.scrollFactor.set(0.1, 0.1);
	push(sunset);

	backlimo = new FlxSprite(-380, 400);
	backlimo.frames = Files.getAtlas(Paths.image('stages/limo/bgLimo'));
	backlimo.animation.addByPrefix('idle', 'background limo pink');
	if (Settings.get('Animated', 'GraphicSettings')) { backlimo.animation.play('idle'); }
	backlimo.scrollFactor.set(0.4, 0.4);
	push(backlimo);

	dancers = Type.createInstance(FlxTypedGroup, []);
	for (i in 0...5) {
		var dancer:FlxSprite = new FlxSprite(140 + (370 * i), 0);
		dancer.frames = Files.getAtlas(Paths.image('stages/limo/limoDancer'));
		dancer.scrollFactor.set(0.4, 0.4);
		dancer.animation.addByIndices('danceLeft', 'bg dancer sketch PINK', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], '', 24, false);
		dancer.animation.addByIndices('danceRight', 'bg dancer sketch PINK', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], '', 24, false);
		dancer.animation.play('danceLeft');
		dancers.add(dancer);
	}
	push(dancers);

	fastcar = new FlxSprite(-530, -30).loadGraphic(Paths.image('stages/limo/fastCarLol'));
	push(fastcar);

	frontlimo = new FlxSprite(-350, 300);
	frontlimo.frames = Files.getAtlas(Paths.image('stages/limo/limoDrive'));
	frontlimo.animation.addByPrefix('idle', 'Limo stage');
	if (Settings.get('Animated', 'GraphicSettings')) { frontlimo.animation.play('idle'); }
	push(frontlimo);

	setGlobal();
	resetFastCar();
}

function beatHit(curBeat:Int):Void {
	if (!Settings.get('Animated', 'GraphicSettings')) { return; }

	isLeftDancing = !isLeftDancing;
	for (dancer in dancers.members) {
		if (isLeftDancing) { dancer.animation.play('danceLeft', true); }
		else { dancer.animation.play('danceRight', true); }
	}
	
	if(FlxG.random.bool(10) && fastCarCanDrive) { fastCarDrive(curBeat); }
}

function resetFastCar():Void {
	fastcar.y = FlxG.random.int(-110, 0);
	fastcar.x = -12600;
	fastcar.velocity.x = 0;

	fastCarCanDrive = true;
}

function fastCarDrive(curBeat:Int):Void {
	FlxG.sound.play(Files.getSound(Paths.soundRandom('stages/limo/carPass', 0, 1)), 0.7);
	fastcar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
	fastCarCanDrive = false;

	timers.push(new FlxTimer().start(2, (tmr:FlxTimer) -> { trace("F"); resetFastCar(); })); 
}
