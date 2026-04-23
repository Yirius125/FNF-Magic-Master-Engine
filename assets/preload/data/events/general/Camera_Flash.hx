import utils.Settings;
import flixel.FlxG;

preset("defaultValues", [
    { name: "Duration", type: "Float", value: 1 }
]);

function execute(_time:Float):Void {
    if (Settings.get("FlashingLights")) { FlxG.camera.flash(0xffffffff, _time, null, true); }
}