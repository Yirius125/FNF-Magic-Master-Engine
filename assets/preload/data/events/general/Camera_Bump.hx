import Std;

preset("defaultValues", [
    { name:"Game", type: "Float", value: 0.015 },
    { name:"HUD", type: "Float", value: 0.03 },
]);

function execute(_game:Float, _hud:Float):Void {
    if (!getState().defaultBumps) { return; }

    getState().camGame.zoom += _game;
    getState().camHUD.zoom += _hud;
}