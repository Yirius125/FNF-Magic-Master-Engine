import flixel.FlxG;

preset("defaultValues", [
    { name: "Id", type: "Int", value: 0 },
    { name: "Name", type: "String", value: "hey" },
    { name: "Force", type: "Bool", value: false },
    { name: "Special", type: "Bool", value: false },
    { name: "Type", type: "List", value: 0 , list: ["Normal", "Sing", "Emote"] },
]);

function execute(_id:Int, _name:String, _force:Bool, _special:Bool, _type:String):Void {
    if (getState().stage == null) { return; }
    
    var l_chrCurrent:Character = getState().stage.getCharacterById(_id);
    if (l_chrCurrent == null) { return; }
    
    if (_type == "Emote") { l_chrCurrent.emoteAnim(_name, _force, _special); }
    else if (_type == "Sing") { l_chrCurrent.singAnim(_name, _force, _special); }
    else { l_chrCurrent.playAnim(_name, _force, _special); }
}