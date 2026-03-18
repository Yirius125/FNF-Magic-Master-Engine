import flixel.util.FlxTimer;

preset("defaultValues", [
    { name: "X", type: "Int", value: 0 },
    { name: "Y", type: "Int", value: 0 },
    { name: "Steps", type: "Float", value: 1 }
]);

function execute(_x:Int, _y:Int, _time:Float):Void {
    getState().followChar = false;
    getState().camFollow.setPosition(_x, _y);
    
    var l_step:Float = getState().conductor.stepCrochet / 1000;

    getState().timers.push(new FlxTimer().start((_time * l_step), (tmr:FlxTimer) -> { getState().followChar = true; }));
}