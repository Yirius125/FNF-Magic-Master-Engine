package substates;

import objects.scripts.Script;

class CustomScriptSubState extends MusicBeatSubstate {
    public var custom_script:Script;

    public function new(new_script:Script, onClose:Void->Void = null):Void {
        custom_script = new_script;
        custom_script.parent = this;
        super(onClose);
        
        scripts.set(custom_script.name, custom_script);
    }
}
