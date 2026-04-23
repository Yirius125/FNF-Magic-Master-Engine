import flixel.util.FlxTimer;
import flixel.FlxSprite;
import utils.Files;
import utils.Paths;
import flixel.FlxG;

function playAnim(_name:String, _force:Bool) {
    if (_name == "singLEFT") { return { name: "left" + FlxG.random.int(1, 2) }; } 
    else if (_name == "singRIGHT") { return { name: "right" + FlxG.random.int(1, 2) };}
}