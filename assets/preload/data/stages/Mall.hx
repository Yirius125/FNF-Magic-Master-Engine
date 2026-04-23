import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;

preset("initChar", 5);
preset("camP_1", [-15,-290]);
preset("camP_2", [1340,490]);
preset("zoom", 0.8);

var background:FlxSprite = null;
var upperBoopers:FlxSprite = null;
var backstairs:FlxSprite = null;
var tree:FlxSprite = null;
var bottomBoopers:FlxSprite = null;
var floorSnow:FlxSprite = null;
var santa:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/bgWalls')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/upperBop')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/bgEscalator')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/christmasTree')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/bottomBop')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/fgSnow')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mall/santa')});
	temp.push({type: "SOUND", instance: Paths.sound('stages/mall/Lights_Shut_off')});
}

function create():Void {
	background = new FlxSprite(-1300, -500).loadGraphic(Files.getGraphic(Paths.image('stages/mall/bgWalls')));
	background.scrollFactor.set(0.2, 0.2);
	push(background);

	upperBoopers = new FlxSprite(-330, 0);
	upperBoopers.frames = Files.getAtlas(Paths.image('stages/mall/upperBop'));
	upperBoopers.animation.addByPrefix('beat', 'Upper Crowd Bob');
	if (Settings.get('Animated', 'GraphicSettings')) { upperBoopers.animation.play('idle'); }
	upperBoopers.scrollFactor.set(0.3, 0.3);
	push(upperBoopers);

	backstairs = new FlxSprite(-1350, -550).loadGraphic(Files.getGraphic(Paths.image('stages/mall/bgEscalator')));
	backstairs.scrollFactor.set(0.3, 0.3);
	push(backstairs);

	tree = new FlxSprite(400, -250).loadGraphic(Files.getGraphic(Paths.image('stages/mall/christmasTree')));
	tree.scrollFactor.set(0.4, 0.4);
	push(tree);

	bottomBoopers = new FlxSprite(-470, 140);
	bottomBoopers.frames = Files.getAtlas(Paths.image('stages/mall/bottomBop'));
	bottomBoopers.animation.addByPrefix('beat', 'Bottom Level Boppers Idle');
	if (Settings.get('Animated', 'GraphicSettings')) { bottomBoopers.animation.play('idle'); }
	bottomBoopers.scrollFactor.set(0.9, 0.9);
	push(bottomBoopers);

	floorSnow = new FlxSprite(-820, 700).loadGraphic(Files.getGraphic(Paths.image('stages/mall/fgSnow')));
	push(floorSnow);

	santa = new FlxSprite(-640, 150);
	santa.frames = Files.getAtlas(Paths.image('stages/mall/santa'));
	santa.animation.addByPrefix('idle', 'santa idle in fear');
	if (Settings.get('Animated', 'GraphicSettings')) { santa.animation.play('idle'); }
	push(santa);

	setGlobal();
}

function beatHit(curBeat:Int):Void {
    if (!Settings.get('Animated', 'GraphicSettings')) { return; }

    upperBoopers.animation.play("beat", true);
    bottomBoopers.animation.play("beat", true);
    santa.animation.play("idle", true);
}