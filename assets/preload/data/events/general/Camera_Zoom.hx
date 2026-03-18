import Std;

preset("defaultValues", [
    { name: "Zoom", type: "Float", value: 1 },
    { name: "Type", type: "List", value: 0 , list: ["Add", "Set", "Reset"] },
    { name: "Camera", type: "List", value: 0 , list: ["Default", "Game"] }
]);

function execute(_value:Float, _type:String, _camera:String):Void {
    if (_type == "Add") { if (_camera == "Default") { getState().defaultZoom += _value; } else { getState().camGame.zoom += _value; } }
    else if (_type == "Set") { if (_camera == "Default") { getState().defaultZoom = _value; } else { getState().camGame.zoom = _value; } }
    else if (_type == "Reset") { if (_camera == "Default") { getState().defaultZoom = getState().stage.zoom; } else { getState().camGame.zoom = getState().stage.zoom; } }
}