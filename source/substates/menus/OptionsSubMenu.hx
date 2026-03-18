package substates.menus;

import flixel.addons.ui.FlxUIGroup;
import objects.menu.MenuButton;
import objects.game.Alphabet;
import flixel.FlxG;
import haxe.Timer;

using utils.Files;
using StringTools;

class OptionsSubMenu extends SubMenu {
    public var options:Array<{display:String, method:Void->Void}> = [];
    public var description:Dynamic;

    public var lblDescription:Alphabet;
    public var gpOptions:FlxUIGroup;

    public var arrOptions(get, never):Array<MenuButton>;
    public function get_arrOptions():Array<MenuButton> {
        var toReturn:Array<MenuButton> = [];
        for (option in gpOptions.members) {
            if (!(option is MenuButton)) { continue; }
            var curButton:MenuButton = cast option;
            toReturn.push(curButton);
        }
        return toReturn;
    }

    public var curOption:Int = 0;
    
    public function new(description:Dynamic, options:Array<{display:String, method:Void->Void}>):Void {
        this.description = description;
        this.options = options;
        super(null, 400, 200);
    }

    override function create():Void {
        super.create();
        
        lblDescription = new Alphabet(0, 0, ((description is String)) ? ([{bold: true, animated: true, scale: 0.5, text: description}]) : (description));
        lblDescription.screenCenter(X);

        var curWidth:Float = 0;
        gpOptions = new FlxUIGroup();
        for (option in options) {
            var newButton:MenuButton = new MenuButton(curWidth, 0, Language.getText('opt_${option.display}'), 0.4, option.method);
            newButton.skipTransition = true;
            curWidth += newButton.width + 10;
            gpOptions.add(newButton);
        }

        group.add(lblDescription);
        group.add(gpOptions);

        backSprite.resize(Math.max(lblDescription.width + 60, gpOptions.width + 60), lblDescription.height + gpOptions.height + 100);
        backSprite.screenCenter();
        
        lblDescription.y = backSprite.y + 40;

        gpOptions.screenCenter(X);
        gpOptions.y = lblDescription.y + lblDescription.height + 30;

        changeOption(0, true);
    }

    override function update(elapsed:Float):Void {
        super.update(elapsed);

        if (!canControlle) { return; }

        if (controls.check("MenuLeft")) {changeOption(-1); }
        if (controls.check("MenuRight")) {changeOption(1); }
        if (controls.check("MenuAccept")) {chooseOption(); }
    }

    public function changeOption(_value:Int = 0, _force:Bool = false):Void {
        curOption = _force ? _value : curOption + _value;

        if (curOption < 0) {curOption = 1; }
        if (curOption > 1) {curOption = 0; }

        for (option in arrOptions) {option.disable(); }
        arrOptions[curOption].enable();

        if (!_force) {FlxG.sound.play(Paths.sound("scrollMenu").getSound(), 0.5); }
    }

    public function chooseOption():Void {
        canControlle = false;
        
        arrOptions[curOption].action();
        
        FlxG.sound.play(Paths.sound("confirmMenu").getSound(), 0.5);
        
        Timer.delay(()->{doClose(); }, 1000);
    }

    override function close():Void {
        super.close();
        
        arrOptions[curOption].click();
    }
}