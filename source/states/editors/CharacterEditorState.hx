package states.editors;

import objects.game.Character.Character_File;
import objects.game.Character.Animation_Data;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUIButton;
import objects.songs.Song.Song_File;
import objects.ui.UINumericStepper;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUIText;
import objects.ui.UITabContainer;
import openfl.net.FileReference;
import flixel.util.FlxArrayUtil;
import objects.ui.UIScrollList;
import objects.game.Character;
import openfl.utils.ByteArray;
import flixel.addons.ui.FlxUI;
import objects.ui.UIContainer;
import flixel.sound.FlxSound;
import flixel.group.FlxGroup;
import objects.ui.UICheckBox;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import objects.ui.UIButton;
import flixel.text.FlxText;
import objects.ui.UISlider;
import openfl.events.Event;
import lime.ui.FileDialog;
import objects.game.Stage;
import openfl.media.Sound;
import objects.ui.UIList;
import objects.game.Icon;
import objects.game.Icon;
import flixel.FlxSprite;
import flixel.FlxObject;
import haxe.xml.Access;
import flixel.FlxG;
import haxe.Json;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

class CharacterEditorState extends MusicBeatState {
    public static var character_data:Character_File;
    public static var curCharacter:String = "Boyfriend";
    public static var curAspect:String = "Default";

    var arrayFocus:Array<FlxUIInputText> = [];
    
    var ctnAnimationMenu:UITabContainer;
    var ctnScriptMenu:UITabContainer;
    var ctnGeneralMenu:UIContainer;
    function overlapsTabs():Bool {
        return 
            ctnScriptMenu.isOverlaping() ||
            ctnAnimationMenu.isOverlaping() ||
            FlxG.mouse.overlaps(ctnGeneralMenu)
        ;
    }

    var character:Character;
    var stage:Stage;
    var icon:Icon;
    
    var mousePointer:FlxPoint = FlxPoint.get(0, 0);
    var mouseState:Int = -1;

    function setMousePointer(_camPoint:Dynamic, _mousePoint:FlxPoint, _inverse:Bool, _state:Int):Void { 
        mousePointer.set(
            _inverse ? _mousePoint.x + _camPoint.x : _mousePoint.x - _camPoint.x, 
            _inverse ? _mousePoint.y + _camPoint.y : _mousePoint.y - _camPoint.y
        );
        mouseState = _state;
    }

    var camFollow:FlxObject;
    var camPoint:FlxSprite;
    var posPoint:FlxSprite;

    private var charPositions:Array<Dynamic> = [
        [100, 100],
        [540, 50],
        [770, 100]
    ];
	private var charPos(get, never):Array<Int>;
	inline function get_charPos():Array<Int> {
        if (chkGfPos.checked) { return charPositions[1]; }
        if (chkDadPos.checked) { return charPositions[0]; }
        return charPositions[2];
    }

    public function new(?onConfirm:String, ?onBack:String, ?data:Character_File):Void {
        if (data != null) { CharacterEditorState.character_data = data; }

        super(onConfirm, onBack);
    }

    override function create() {
        if (CharacterEditorState.character_data == null) { CharacterEditorState.character_data = new Character(0, 0, curCharacter, curAspect).data; }

        super.create();
        
        FlxG.sound.playMusic(Paths.music('break_song').getSound());        

        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);

        stage = new Stage(
            "Stage",
            [
                ["Girlfriend", [540, 50], 1, false, "Default", "GF", 0],
                ["Daddy_Dearest", [100, 100], 1, true, "Default", "NORMAL", 0],
                ["Boyfriend", [770, 100], 1, false, "Default", "NORMAL", 0],
                ["Boyfriend", [770, 100], 1, false, "Default", "NORMAL", 0]
            ]
        );
        stage.cameras = [camFGame];
        add(stage);

        for (char in stage.characterData) {char.alpha = 0.5; }
        
        character = stage.getCharacterById(3);
        character.curAspect = curAspect;
        character.setupByFile(character_data);
        character.onDebug = true;
        character.alpha = 1;

        ctnGeneralMenu = new UIContainer(0, 0, 300, Std.int(FlxG.height));
		ctnGeneralMenu.x = FlxG.width - ctnGeneralMenu.width;
        ctnGeneralMenu.camera = camHUD;
        addGeneralMenuStuff();
        add(ctnGeneralMenu);

        ctnScriptMenu = new UITabContainer(0, 70, 300, 170, 50, "Script", 20);
        ctnScriptMenu._bounds.x -= ctnGeneralMenu.width;
        ctnScriptMenu.camera = camHUD;
        addScriptMenuStuff();
        add(ctnScriptMenu);

        ctnAnimationMenu = new UITabContainer(0, ctnScriptMenu.y + ctnScriptMenu.height, 300, 440, 50, "Animations", 20);
        ctnAnimationMenu._bounds.x -= ctnGeneralMenu.width;
        ctnAnimationMenu.camera = camHUD;
        addAnimationMenuStuff();
        add(ctnAnimationMenu);

        icon = new Icon();
        icon.setIcon(character_data.icon);
        icon.scale.set(0.5, 0.5); icon.updateHitbox();
        icon.camera = camHUD;
        icon.x = 5;
        add(icon);

        camPoint = new FlxSprite().loadGraphic(Paths.image("editor_menu/resizecam")); 
        camPoint.scale.set(0.5, 0.5); camPoint.updateHitbox();
        camPoint.camera = camFGame;
        camPoint.alpha = 0.5;
        add(camPoint);

        posPoint = new FlxSprite().loadGraphic(Paths.image("editor_menu/positionchar")); 
        posPoint.scale.set(0.5, 0.5); posPoint.updateHitbox();
        posPoint.camera = camFGame;
        posPoint.alpha = 0.5;
        add(posPoint);

		camFollow = new FlxObject(character.characterSprite.getGraphicMidpoint().x, character.characterSprite.getGraphicMidpoint().y, 1, 1);
		add(camFollow);
        
        //camFGame.x -= Std.int(ctnGeneralMenu.width / 2);
        camFGame.follow(camFollow, LOCKON);

        reloadCharacter();

        #if desktop
		// Updating Discord Rich Presence
		Discord.change('[${character.curCharacter}-${curAspect}]', '[Character Editor]');
		Magic.setWindowTitle('Editing [${character.curCharacter}-${curAspect}]', 1);
		#end
        
        FlxG.mouse.visible = true;
    }

    override function update(elapsed:Float) {
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);

        var arrayControlle = true;
        for (item in arrayFocus) {if (item.hasFocus) {arrayControlle = false; }}

        if (canControlle && arrayControlle) {
            switch (mouseState) {
                case 0: { camFollow.setPosition(mousePointer.x - pMouse.x, mousePointer.y - pMouse.y); }
                case 1: {
                    var _charpos = character.getScreenPosition(null, camFGame);
                    character_data.camera = [pMouse.x - _charpos.x - mousePointer.x, pMouse.y - _charpos.y - mousePointer.y];
                }
                case 2: {
                    var _charpos = character.getScreenPosition(null, camFGame);
                    character_data.position = [pMouse.x - _charpos.x - mousePointer.x, pMouse.y - _charpos.y - mousePointer.y];
                    character.characterSprite.setPosition(character.x + character_data.position[0], character.y + character_data.position[1]);
                }
            }

            if (FlxG.mouse.justPressedMiddle) { camFollow.setPosition(character.characterSprite.getGraphicMidpoint().x, character.characterSprite.getGraphicMidpoint().y); }
            else if (FlxG.keys.justPressed.SPACE) { character.playAnim(clAnims.getSelectedLabel(), true); }
            else if (FlxG.keys.justPressed.Q) { clAnims.change(true); }
            else if (FlxG.keys.justPressed.E) { clAnims.change(); }

            camPoint.alpha = posPoint.alpha = 0.5;
            if (FlxG.mouse.overlaps(camPoint, camFGame)) { camPoint.alpha = 1; }
            else if (FlxG.mouse.overlaps(posPoint, camFGame)) { posPoint.alpha = 1; }

            if ((FlxG.mouse.releasedRight && mouseState == 0) || (FlxG.mouse.released && mouseState > 0)) {mouseState = -1; }
            else if (mouseState == -1 && !overlapsTabs()) {
                if (FlxG.mouse.justPressedRight) { setMousePointer(camFollow, pMouse, true, 0); }
                else if (FlxG.mouse.justPressed) {
                    if (FlxG.mouse.overlaps(camPoint, camFGame)) {
                        var midpoint = camPoint.getScreenPosition(null, camFGame);
                        midpoint.y += camPoint.height / 2;
                        midpoint.x += camPoint.width / 2;
                        setMousePointer(midpoint, pMouse, false, 1);
                    } else if (FlxG.mouse.overlaps(posPoint, camFGame)) {
                        var midpoint = posPoint.getScreenPosition(null, camFGame);
                        midpoint.y += posPoint.height / 2;
                        midpoint.x += posPoint.width / 2;
                        setMousePointer(midpoint, pMouse, false, 2);
                    }
                }
            }

            if (FlxG.keys.pressed.SHIFT) {
                if (FlxG.mouse.wheel != 0) {camFGame.zoom += (FlxG.mouse.wheel * 0.1); } 
                
                if (FlxG.keys.justPressed.W) {character_data.position[1] -= 5; reloadCharacter(); }
                if (FlxG.keys.justPressed.A) {character_data.position[0] -= 5; reloadCharacter(); }
                if (FlxG.keys.justPressed.S) {character_data.position[1] += 5; reloadCharacter(); }
                if (FlxG.keys.justPressed.D) {character_data.position[0] += 5; reloadCharacter(); }
                
                if (FlxG.keys.justPressed.I) {character_data.camera[1] -= 5; reloadCharacter(); }
                if (FlxG.keys.justPressed.J) {character_data.camera[0] -= 5; reloadCharacter(); }
                if (FlxG.keys.justPressed.K) {character_data.camera[1] += 5; reloadCharacter(); }
                if (FlxG.keys.justPressed.L) {character_data.camera[0] += 5; reloadCharacter(); }
            } else {
                if (FlxG.mouse.wheel != 0) {camFGame.zoom += (FlxG.mouse.wheel * 0.01); }
                
                if (FlxG.keys.justPressed.W) {character_data.position[1]--; reloadCharacter(); }
                if (FlxG.keys.justPressed.A) {character_data.position[0]--; reloadCharacter(); }
                if (FlxG.keys.justPressed.S) {character_data.position[1]++; reloadCharacter(); }
                if (FlxG.keys.justPressed.D) {character_data.position[0]++; reloadCharacter(); }
                
                if (FlxG.keys.justPressed.I) {character_data.camera[1]--; reloadCharacter(); }
                if (FlxG.keys.justPressed.J) {character_data.camera[0]--; reloadCharacter(); }
                if (FlxG.keys.justPressed.K) {character_data.camera[1]++; reloadCharacter(); }
                if (FlxG.keys.justPressed.L) {character_data.camera[0]++; reloadCharacter(); }
            }
        }
        
        super.update(elapsed);
    
        posPoint.setPosition(
            character.x + character_data.position[0] - (posPoint.width / 2),
            character.y + character_data.position[1] - (posPoint.height / 2)
        );
        camPoint.setPosition(
            character.x + character_data.camera[0] - (camPoint.width / 2),
            character.y + character_data.camera[1] - (camPoint.height / 2)
        );
    }

    public function reloadCharacter():Void {
        character.setupByFile(character_data);
        character.turnLook(chkDadPos.checked);
        character.setPosition(charPos[0], charPos[1]);
        character.playAnim(clAnims.getSelectedLabel(), true);
    }

    var txtCharacter:FlxUIInputText;
    var txtAspect:FlxUIInputText;
    var chkDadPos:FlxUICheckBox;
    var chkGfPos:FlxUICheckBox;
    var txtImage:FlxUIInputText;
    var txtIcon:FlxUIInputText;
    var txtDeath:FlxUIInputText;
    var chkFlip:FlxUICheckBox;
    var chkAntialiasing:FlxUICheckBox;
    var chkDance:FlxUICheckBox;
    private function addGeneralMenuStuff():Void {
        // < == [ Load Characters ] == > //
        var ttlCharacter = new FlxText(0, 5, ctnGeneralMenu.display_width, "< - Character - >", 20); ctnGeneralMenu.addPlus(ttlCharacter, 10);
        ttlCharacter.alignment = CENTER;

        var lblCharacter = new FlxText(0, 0, ctnGeneralMenu.display_width, "Character:", 12); ctnGeneralMenu.addPlus(lblCharacter, 0);
        txtCharacter = new FlxUIInputText(0, 0, ctnGeneralMenu.display_width, curCharacter, 16);
        txtCharacter.name = "CHARACTER_NAME"; arrayFocus.push(txtCharacter);
        ctnGeneralMenu.addPlus(txtCharacter, 10);
        
        var lblAspect = new FlxText(0, 0, ctnGeneralMenu.display_width, "Aspect:", 12); ctnGeneralMenu.addPlus(lblAspect, 0);
        txtAspect = new FlxUIInputText(0, 0, ctnGeneralMenu.display_width, curAspect, 16);
        txtAspect.name = "CHARACTER_ASPECT"; arrayFocus.push(txtAspect);
        ctnGeneralMenu.addPlus(txtAspect, 10);

        var btnLoad:FlxUIButton = new UIButton(0, 0, ctnGeneralMenu.display_width, null, "Load Character", 16, null, null, () -> {
            curCharacter = txtCharacter.text;
            curAspect = txtAspect.text;

            var newCharacter:Character = new Character(0, 0, txtCharacter.text, txtAspect.text);
            newCharacter.setupByFile();
            
            MusicBeatState.switchState("states.editors.CharacterEditorState", [null, "states.MainMenuState", newCharacter.data]);
        }); ctnGeneralMenu.addPlus(btnLoad);

        var btnSave:FlxUIButton = new UIButton(0, 0, ctnGeneralMenu.display_width, null, "Save Character", 16, null, null, () -> {
            saveCharacter('${txtCharacter.text}-${txtAspect.text}');
        }); ctnGeneralMenu.addPlus(btnSave, 10);

        // < == [ Characters Positions ] == > //
        var ttlPositions = new FlxText(0, 0, ctnGeneralMenu.display_width, "< - Positions - >", 20); ctnGeneralMenu.addPlus(ttlPositions, 10);
        ttlPositions.alignment = CENTER;

        chkDadPos = new UICheckBox(0, 0, ctnGeneralMenu.display_width, "Dad Position", 18); ctnGeneralMenu.addPlus(chkDadPos, 0);
        chkGfPos = new UICheckBox(0, 0, ctnGeneralMenu.display_width, "Girlfriend Position", 18); ctnGeneralMenu.addPlus(chkGfPos, 15);

        // < == [ Character Information ] == > //
        var ttlInformation = new FlxText(0, 0, ctnGeneralMenu.display_width, "< - Information - >", 20); ctnGeneralMenu.addPlus(ttlInformation, 10);
        ttlInformation.alignment = CENTER;
        
        var lblImage = new FlxText(0, 0, ctnGeneralMenu.display_width, "Image:", 12); ctnGeneralMenu.addPlus(lblImage, 0);
        txtImage = new FlxUIInputText(0, 0, ctnGeneralMenu.display_width, character_data.image, 16);
        txtImage.name = "CHARACTER_IMAGE"; arrayFocus.push(txtImage);
        ctnGeneralMenu.addPlus(txtImage, 10);
        
        var lblIcon = new FlxText(0, 0, ctnGeneralMenu.display_width, "Icon:", 12); ctnGeneralMenu.addPlus(lblIcon, 0);
        txtIcon = new FlxUIInputText(0, 0, ctnGeneralMenu.display_width, character_data.icon, 16);
        txtIcon.name = "CHARACTER_ICON"; arrayFocus.push(txtIcon);
        ctnGeneralMenu.addPlus(txtIcon, 10);
        
        var lblDeath = new FlxText(0, 0, ctnGeneralMenu.display_width, "Death Sound", 12); ctnGeneralMenu.addPlus(lblDeath, 0);
        txtDeath = new FlxUIInputText(0, 0, ctnGeneralMenu.display_width, character_data.death, 16);
        txtDeath.name = "CHARACTER_DEATH"; arrayFocus.push(txtDeath);
        ctnGeneralMenu.addPlus(txtDeath, 10);

        var lblScale = new FlxText(0, 0, ctnGeneralMenu.display_width, "Scale:", 12); ctnGeneralMenu.addPlus(lblScale, 0);
        var sldScale = new UISlider(10, 0, 12, ctnGeneralMenu.display_width - 20, 20, false, character_data, "scale", 0.1, 2);
        sldScale.callback = (_value) -> { reloadCharacter(); }
        ctnGeneralMenu.addPlus(sldScale);

        var lblSing = new FlxText(0, 0, ctnGeneralMenu.display_width, "Sing Duration:", 12); ctnGeneralMenu.addPlus(lblSing, 0);
        var sldSing = new UISlider(10, 0, 12, ctnGeneralMenu.display_width - 20, 20, false, character_data, "singTime", 0, 2);
        ctnGeneralMenu.addPlus(sldSing);
        
        chkFlip = new UICheckBox(0, 0, ctnGeneralMenu.display_width, "Flip Image", 18, character_data.onRight); ctnGeneralMenu.addPlus(chkFlip, 0);
        chkAntialiasing = new UICheckBox(0, 0, ctnGeneralMenu.display_width, "Antialiasing", 18, character_data.antialiasing); ctnGeneralMenu.addPlus(chkAntialiasing, 0);
        chkDance = new UICheckBox(0, 0, ctnGeneralMenu.display_width, "Beat Dance", 18, character_data.danceIdle); ctnGeneralMenu.addPlus(chkDance, 10);
    }
    
    var clAnims:UIList;
    var txtAnimName:FlxUIInputText;
    var txtAnimSymbol:FlxUIInputText;
    var txtAnimIndices:FlxUIInputText;
    var sldFramerate:UISlider;
    var sldSingAnim:UISlider;
    var chkAnimLoop:FlxUICheckBox;
    private function addAnimationMenuStuff():Void {   
        var ttlCurAnim = new FlxText(0, 5, ctnAnimationMenu.display_width, "< - Current Animation - >", 18); ctnAnimationMenu.addBody(ttlCurAnim, 10);
        ttlCurAnim.alignment = CENTER;

        var anims:Array<String> = [];
        for (anim in character_data.animations) {anims.push(anim.key); }
        clAnims = new UIList(0, 0, ctnAnimationMenu.display_width, 20, anims); ctnAnimationMenu.addBody(clAnims);
        clAnims.name = "CHARACTER_ANIMS";

        var btnAddAnim = new UIButton(0, 0, Std.int(ctnAnimationMenu.display_width / 3) - 10, null, "Add", 16, null, 0xff86ff82, () -> {
            var arrIndices:Array<Int> = [];
            try{arrIndices = Json.parse('{ "Anims": ${txtAnimIndices.text}}').Anims; txtAnimIndices.color = FlxColor.BLACK; }catch(e) {trace(e); txtAnimIndices.color = FlxColor.RED; }

            if (!clAnims.contains(txtAnimName.text) && txtAnimName.text.length > 0) {
                var nCharAnim:Animation_Data = {
                    key: txtAnimName.text,
                    symbol: txtAnimSymbol.text,
                    fps: Std.int(sldFramerate.value),
                    indices: arrIndices,
                    loop: chkAnimLoop.checked,
                    loopTime: Std.int(sldSingAnim.value)
                }

                character_data.animations.push(nCharAnim);
                
                var anims:Array<String> = []; for (anim in character_data.animations) {anims.push(anim.key); }
                clAnims.setData(anims);
                clAnims.updateIndex();
            }          

            reloadCharacter();
        }); ctnAnimationMenu.addBody(btnAddAnim, 0, false);

        var btnUptAnim = new UIButton(btnAddAnim.width + 5, 0, Std.int(ctnAnimationMenu.display_width / 3), null, "Update", 16, null, 0xff8a82ff, () -> {
            var arrIndices:Array<Int> = [];
            try{arrIndices = Json.parse('{ "Anims": ${txtAnimIndices.text}}').Anims; txtAnimIndices.color = FlxColor.BLACK; }catch(e) {trace(e); txtAnimIndices.color = FlxColor.RED; }

            for (anim in character_data.animations) {
                if (anim.key == clAnims.getSelectedLabel()) {
                    anim.key = txtAnimName.text;
                    anim.symbol = txtAnimSymbol.text;
                    anim.fps = Std.int(sldFramerate.value);
                    anim.indices = arrIndices;
                    anim.loopTime = Std.int(sldSingAnim.value);
                    anim.loop = chkAnimLoop.checked;
                    break;
                }
            }
            
            var anims:Array<String> = []; for (anim in character_data.animations) {anims.push(anim.key); }
            clAnims.setData(anims);

            reloadCharacter();
        }); ctnAnimationMenu.addBody(btnUptAnim, 0, false);

        var btnDelAnim = new UIButton(btnAddAnim.width + btnUptAnim.width + 10, 0, Std.int(ctnAnimationMenu.display_width / 3), null, "Delete", 16, null, 0xffff8282, () -> {
            if (!clAnims.contains(txtAnimName.text)) { return; }
            for (anim in character_data.animations) {
                if (anim.key != txtAnimName.text) { continue; }
                character_data.animations.remove(anim); break;
            }
            
            var anims:Array<String> = []; for (anim in character_data.animations) {anims.push(anim.key); }
            clAnims.setData(anims);
            clAnims.updateIndex();

            reloadCharacter();
        }); ctnAnimationMenu.addBody(btnDelAnim, 10);

        var lblAnimName = new FlxText(0, 0, ctnAnimationMenu.display_width, "Animation Name:", 12); ctnAnimationMenu.addBody(lblAnimName, 0);
        txtAnimName = new FlxUIInputText(0, 0, ctnAnimationMenu.display_width, "", 16);
        txtAnimName.name = "ANIMATION_NAME"; arrayFocus.push(txtAnimName);
        ctnAnimationMenu.addBody(txtAnimName);

        var lblAnimSymbol = new FlxText(0, 0, ctnAnimationMenu.display_width, "Animation Symbol:", 12); ctnAnimationMenu.addBody(lblAnimSymbol, 0);
        txtAnimSymbol = new FlxUIInputText(0, 0, ctnAnimationMenu.display_width, "", 16);
        txtAnimSymbol.name = "ANIMATION_SYMBOL"; arrayFocus.push(txtAnimSymbol);
        ctnAnimationMenu.addBody(txtAnimSymbol);

        var lblAnimIndices = new FlxText(0, 0, ctnAnimationMenu.display_width, "Animation Indices:", 12); ctnAnimationMenu.addBody(lblAnimIndices, 0);
        txtAnimIndices = new FlxUIInputText(0, 0, ctnAnimationMenu.display_width, "[]", 16);
        txtAnimIndices.name = "ANIMATION_INDICES"; arrayFocus.push(txtAnimIndices);
        ctnAnimationMenu.addBody(txtAnimIndices, 10);

        var lblFramerate = new FlxText(0, 0, ctnAnimationMenu.display_width, "Framerate:", 12); ctnAnimationMenu.addBody(lblFramerate, 0);
        sldFramerate = new UISlider(10, 0, 12, ctnAnimationMenu.display_width - 20, 20, false, null, null, 1, 120);
        ctnAnimationMenu.addBody(sldFramerate);

        var lblSingAnim = new FlxText(0, 0, ctnAnimationMenu.display_width, "Sing Animation:", 12); ctnAnimationMenu.addBody(lblSingAnim, 0);
        sldSingAnim = new UISlider(10, 0, 12, ctnAnimationMenu.display_width - 20, 20, false, null, null, 0, 10);
        ctnAnimationMenu.addBody(sldSingAnim);
        
        chkAnimLoop = new UICheckBox(0, 0, ctnAnimationMenu.display_width, "Animation Loop", 18, false); ctnAnimationMenu.addBody(chkAnimLoop, 10);

        var btnImportAnims = new UIButton(0, 0, ctnAnimationMenu.display_width, null, "Import Animations", 16, null, null, () -> {
            var character_path:String = Paths.image('characters/${character_data.name}/${character_data.image}').replace('.png', '.xml');
            if (!Paths.exists(character_path)) { return; }
            var animSymbols:Array<String> = character_path.getXMLAnimations();

            character_data.animations = [];
            for (symbol in animSymbols) {
                var nCharAnim:Animation_Data = {
                    key: symbol,
                    symbol: symbol,
                    
                    fps: 24,    
                    indices: [],
                    loopTime: 0,

                    loop: false
                }

                character_data.animations.push(nCharAnim);
            }
            
            reloadCharacter();
            clAnims.setData(animSymbols);
        }); ctnAnimationMenu.addBody(btnImportAnims, 10);
    }

    var txtScript:FlxUIInputText;
    var txtFunction:FlxUIInputText;
    private function addScriptMenuStuff():Void {
        var lblScript = new FlxText(0, 5, ctnScriptMenu.display_width, "Script File:", 12); ctnScriptMenu.addBody(lblScript, 0);
        txtScript = new FlxUIInputText(0, 5, ctnScriptMenu.display_width, character_data.script, 16);
        txtScript.name = "CHARACTER_SCRIPT"; arrayFocus.push(txtScript);
        ctnScriptMenu.addBody(txtScript, 10);

        var lblFunction = new FlxText(0, 0, ctnScriptMenu.display_width, "Function Name:", 12); ctnScriptMenu.addBody(lblFunction, 0);
        txtFunction = new FlxUIInputText(0, 0, ctnScriptMenu.display_width, "", 16);
        txtFunction.name = "SCRIPT_FUNCTION"; arrayFocus.push(txtFunction);
        ctnScriptMenu.addBody(txtFunction, 10);

        var btnFunction = new UIButton(0, 0, ctnScriptMenu.display_width, null, "Execute Function", 16, null, null, () -> {
            if (character.script == null) { return; }
            character.script.call(txtFunction.text);
        }); ctnScriptMenu.addBody(btnFunction);
    }
    
    override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>) {
        if (id == FlxUICheckBox.CLICK_EVENT) {
            var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;

			switch (label) {
                case "Antialiasing":{character_data.antialiasing = check.checked; reloadCharacter(); }
                case "Beat Dance":{character_data.danceIdle = check.checked; reloadCharacter(); }
                case "Flip Image":{character_data.onRight = check.checked; reloadCharacter(); }
                case "Dad Position", "Girlfriend Position":{reloadCharacter(); }
                default:{trace('$label WORKS!'); }
			}
		} else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText)) {
            var input:FlxUIInputText = cast sender;
            var wname = input.name;

            switch (wname) {
                default:{trace('$wname WORKS!'); }
                case "CHARACTER_ICON":{ character_data.icon = input.text; icon.setIcon(character_data.icon); }
                case "CHARACTER_SCRIPT":{ character_data.script = input.text; reloadCharacter(); }
                case "CHARACTER_IMAGE":{ character_data.image = input.text; reloadCharacter(); }
                case "CHARACTER_NAME":{ character_data.name = input.text; reloadCharacter(); }
                case "CHARACTER_DEATH": { character_data.death = input.text; }
            }
        } else if (id == FlxUIDropDownMenu.CLICK_EVENT && (sender is FlxUIDropDownMenu)) {
            var drop:FlxUIDropDownMenu = cast sender;
            var wname = drop.name;

            switch (wname) {
                default:{trace('$wname WORKS!'); }
            }
        } else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper)) {
            var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;

            switch (wname) {
                default:{trace('$wname WORKS!'); }
                case "CHARACTER_X":{character_data.position[0] = nums.value; reloadCharacter(); }
                case "CHARACTER_Y":{character_data.position[1] = nums.value; reloadCharacter(); }
                case "CHARACTER_SingDuration":{character_data.singTime = nums.value; }
                case "CHARACTER_CameraX":{character_data.camera[0] = nums.value; }
                case "CHARACTER_CameraY":{character_data.camera[1] = nums.value; }
            }
        } else if (id == UIList.CHANGE_EVENT && (sender is UIList)) {
            var list:UIList = cast sender;
			var wname = list.name;

            switch (wname) {
                default:{trace('$wname WORKS!'); }
                case "CHARACTER_ANIMS":{
                    var curAnim = character_data.animations[list.getSelectedIndex()];
                    if (curAnim != null) {
                        character.playAnim(curAnim.key, true);
                        txtAnimSymbol.text = curAnim.symbol;
                        txtAnimName.text = curAnim.key;
                        if (curAnim.indices != null && curAnim.indices.length > 0) {txtAnimIndices.text = curAnim.indices.toString(); } else {txtAnimIndices.text = "[]"; }
                        sldSingAnim.value = curAnim.loopTime;
                        chkAnimLoop.checked = curAnim.loop;
                        sldSingAnim.varString = "loopTime";
                        sldFramerate.value = curAnim.fps;
                        sldFramerate._object = curAnim;
                        sldFramerate.varString = "fps";
                        sldSingAnim._object = curAnim;
                    } else {
                        txtAnimName.text = "";
                        sldSingAnim.value = 1;
                        txtAnimSymbol.text = "";
                        sldFramerate.value = 30;
                        txtAnimIndices.text = "[]";
                        sldSingAnim._object = null;
                        chkAnimLoop.checked = false;
                        sldFramerate._object = null;
                        sldSingAnim.varString = null;
                        sldFramerate.varString = null;
                    }
                }
            }
        }
    }

    override function destroy():Void {
        FlxG.sound.music.stop();
        super.destroy();
    }

    private function getFile(_file:FlxUIInputText):Void {
        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str) {_file.text = str; });
        fDialog.browse();
	}

    var _file:FileReference;
    function saveCharacter(name:String) {
        var cur_save:String = Json.stringify(character_data, "\t");
    
        if ((cur_save != null) && (cur_save.length > 0)) {
            _file = new FileReference();
            _file.addEventListener(Event.COMPLETE, onSaveComplete);
            _file.addEventListener(Event.CANCEL, onSaveCancel);
            _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
            _file.save(cur_save, '${name}.json');
        }
    }

    function onSaveComplete(_):Void {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.notice("Successfully saved CHARACTER.");
    }
        
    function onSaveCancel(_):Void {
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
    }

    function onSaveError(_):Void{
        _file.removeEventListener(Event.COMPLETE, onSaveComplete);
        _file.removeEventListener(Event.CANCEL, onSaveCancel);
        _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
        _file = null;
        FlxG.log.error("Problem saving Character character_data");
    }
}