import flixel.FlxG;

preset("defaultValues", [
    { name: "Shake", type: "Float", value: 0.03 },
    { name: "Duration", type: "Float", value: 1 }
]);

function execute(_shake:Float, _time:Float):Void {
    FlxG.camera.shake(_shake, _time, null, true);
}