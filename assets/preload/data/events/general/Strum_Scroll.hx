import objects.notes.StrumLine;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import Math;

preset("defaultValues", [
    { name: "Id", type: "Int", value: 0 },
    { name: "Scroll", type: "Float", value: 1 },
    { name: "Time", type: "Float", value: 0 }
]);

function execute(_id:Int, _scroll:Float, _time:Float):Void {
    var l_curScroll:Float = Math.abs(_scroll);

    for (f_curStrum in 0...getState().strums.length) {
        var l_stmCurrent:StrumLine = getState().strums.members[f_curStrum];

        if (_time <= 0) { l_stmCurrent.scrollspeed = l_curScroll; }
        else { FlxTween.tween(l_stmCurrent, { scrollspeed: l_curScroll }, Math.abs(_time), { ease: FlxEase.quadInOut }); }
    }
}