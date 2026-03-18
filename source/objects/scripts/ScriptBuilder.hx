package objects.scripts;

using StringTools;
using utils.Files;
using utils.Paths;

typedef File_Object = {
    var name:String;
    var unique:Bool;
    var attribute:Bool;
    var create_object:Bool;
    var imports:Array<String>;
    var sources:Array<{source:String, type:String}>;
    var variables:Array<{name:String, type:String, placeholder:Dynamic, ?args:Array<Dynamic>}>;
}

typedef Script_Object = {
    var name:String;
    var object:String;
    var variables:Dynamic;
    var attributes:Array<Script_Object>;
}

class ScriptBuilder {
    public static var files(default, null):Map<String, File_Object> = [];
    public static function getFile(_file:String, ?_att:String):File_Object {
        if (files.exists(_att != null ? _att : _file)) { return files[_att != null ? _att : _file]; }
        
        var _file_path:String = Paths.json('stage_objects/${_file}/${_att != null ? _att : _file}');
        if (!_file_path.exists()) { return null; }
        files.set(_att != null ? _att : _file, cast _file_path.getJson());

        return files[_att != null ? _att : _file];
    }

    public var members:Array<Script_Object> = [];
    public var presets(default, null):Dynamic = {};

    public static function load(_file:String, ?_att:String):File_Object {
        var _file_object:File_Object = files.exists(_att != null ? _att : _file) ? files[_att != null ? _att : _file] : null;
        if (_file_object != null) { return _file_object; }

        var _file_path:String = Paths.json('stage_objects/${_file}/${_att != null ? _att : _file}');

        if (!_file_path.exists()) { return null; }

        files.set(_att != null ? _att : _file, _file_object = cast _file_path.getJson());

        return _file_object;
    }
    public static function addAttribute(_object:Script_Object, _file:String):Script_Object {
        var _file_object:File_Object = load(_object.object, _file);
        if (_file_object == null) { return null; }
        
        if (_file_object.unique) {
            for (_att in _object.attributes) {
                if (_att.object != _file) { continue; }
                return null;
            }
        }

        var _obj:Script_Object = cast {name: 'attribute_${_object.attributes.length}', object: _file, variables: {}, attributes: []};
        for (_var in _file_object.variables) {Reflect.setProperty(_obj.variables, _var.name, _var.placeholder); }
        _object.attributes.push(_obj);
        return _obj;
    }

    public function new():Void {

    }

    public function _add(_object:Script_Object):Void {
        var _file_object:File_Object = load(_object.object);
        if (_file_object == null) { return; }

        members.push(_object);
    }
    public function add(_file:String):Void {
        var _file_object:File_Object = load(_file);
        if (_file_object == null) { return; }

        var _obj:Script_Object = cast {name: 'object_${members.length}', object: _file, variables: {}, attributes: []};
        for (_var in _file_object.variables) {Reflect.setProperty(_obj.variables, _var.name, _var.placeholder); }
        members.push(_obj);
    }

    public function set(_name:String, _value:Dynamic):Void {
        Reflect.setProperty(presets, _name, _value);
    }

    public function last():Script_Object { return members[members.length - 1]; }

    public function build():String {
        var _imports:Array<String> = [];
        var _initial_source:String = "";
        var _create_source:String = "";
        var _update_source:String = "";
        var _cache_source:String = "";
        var _beat_source:String = "";

        for (_obj in members) {
            var _cur_file:File_Object = files[_obj.object];
            var _cur_source_initial:String = "";
            var _cur_source_create:String = "";
            var _cur_source_update:String = "";
            var _cur_source_cache:String = "";
            var _cur_source_beat:String = "";

            var replace_source = (_rep:String, _to:String) -> {
                _cur_source_initial = _cur_source_initial.replace("${"+_rep+"}", _to);
                _cur_source_create = _cur_source_create.replace("${"+_rep+"}", _to);
                _cur_source_update = _cur_source_update.replace("${"+_rep+"}", _to);
                _cur_source_cache = _cur_source_cache.replace("${"+_rep+"}", _to);
                _cur_source_beat = _cur_source_beat.replace("${"+_rep+"}", _to);
            };

            for (_imp in _cur_file.imports) {
                if (!_imports.contains(_imp)) {_imports.push(_imp); }
                for (_att in _obj.attributes) {
                    var _cur_att_file:File_Object = files[_att.object];
                    for (__imp in _cur_att_file.imports) {
                        if (!_imports.contains(__imp)) {_imports.push(__imp); }
                    }
                }
            }
            
            for (_src in _cur_file.sources) {
                switch (_src.type) {
                    case "initial": {_cur_source_initial = _src.source; }
                    case "pre-create": {_cur_source_create = _src.source + "\n"; }
                }
            }
            for (_att in _obj.attributes) {
                var _cur_att_file:File_Object = files[_att.object];
            
                for (_src in _cur_att_file.sources) {
                    switch (_src.type) {
                        case "cache": {_cur_source_cache += _src.source + "\n"; }
                        case "create": {_cur_source_create += _src.source + "\n"; }
                    }
                }
            }

            for (_src in _cur_file.sources) {
                switch (_src.type) {
                    case "post-create": {_cur_source_create += _src.source + "\n"; }
                    case "update": {_cur_source_update += _src.source + "\n"; }
                    case "beat": {_cur_source_beat += _src.source + "\n"; }
                }
            }
            for (_att in _obj.attributes) {
                var _cur_att_file:File_Object = files[_att.object];
            
                for (_src in _cur_att_file.sources) {
                    switch (_src.type) {
                        case "update": {_cur_source_update += _src.source + "\n"; }
                        case "beat": {_cur_source_beat += _src.source + "\n"; }
                    }
                }
            }

            replace_source("name", _obj.name);
            for (_variable in Reflect.fields(_obj.variables)) {replace_source(_variable, Reflect.getProperty(_obj.variables, _variable)); }
            for (_att in _obj.attributes) {for (_variable in Reflect.fields(_att.variables)) {replace_source(_variable, Reflect.getProperty(_att.variables, _variable)); }}

            _initial_source += _cur_source_initial + "\n";
            _create_source += _cur_source_create + "\n";
            _update_source += _cur_source_update + "\n";
            _cache_source += _cur_source_cache + "\n";
            _beat_source += _cur_source_beat + "\n";
        }
        
        _create_source += "setGlobal();\n";

        var _result_source:String = "";
        for (_imp in _imports) {_result_source += 'import ${_imp};\n'; }
        _result_source += "\n";
        for (_preset in Reflect.fields(presets)) {_result_source += 'preset("${_preset}", ${Reflect.getProperty(presets, _preset)});\n'; }
        _result_source += "\n";
        _result_source += _initial_source;
        _result_source += "\n";
        _result_source += "function cache(list:Array<Dynamic>):Void {\n";
        _result_source += _cache_source;
        _result_source += "}";
        _result_source += "\n\n";
        _result_source += "function create():Void {\n";
        _result_source += _create_source;
        _result_source += "}";
        _result_source += "\n\n";
        _result_source += "function update(elapsed:Float):Void {\n";
        _result_source += _update_source;
        _result_source += "}";
        _result_source += "\n\n";
        _result_source += "function beatHit(curBeat:Int):Void {\n";
        _result_source += _beat_source;
        _result_source += "}";

        return _result_source;
    }
}