import objects.game.Character;

preset("defaultValues", [
    { name: "Id", type: "Int", value: 0 },
    { name: "Name", type: "String", value: "Boyfriend" },
    { name: "Category", type: "String", value: "Default" },
    { name: "Type", type: "String", value: "Default" }
]);

// Variables
var l_cacheList:Array<Dynamic> = [];
var l_characterMap:Map<String, Character> = [];

function cache_event(_list:Array<Dynamic>, _id:Int, _name:String, _aspect:String, _type:String):Void {
    Character.cache(_list, _name, _aspect, _type != "Default" ? _type : null, false);
    l_cacheList.push({ id: _id, name: _name, aspect: _aspect, type: _type });
}

function preload():Void {
    for (l_chrCurrent in getState().stage.characterData) {
        var l_keyCharacter:String = getCharacterKey(l_chrCurrent.ID, l_chrCurrent.curCharacter, l_chrCurrent.curAspect, l_chrCurrent.curType);
        l_characterMap.set(l_keyCharacter, l_chrCurrent);
    }

    for (l_curCharacter in l_cacheList) {
        var l_keyCharacter:String = getCharacterKey(l_curCharacter.id, l_curCharacter.name, l_curCharacter.aspect, l_curCharacter.type);
        if (l_characterMap.exists(l_keyCharacter)) { continue; }

        var l_chrNew:Character = new Character(0, 0, l_curCharacter.name, l_curCharacter.aspect, l_curCharacter.type == "Default" ? null : l_curCharacter.type);
        l_characterMap.set(l_keyCharacter, l_chrNew);
    }
}

function execute(_id:Int, _name:String, _aspect:String, _type:String):Void {
    if (getState().stage == null) { return; }
    
    var l_keyCharacter:String = getCharacterKey(_id, _name, _aspect, _type);
    if (!l_characterMap.exists(l_keyCharacter)) { return; }

    var l_chrCurrent:Character = getState().stage.getCharacterById(_id);
    if (l_chrCurrent == null) { return; }

    var l_characterIndex:Int = getState().stage.members.indexOf(l_chrCurrent);
    if (l_characterIndex < 0) { return; }

    var l_chrChange:Character = l_characterMap.get(l_keyCharacter);
    l_chrChange.scrollFactor.set(l_chrCurrent.scrollFactor.x, l_chrCurrent.scrollFactor.y);
    l_chrChange.setPosition(l_chrCurrent.x, l_chrCurrent.y);
    l_chrChange.scaleCharacter(l_chrCurrent.curScale);
    l_chrChange.turnLook(l_chrCurrent.onRight); 

    getState().stage.members[l_characterIndex] = getState().stage.characterData[_id] = l_chrChange;
}

function getCharacterKey(_id:Int, _name:String, _aspect:String, _type:String):String { return _id + "_" + _name + "_" + _aspect + "_" + (_type == null ? "Default" : _type); }