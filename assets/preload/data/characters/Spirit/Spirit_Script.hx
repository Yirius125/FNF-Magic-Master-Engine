import flixel.addons.effects.FlxTrail;
import flixel.FlxSprite;

var character:FlxSprite;
var evil_trail:FlxTrail;

function preload():Void {
    evil_trail = new FlxTrail(characterSprite, null, 4, 24, 0.3, 0.069);
    add(evil_trail);
}