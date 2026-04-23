import Reflect;

preset("loadEditor", true);

preset("defaultValues", 
    [
        { name: "Char List", type: "Array", value: [] }
    ]
);

function execute(value:Array<Int>) {
    if (_note == null || value.length <= 0) { return; }
    Reflect.setProperty(_note, "singCharacters", value);
}