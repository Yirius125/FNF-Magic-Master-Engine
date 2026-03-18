import flixel.FlxSprite;
import utils.Files;
import utils.Paths;

preset("initChar", 2);
preset("camP_1", [-60,-2210]);
preset("camP_2", [1110,490]);
preset("zoom", 1.1);

var background:FlxSprite = null;
var floorSnow:FlxSprite = null;
var tree:FlxSprite = null;

function addToLoad(temp):Void {
	temp.push({type: "IMAGE", instance: Paths.image('stages/mallEvil/evilBG')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mallEvil/evilTree')});
	temp.push({type: "IMAGE", instance: Paths.image('stages/mallEvil/evilSnow')});
}

function create():Void {
	background = new FlxSprite(-615, -620).loadGraphic(Files.getGraphic(Paths.image('stages/mallEvil/evilBG')));
	background.scrollFactor.set(0.2, 0.2);
	push(background);

	tree = new FlxSprite(400, -250).loadGraphic(Files.getGraphic(Paths.image('stages/mallEvil/evilTree')));
	tree.scrollFactor.set(0.4, 0.4);
	push(tree);

	floorSnow = new FlxSprite(-620, 700).loadGraphic(Files.getGraphic(Paths.image('stages/mallEvil/evilSnow')));
	push(floorSnow);

}