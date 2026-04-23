import Reflect;

preset("loadEditor", true);

preset("defaultValues", 
    [
        { name: "Property", type: "String", value: "" },
        { name: "Value", type: "String", value: "" }
    ]
);

function execute(property:String, value:Dynamic) {
    if (_note == null || property == "") { return; }
    Reflect.setProperty(_note, property, value);
}