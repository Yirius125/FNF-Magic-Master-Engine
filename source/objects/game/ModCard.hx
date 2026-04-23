package objects.game;

import flixel.addons.ui.FlxUITabMenu;
import objects.menu.MenuButton;
import flixel.addons.ui.FlxUI;
import objects.utils.Controls;
import objects.scripts.Script;
import objects.utils.Mod;
import flixel.FlxSprite;
import flixel.FlxG;
import haxe.Timer;

using utils.Files;
using StringTools;

class ModCard extends FlxUITabMenu {
    public var script:Script;
    public var mod:Mod;

    public var id(get, never):Int;
    public function get_id():Int { return Mods.list.indexOf(mod); }

    public var callbacks:Map<String, Void->Void> = [];

    public var enableUI:FlxUI;
    public var disableUI:FlxUI;
    public var normalUI:FlxUI;

    public var backMove:FlxSprite;
    public var optLeft:MenuButton;
    public var optRight:MenuButton;

    public var backOptions:FlxSprite;
    public var optEnable:MenuButton;

    public var options:Array<MenuButton> = [];
    public var curOption:Int = 3;

    public var controls:Controls = Players.get(0).controls;
    public var canControlle:Bool = false;

    public function new(x:Float = 0, y:Float = 0, width:Float = 100, height:Float = 100, mod:Mod) {
        this.mod = mod;
        super(Magic.sliceRect(0, 0, 100, 100, Paths.image("menu_card", null, mod.name)), null, []);
        this.x = x;
        this.y = y;
        this.resize(width, height);

        script = new Script();
        script.parent = this;
        script.force('${mod.path}/scripts/Card.hx', true);

        enableUI = new FlxUI(null, this);
        enableUI.name = "enable";
        this.addGroup(enableUI);

        disableUI = new FlxUI(null, this);
        disableUI.name = "disable";
        this.addGroup(disableUI);
        
        normalUI = new FlxUI(null, this);
        normalUI.name = "normal";
        this.addGroup(normalUI);

        script.call("preCreate");

        optLeft = new MenuButton(0, 0, "<", 0.3, ()->{
            if (!canControlle) { return; }
            canControlle = false;

            var curInsert:Int = Mods.list.indexOf(mod) - 1;

            Mods.list.remove(mod);
            if (curInsert < 0) {curInsert = Mods.list.length; }
            Mods.list.insert(curInsert, mod);
            if (callbacks.exists("onLeft")) {callbacks.get("onLeft")(); }

            Timer.delay(()->{canControlle = true; }, 100);
        }, {enableColor: 0xff525252});
        optLeft.callAfterTransition = false;
        optRight = new MenuButton(0, 0, ">", 0.3, ()->{
            if (!canControlle) { return; }
            canControlle = false;

            var curInsert:Int = Mods.list.indexOf(mod) + 1;

            Mods.list.remove(mod);
            if (curInsert > Mods.list.length) {curInsert = 0; }
            Mods.list.insert(curInsert, mod);
            if (callbacks.exists("onRight")) {callbacks.get("onRight")(); }

            Timer.delay(()->{canControlle = true; }, 100);
        }, {enableColor: 0xff525252});
        optRight.callAfterTransition = false;
        backMove = Magic.roundRect(0, 0, Std.int(optLeft.width + optRight.width) + 30, Std.int(Math.max(optLeft.height, optRight.height)) + 20, 15, 15, 0x38000000);

        backMove.setPosition(30, this.height - backMove.height - 30);
        optLeft.setPosition(backMove.x + 10, backMove.y + 10);
        optRight.setPosition(optLeft.x + optLeft.width + 10, backMove.y + 10);

        normalUI.add(backMove);
        normalUI.add(optLeft);
        normalUI.add(optRight);

        optEnable = new MenuButton(0, 0, "!", 0.3, ()->{
            mod.enabled = !mod.enabled;
            optEnable.enableColor = mod.enabled ? 0xff61c54d : 0xffc54d4d;
            optEnable.back.color = optEnable.enableColor;
        }, {enableColor: mod.enabled ? 0xff61c54d : 0xffc54d4d});
        optEnable.callAfterTransition = false;
        backOptions = Magic.roundRect(0, 0, Std.int(optEnable.width) + 20, Std.int(optEnable.height) + 20, 15, 15, 0x38000000);

        backOptions.setPosition(this.width - backOptions.width - 30, this.height - backOptions.height - 30);
        optEnable.setPosition(backOptions.x + 10, backOptions.y + 10);

        normalUI.add(backOptions);
        normalUI.add(optEnable);

        options = [optLeft, optRight, optEnable];
        curOption = 2;
        
        script.call("postCreate");
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        if (canControlle) {
            switch (_selected_tab_id) {
                case "normal":{
                    if (controls.check("MenuBack")) {if (callbacks.exists("disable")) {callbacks.get("disable")(); }}
                    else if (controls.check("MenuLeft")) {changeOption(-1); }
                    else if (controls.check("MenuRight")) {changeOption(1); }
                    else if (controls.check("MenuAccept")) {chooseOption(); }
                }
            }
        }
        
        script.call("update");
    }

    public function changeOption(_value:Int = 0, _force:Bool = false):Void {
        curOption = _force ? _value : curOption + _value;

        if (curOption < 0) {curOption = options.length - 1; }
        if (curOption >= options.length) {curOption = 0; }

        for (opt in options) {opt.disable(); }
        options[curOption].enable();

        if (!_force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound(), 0.5); }
    }
    public function chooseOption():Void {
        options[curOption].click();
    }

    override public function showTabId(name:String):Void {
        if (name == "hidden") {name = mod.enabled ? "enable" : "disable"; }
        super.showTabId(name);

        var i:Int = 0;
		for (group in _tab_groups) {
            if (group.name == name) {
				_selected_tab_id = name;
				_selected_tab = i;
                break;
            }
            i++;
        }
    }
}