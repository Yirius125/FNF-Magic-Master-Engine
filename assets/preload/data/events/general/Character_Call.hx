import objects.game.Character;

preset("defaultValues", [
    { name: "Id", type: "Int", value: 0 },
    { name: "Function", type: "String", value: "" },
    { name: "Arguments", type: "Array", value: [] }
]);

function execute(_id:Int, _func:String, _args:Array<Dynamic>):Void {
    if (getState().stage == null) { return; }
    
    var l_character:Character = getState().stage.getCharacterById(_id);
    if (l_character == null) { return; }

    l_character.script.call(_func, _args);
}