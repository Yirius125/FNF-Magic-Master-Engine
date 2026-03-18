package objects.scripts;

import objects.scripts.Script.Script_Calls;
import objects.scripts.Script;
import utils.Scripts;
import utils.Mods;

class ScriptList {
    public var call_globals:Bool = true;

    public var m_piorityList:Array<String> = [];
    public var m_localList:Map<String, Script> = [];
    
    public var d_list(get, default):Array<{name:String, script:Script}> = [];
    public function get_d_list():Array<{name:String, script:Script}> {
        var l_scriptList:Array<{name:String, script:Script}> = [];

        if (call_globals) { for (l_key => l_script in Scripts.global_scripts) { l_scriptList.push({name: l_key, script: l_script}); } }
        for (l_key => l_script in this.m_localList) { l_scriptList.push({name: l_key, script: l_script}); }

        l_scriptList.sort((_a, _b) -> {
            var l_priorityA:Bool = m_piorityList.indexOf(_a.name) != -1;
            var l_priorityB:Bool = m_piorityList.indexOf(_b.name) != -1;

            if (l_priorityA && !l_priorityB) { return -1; }
            if (!l_priorityA && l_priorityB) { return -1; }

            return 0;
        });

        return l_scriptList;
    }
    
    public function new(?_scripts:Map<String, Script>):Void {
        if (_scripts != null) { this.m_localList = _scripts; }
    }

    public function get(_key:String):Script {
        if (call_globals && Scripts.contains(_key)) { return Scripts.get(_key); }
        return m_localList.get(_key);
    }

	public function set(_key:String, _script:Script):Void {
        if (call_globals && Scripts.contains(_key)) { return; }
		if (m_localList.exists(_key)) { return; }
        
        m_localList.set(_key, _script);
	}
	public function remove(_key:String):Void {
		m_localList.remove(_key);
	}

    public function load(_key:String, _file:String):Void {
        if (m_localList.exists(_key)) { return; }

        var l_scpNew = new Script();
        l_scpNew.load(_file, true);
        l_scpNew.name = _key;
        
        if (l_scpNew.program == null) { return; }
        
        m_localList.set(_key, l_scpNew);
    }

    public function setVar(_name:String, _value:Dynamic) {
		for (l_scpCurrent in d_list) { l_scpCurrent.script.interp.variables.set(_name, _value); }
    }

	public function call(_name:String, _arguments:Array<Dynamic> = null):Void {
		if (_arguments == null) { _arguments = []; }
        
		for (l_scpCurrent in d_list) { l_scpCurrent.script.call(_name, _arguments); }
	}

    public function callback(_name:String, _arguments:Array<Dynamic> = null):Script_Calls {
		if (_arguments == null) { _arguments = []; }

        var l_toReturn:Script_Calls = Continue;

		for (l_scpCurrent in d_list) {
            var l_tempResult:Dynamic = l_scpCurrent.script.call(_name, _arguments);
            if (l_tempResult == null) { continue; }

            try {
                var l_tempCallback:Script_Calls = cast(l_tempResult, Script_Calls);
                if (l_tempCallback == Stop_And_Break) { return Stop; }
                if (l_tempCallback == Break) { return Break; }
                if (l_toReturn == Stop) { continue; }

                l_toReturn = l_tempCallback;
            } catch(e) { }
        }

        return l_toReturn;
    }

    public function complex(_name:String, _arguments:Array<Dynamic> = null, _endMethod:Void->Void):Void {
		if (_arguments == null) { _arguments = []; }

        var l_methods:Array<(Void -> Void) -> Void> = [];
		for (l_scpCurrent in d_list) {
            l_methods.push((_next:(Void -> Void)) -> { 
                var l_newArguments:Array<Dynamic> = _arguments.copy();
                l_newArguments.push(_next);

                if (l_scpCurrent.script.getVar(_name) == null) { _next(); }
                else { l_scpCurrent.script.call(_name, l_newArguments); }
            });
        }

        var l_indexScript:Int = 0;

        function doNext():Void {
            if (l_indexScript >= l_methods.length) { _endMethod(); } else {
                var l_curMethod:(Void -> Void) -> Void = l_methods[l_indexScript];
                l_indexScript++;

                l_curMethod(doNext);
            }
        }

        doNext();
    }
}