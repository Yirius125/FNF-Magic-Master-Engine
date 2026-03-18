import objects.game.Character;
import flixel.sound.FlxSound;
import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;
import flixel.FlxG;

preset("initChar", 5);
preset("camP_1", [585,305]);
preset("camP_2", [980,610]);
preset("zoom", 1.1);

var phillyLightsColors = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
var trainMoving:Bool = false;
var trainFrameTiming:Float = 0;
var trainCars:Int = 8;
var trainFinishing:Bool = false;
var trainCooldown:Int = 0;
var startedMoving:Bool = false;
var curLight:Int = -1;

var sky:FlxSprite = null;
var city:FlxSprite = null;
var lights:FlxSprite = null;
var behindtrain:FlxSprite = null;
var train:FlxSprite = null;
var street:FlxSprite = null;
var trainsound:FlxSound = null;

function cache(list:Array<Dynamic>):Void {
	list.push({type: "IMAGE", instance: Paths.image('stages/philly/sky')});
	list.push({type: "IMAGE", instance: Paths.image('stages/philly/win')});
	list.push({type: "IMAGE", instance: Paths.image('stages/philly/city')});
	list.push({type: "IMAGE", instance: Paths.image('stages/philly/train')});
	list.push({type: "IMAGE", instance: Paths.image('stages/philly/street')});
	list.push({type: "IMAGE", instance: Paths.image('stages/philly/behindTrain')});
}

function create():Void {
	sky = new FlxSprite(-100, 0).loadGraphic(Paths.image('stages/philly/sky'));
	sky.scrollFactor.set(0.1, 0.1);
	push(sky);

	city = new FlxSprite(-10, 0).loadGraphic(Paths.image('stages/philly/city'));
	city.scrollFactor.set(0.3, 0.3);
	push(city);

	lights = new FlxSprite(0, 0).loadGraphic(Paths.image('stages/philly/win'));
	lights.scrollFactor.set(0.3, 0.3);
	push(lights);

	behindtrain = new FlxSprite(-40, 50).loadGraphic(Paths.image('stages/philly/behindTrain'));
	push(behindtrain);

	train = new FlxSprite(2000, 360).loadGraphic(Paths.image('stages/philly/train'));
	push(train);

	street = new FlxSprite(-40, 50).loadGraphic(Paths.image('stages/philly/street'));
	push(street);

	trainsound = new FlxSound().loadEmbedded(Files.getSound(Paths.sound('stages/philly/train_passes')));
	FlxG.sound.list.add(trainsound);

    setGlobal();
}

function update(_elapsed:Float):Void {
    if (!Settings.get('Animated', 'GraphicSettings')) { return; }

    if (trainMoving) {
        trainFrameTiming += _elapsed;

        if (trainFrameTiming >= 1 / 24) {
            updateTrainPos();
            trainFrameTiming = 0;
        }
    }

    lights.alpha -= (conductor.crochet / 1000) * FlxG.elapsed * 1.5;
}

function beatHit(curBeat:Int):Void {
    if (!Settings.get('Animated', 'GraphicSettings')) { return; }
    
    if (!trainMoving) { trainCooldown += 1; }

    if (curBeat % 4 == 0) {
        curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
        lights.color = phillyLightsColors[curLight];
        lights.alpha = 1;
    }

    if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8) {
        trainCooldown = FlxG.random.int(-4, 0);
        trainStart();
    }
}

function trainStart():Void {
    trainMoving = true;
    trainsound.play(true);
}

function stepHit(curStep:Int):Void {
    if (trainMoving && trainsound.time >= 4700 && curStep % 2 == 0) {
        var gf_char:Character = getCharacterByStatus("Girlfriend");
        if (gf_char != null) { gf_char.emoteAnim('hairBlow', true); }
    }
}
function updateTrainPos():Void {
    if (trainsound.time >= 4700) {
        train.visible = true;
        startedMoving = true;
    }

    if (startedMoving) {
        train.x -= 400;

        if (train.x < -2000 && !trainFinishing) {
            train.x = -1150;
            trainCars -= 1;

            if (trainCars <= 0) {trainFinishing = true; }
        }

        if (train.x < -4000 && trainFinishing) { trainReset(); }
    }
}

function trainReset():Void {
    train.x = FlxG.width + 200;
    train.visible = false;
    trainMoving = false;
    //trainsound.stop();
    //trainsound.time = 0;
    trainCars = 8;
    trainFinishing = false;
    startedMoving = false;
    
    var gf_char:Character = getCharacterByStatus("Girlfriend");
    if (gf_char != null) { gf_char.emoteAnim('hairFall', true); }
}

function paused(isPaused:Bool):Void {
    if (isPaused) { trainsound.pause(); } 
    else { trainsound.resume(); }
}