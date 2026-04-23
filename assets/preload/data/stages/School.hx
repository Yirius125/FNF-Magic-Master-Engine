import states.PlayState;
import flixel.FlxSprite;
import utils.Settings;
import utils.Files;
import utils.Paths;
import flixel.FlxG;

preset("camP_1", [380, 310]);
preset("camP_2", [930, 530]);
preset("initChar", 6);
preset("zoom", 1);

var sky:FlxSprite = null;
var school:FlxSprite = null;
var street:FlxSprite = null;
var backtrees:FlxSprite = null;
var fronttrees:FlxSprite = null;
var petals:FlxSprite = null;
var girls:FlxSprite = null;

function cache(list:Array<Dynamic>):Void {
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/weebSky') });
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/weebSchool') });
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/weebStreet') });
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/weebTreesBack') });
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/weebTrees') });
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/petals') });
	list.push({ type: "IMAGE", instance: Paths.image('stages/school/bgFreaks') });
}

function create():Void {
	sky = new FlxSprite(-280, -50).loadGraphic(Paths.image('stages/school/weebSky'));
	sky.scale.set(6, 6);
	sky.updateHitbox();
	sky.scrollFactor.set(0.1, 0);
	sky.antialiasing = false;
	push(sky);

	school = new FlxSprite(-277, 0).loadGraphic(Paths.image('stages/school/weebSchool'));
	school.scale.set(6, 6);
	school.updateHitbox();
	school.scrollFactor.set(0.3, 1);
	school.antialiasing = false;
	push(school);

	street = new FlxSprite(-277, 0).loadGraphic(Paths.image('stages/school/weebStreet'));
	street.scale.set(6, 6);
	street.updateHitbox();
	street.antialiasing = false;
	push(street);

	backtrees = new FlxSprite(-277, 0).loadGraphic(Paths.image('stages/school/weebTreesBack'));
	backtrees.scale.set(6, 6);
	backtrees.updateHitbox();
	backtrees.antialiasing = false;
	push(backtrees);

	fronttrees = new FlxSprite(-890, -1060);
	fronttrees.frames = Files.getAtlas(Paths.image('stages/school/weebTrees'));
	fronttrees.animation.addByPrefix('idle', 'trees');
	if (Settings.get('Animated', 'GraphicSettings')) { fronttrees.animation.play('idle'); }
	fronttrees.antialiasing = false;
	fronttrees.scale.set(6, 6);
	fronttrees.updateHitbox();
	push(fronttrees);

	petals = new FlxSprite(500, 450);
	petals.frames = Files.getAtlas(Paths.image('stages/school/petals'));
	petals.animation.addByPrefix('idle', 'PETALS ALL');
	if (Settings.get('Animated', 'GraphicSettings')) { petals.animation.play('idle'); }
	petals.antialiasing = false;
	petals.scale.set(6, 6);
	petals.updateHitbox();
	push(petals);

	girls = new FlxSprite(-650, 151);
	girls.frames = Files.getAtlas(Paths.image('stages/school/bgFreaks'));
	girls.animation.addByPrefix('idle', 'BG girls group');
	girls.animation.addByPrefix('freak', 'BG fangirls dissuaded');
	if (Settings.get('Animated', 'GraphicSettings')) { 
		girls.animation.play('idle');
		if (PlayState.song.song == "Roses") {
			girls.animation.play('freak');
		}
	}
	girls.scale.set(6, 6);
	girls.updateHitbox();
	girls.antialiasing = false;
	push(girls);
}