import objects.game.Character;

preset("defaultValues", [
    { name: "Id", type: "Int", value: 0 },
    { name: "X", type: "Int", value: 0 },
    { name: "Y", type: "Int", value: 0 }
]);

function execute(_id:Int, _x:Int, _y:Int):Void {
    var l_character:Character = getState().stage.getCharacterById(_id);

    l_character.setPosition(_x, _y);
}