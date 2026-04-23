package states.editors;

import objects.scripts.ScriptBuilder.Script_Object;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxUIInputText;
import objects.scripts.ScriptBuilder;
import flixel.addons.ui.FlxUIButton;
import objects.ui.UIScrollList;
import objects.utils.SaverFile;
import objects.game.Character;
import flixel.tweens.FlxTween;
import objects.ui.UIContainer;
import objects.ui.UIInputText;
import objects.ui.UICheckBox;
import flixel.tweens.FlxEase;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import objects.ui.UIButton;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.math.FlxMath;
import objects.ui.UISlider;
import lime.ui.FileDialog;
import objects.game.Stage;
import openfl.media.Sound;
import objects.game.Icon;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxG;
import haxe.Json;

#if desktop
import utils.Discord;
import sys.FileSystem;
import sys.io.File;
#end

using utils.Files;
using StringTools;

typedef Stage_File = {
    var zoom:Float;
    var name:String;
    var charLayer:Int;
    var initCam:Array<Float>;
    var finishCam:Array<Float>;
    var objects:Array<Script_Object>;
}

class StageEditorState extends MusicBeatState {
    private static var save_file:SaverFile = null;
    public static var stage_file:Stage_File;
    var builder:ScriptBuilder;

    var arrayFocus:Array<FlxUIInputText> = [];
    var dragMenu:UIStageObject = null;
    var curMenu:UIContainer = null;
    
    var curObjMenu:Script_Object = null;
    var curObjTab:UIStageObject = null;
    var curObjStage:Dynamic = null;

    var ctnAttributesMenu:UIScrollList;
    var ctnPropertiesMenu:UIScrollList;
    var ctnToolboxMenu:UIScrollList;
    var ctnGeneralMenu:UIContainer;
    var ctnLayersMenu:UIScrollList;

    var btnProperties:UIButton;
    var btnGeneral:UIButton;
    var btnToolbox:UIButton;
    var btnLayers:UIButton;
    var btnReload:UIButton;

    var objectDisplay:FlxSprite;
    var cameraSprite:FlxSprite;
    var finishSpot:FlxSprite;
    var initSpot:FlxSprite;
    var debugText:FlxText;

    var stage:Stage;

    var camFollow:FlxObject;
    
    var mousePointer:FlxPoint = FlxPoint.get(0, 0);
    var mouseState:Int = -1;

    function setMousePointer(_camPoint:Dynamic, _mousePoint:Dynamic, _inverse:Bool, _state:Int):Void { 
        mousePointer.set(
            _inverse ? _mousePoint.x + _camPoint.x : _mousePoint.x - _camPoint.x, 
            _inverse ? _mousePoint.y + _camPoint.y : _mousePoint.y - _camPoint.y
        );
        mouseState = _state;
    }

    public static function parse(_file:Stage_File):Void {
        if (_file == null) { 
            _file = {
                finishCam: [1095, 800],
                initCam: [250, 180],
                name: "Stage",
                charLayer: 0,
                objects: [],
                zoom: 0.7
            };
            return;
        }
        if (_file.finishCam == null) { _file.finishCam = [1095, 800];}
        if (_file.initCam == null) { _file.initCam = [250, 180]; }
        if (_file.charLayer <= 0) { _file.charLayer = 0; }
        if (_file.objects == null) { _file.objects = []; }
        if (_file.name == null) { _file.name = "Stage"; }
        if (_file.zoom <= 0.1) { _file.zoom = 0.7; }
    }
    
    public function new(?onConfirm:String, ?onBack:String, stageName:String = "Stage"):Void {
        var stage_path:String = Paths.json('saved_stages/${stageName}');
        var stage_json:Stage_File = cast stage_path.getJson();
        StageEditorState.parse(stage_json);
        
        StageEditorState.stage_file = stage_json;

        super(onConfirm, onBack);
    }

    override function create() {
        FlxG.sound.playMusic(Paths.music('break_song').getSound());

        #if desktop
		Discord.change('Editing Stage', '[Stage Editor]');
		Magic.setWindowTitle('Editing Stage', 1);
		#end
        
        super.create();
        
        var bgGrid:FlxSprite = FlxGridOverlay.create(10, 10, FlxG.width, FlxG.height, true, 0xff4d4d4d, 0xff333333);
        bgGrid.cameras = [camGame];
        add(bgGrid);
        
        builder = new ScriptBuilder();
        builder.set("zoom", stage_file.zoom);
        builder.set("camP_1", stage_file.initCam);
        builder.set("camP_2", stage_file.finishCam);
        builder.set("initChar", stage_file.charLayer);

        stage = new Stage("Stage", [
            ["Girlfriend", [540, 50], 1, false, "Default", "NORMAL", 0],
            ["Daddy_Dearest", [100, 100], 1, true, "Default", "NORMAL", 0],
            ["Boyfriend", [770, 100], 1, false, "Default", "NORMAL", 0]
        ]);
        for (c in stage.characterData) {c.alpha = 0.5;}
        stage.loadSource(builder.build());
        stage.cameras = [camFGame];
        stage.reload();
        add(stage);

        ctnGeneralMenu = new UIContainer(FlxG.width, 0, 300, FlxG.height);
        ctnGeneralMenu.camera = camHUD;
        addGeneralMenuStuff();
        add(ctnGeneralMenu);

        ctnToolboxMenu = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnToolboxMenu.camera = camHUD;
        addToolboxMenuStuff();
        add(ctnToolboxMenu);

        ctnLayersMenu = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnLayersMenu.camera = camHUD;
        addLayersMenuStuff();
        add(ctnLayersMenu);

        ctnPropertiesMenu = new UIScrollList(FlxG.width, 0, 300, FlxG.height);
        ctnPropertiesMenu.camera = camHUD;
        add(ctnPropertiesMenu);

        ctnAttributesMenu = new UIScrollList(0, FlxG.height - 200, 300, 200);
        ctnPropertiesMenu.scroller.resize(null, Std.int(ctnPropertiesMenu.scroller.height - ctnAttributesMenu.height));
        ctnPropertiesMenu.front_group.add(ctnAttributesMenu);
        
        var ctnTabMenu:UIContainer = new UIContainer(0, 0, ctnAttributesMenu.width, 50, null, Paths.image("editor_menu/tiles/outline-right-both"));
        var ttlAttributes = new FlxText(0, 0, ctnTabMenu.display_width, "< - Attributes - >", 20); 
        ttlAttributes.alignment = CENTER;
        ctnTabMenu.addPlus(ttlAttributes, 10);
        ctnAttributesMenu.front_group.add(ctnTabMenu);

        ctnAttributesMenu.scroller.resize(null, Std.int(ctnAttributesMenu.scroller.height - ctnTabMenu.height));
        ctnAttributesMenu.scroller.y += ctnTabMenu.height - ctnAttributesMenu.list_height + 2.5;
        
        btnReload = new UIButton(10, 10, null, null, "Reload", 12, null, null, () -> {reload();});
        btnReload.camera = camHUD;
        add(btnReload);

        btnGeneral = new UIButton(10, btnReload.y + btnReload.height + 20, null, null, "General", 12, null, null, () -> {showTab(ctnGeneralMenu);});
        btnGeneral.camera = camHUD;
        add(btnGeneral);

        btnToolbox = new UIButton(10, btnGeneral.y + btnGeneral.height + 10, null, null, "Toolbox", 12, null, null, () -> {showTab(ctnToolboxMenu);});
        btnToolbox.camera = camHUD;
        add(btnToolbox);

        btnLayers = new UIButton(10, btnToolbox.y + btnToolbox.height + 10, null, null, "Layers", 12, null, null, () -> {showTab(ctnLayersMenu);});
        btnLayers.camera = camHUD;
        add(btnLayers);

        btnProperties = new UIButton(10, btnLayers.y + btnLayers.height + 10, null, null, "Properties", 12, null, null, () -> {showTab(ctnPropertiesMenu);});
        btnProperties.camera = camHUD;
        add(btnProperties);

        initSpot = new FlxSprite(stage_file.initCam[0] - 17, stage_file.initCam[1] - 17).loadGraphic(Paths.image("editor_menu/initcam"));
        initSpot.scale.set(0.5, 0.5); initSpot.updateHitbox();
        initSpot.cameras = [camFGame];
        add(initSpot);
        
        finishSpot = new FlxSprite(stage_file.finishCam[0] - 35, stage_file.finishCam[1] - 35).loadGraphic(Paths.image("editor_menu/finishcam"));
        finishSpot.scale.set(0.5, 0.5); finishSpot.updateHitbox();
        finishSpot.cameras = [camFGame];
        add(finishSpot);

        cameraSprite = new FlxSprite().loadGraphic(Paths.image("editor_menu/camera_border"));
        cameraSprite.scale.x = cameraSprite.scale.y = 1 / stage_file.zoom;
        cameraSprite.scrollFactor.set(0,0);
        cameraSprite.cameras = [camFGame];
        cameraSprite.alpha = 0.5;
        add(cameraSprite);

        debugText = new FlxText(0, 0, 0, "", 20);
        debugText.y = FlxG.height - debugText.height;
        debugText.cameras = [camHUD];
        add(debugText);

		camFollow = new FlxObject(0, 0, 1, 1);
        camFollow.screenCenter();
		add(camFollow);
        
        camFGame.zoom = stage_file.zoom;
        camFGame.follow(camFollow, LOCKON);
        
        FlxG.mouse.visible = true;
    }

    public function showTab(_tab:UIContainer):Void {
        if (curMenu != null) {
            FlxTween.cancelTweensOf(curMenu);
            FlxTween.tween(curMenu, {x: FlxG.width}, 0.2, {ease: FlxEase.quadOut});
        }

        curMenu = curMenu == _tab ? null : _tab;

        if (curMenu != null) {
            FlxTween.cancelTweensOf(curMenu);
            FlxTween.tween(curMenu, {x: FlxG.width - curMenu.width}, 0.2, {ease: FlxEase.quadOut});
        }
    }

    override function update(elapsed:Float) {
        camFGame.x = FlxMath.lerp(camFGame.x, curMenu != null ? -(curMenu.width / 2) : 0, elapsed * 20);
        var pMouse = FlxG.mouse.getPositionInCameraView(camFGame);
        var wMouse = FlxG.mouse.getWorldPosition(camFGame);

        debugText.text = 'X: ${Std.int(wMouse.x)} | Y: ${Std.int(wMouse.y)}';

        var arrayControlle = true;
        for (item in arrayFocus) {if (item.hasFocus) {arrayControlle = false;}}

        if (canControlle && arrayControlle) {

            switch (mouseState) {
                case 0: {
                    camFollow.setPosition(
                        Math.min(Math.max(mousePointer.x - pMouse.x, stage_file.initCam[0]), stage_file.finishCam[0]), 
                        Math.min(Math.max(mousePointer.y - pMouse.y, stage_file.initCam[1]), stage_file.finishCam[1])
                    );
                }
                case 1: {initSpot.setPosition(Math.floor(wMouse.x - mousePointer.x), Math.floor(wMouse.y - mousePointer.y));}
                case 2: {finishSpot.setPosition(Math.floor(wMouse.x - mousePointer.x), Math.floor(wMouse.y - mousePointer.y));}
                case 3: {
                    curObjMenu.variables.x = curObjStage.x = Std.int(wMouse.x - mousePointer.x);
                    curObjMenu.variables.y = curObjStage.y = Std.int(wMouse.y - mousePointer.y);
                }
                case 4: {dragMenu.y = FlxG.mouse.y - mousePointer.y;}
            }

            initSpot.alpha = finishSpot.alpha = 0.5;
            if (FlxG.mouse.overlaps(initSpot, camFGame)) {initSpot.alpha = 1;}
            else if (FlxG.mouse.overlaps(finishSpot, camFGame)) {finishSpot.alpha = 1;}

            if ((FlxG.mouse.releasedRight && mouseState == 0) || (FlxG.mouse.justReleased && mouseState == 4) || (FlxG.mouse.released && mouseState > 0 && mouseState < 4)) {
                switch (mouseState) {
                    case 1:{stage_file.initCam = [initSpot.x + 16, initSpot.y + 16];}
                    case 2:{stage_file.finishCam = [finishSpot.x + 35, finishSpot.y + 35];}
                    case 4:{
                        dragMenu = null;
                        mouseState = -1;

                        ctnLayersMenu.list.sort(FlxSort.byY);
                        builder.members = [];

                        ctnLayersMenu.current_height = 0;
                        for (_objTab in ctnLayersMenu.list.members) {
                            builder.members.push(cast(_objTab, UIStageObject)._object);
                            FlxTween.tween(_objTab, {y: ctnLayersMenu.list_height + ctnLayersMenu.current_height}, 0.1, {ease: FlxEase.quadInOut});
                            ctnLayersMenu.current_height += _objTab.height + 5;
                        }

                        reload();
                    }
                }
                mouseState = -1;
            } else if (mouseState == -1) {
                if (FlxG.mouse.justPressedRight && (curMenu == null || FlxG.mouse.x < FlxG.width - curMenu.width)) {setMousePointer(camFollow, pMouse, true, 0);}
                else if (FlxG.mouse.justPressed) {
                    if (FlxG.mouse.overlaps(initSpot, camFGame)) {setMousePointer(initSpot, wMouse, false, 1);}
                    else if (FlxG.mouse.overlaps(finishSpot, camFGame)) {setMousePointer(finishSpot, wMouse, false, 2);}
                    else if (curObjStage != null && FlxG.mouse.overlaps(curObjStage, camFGame)) {setMousePointer(curObjStage, wMouse, false, 3);}
                    else if (dragMenu == null) {
                        for (_objTab in ctnLayersMenu.list.members) {
                            if (!FlxG.mouse.overlaps(_objTab)) { continue;}
                            dragMenu = cast _objTab;
                            setMousePointer(dragMenu, FlxG.mouse, false, 4);
                        }
                    }
                } else if (FlxG.mouse.justReleasedRight) {
                    for (_objTab in ctnLayersMenu.list.members) {
                        if (!FlxG.mouse.overlaps(_objTab)) { continue;}
                        curObjTab = cast _objTab;
                        if (curObjTab._object != curObjMenu) {
                            curObjStage = curObjTab._stage;
                            curObjMenu = cast curObjTab._object;
                            setPropertiesMenu();
                        }
                        showTab(ctnPropertiesMenu);
                        break;
                    }
                }
            }

            if (FlxG.keys.pressed.SHIFT) {
                if (FlxG.mouse.justPressedMiddle) {camFGame.zoom = stage_file.zoom;}
                if (FlxG.mouse.wheel != 0) {camFGame.zoom += (FlxG.mouse.wheel * 0.1);}
            } else {
                if (FlxG.mouse.justPressedMiddle) {camFollow.screenCenter();}
                if (FlxG.mouse.wheel != 0) {camFGame.zoom += (FlxG.mouse.wheel * 0.01);}
            }
        }   
        
        super.update(elapsed);
    }
    
    var txtStage:UIInputText;
    var sldInitChar:UISlider;
    var sldZoom:UISlider;
    private function addGeneralMenuStuff():Void {
        var ttlStage = new FlxText(0, 5, ctnGeneralMenu.display_width, "< - Stage - >", 20); ctnGeneralMenu.addPlus(ttlStage, 10);
        ttlStage.alignment = CENTER;

        var lblStage = new FlxText(0, 0, ctnGeneralMenu.display_width, "Stage:", 12); ctnGeneralMenu.addPlus(lblStage, 0);
        txtStage = new UIInputText(0, 0, ctnGeneralMenu.display_width, stage_file.name, 16, (_text)->{stage_file.name = _text;});
        arrayFocus.push(txtStage);
        ctnGeneralMenu.addPlus(txtStage, 10);

        var btnExport:FlxUIButton = new UIButton(0, 0, Std.int(ctnGeneralMenu.display_width / 2 - 2.5), null, "Export (.hx)", 16, null, null, () -> {
            if (save_file != null) { return;}
            
            builder.set("zoom", stage_file.zoom);
            builder.set("camP_1", stage_file.initCam);
            builder.set("camP_2", stage_file.finishCam);
            builder.set("initChar", stage_file.charLayer);

            save_file = new SaverFile([{name: '${txtStage.text}.hx', data: builder.build()}], {destroyOnComplete: true, onComplete: ()->{save_file = null;}});
			save_file.saveFile();
        }); ctnGeneralMenu.addPlus(btnExport, 0, false);

        var btnSave:FlxUIButton = new UIButton(btnExport.width + 5, 0, Std.int(ctnGeneralMenu.display_width / 2 - 2.5), null, "Save (.json)", 16, null, null, () -> {
            if (save_file != null) { return;}
            save_file = new SaverFile([{name: '${txtStage.text}.json', data: Json.stringify(stage_file, "\t")}], {destroyOnComplete: true, onComplete: ()->{save_file = null;}});
			save_file.saveFile();
        }); ctnGeneralMenu.addPlus(btnSave);

        var btnLoad:FlxUIButton = new UIButton(0, 0, ctnGeneralMenu.display_width, null, "Load Stage", 16, null, null, () -> {
            MusicBeatState.switchState("states.editors.StageEditorState", [null, "states.MainMenuState", txtStage.text]);
        }); ctnGeneralMenu.addPlus(btnLoad, 10);
        
        var ttlInformation = new FlxText(0, 0, ctnGeneralMenu.display_width, "< - Information - >", 20); ctnGeneralMenu.addPlus(ttlInformation, 10);
        ttlInformation.alignment = CENTER;

        var lblInitChar = new FlxText(0, 0, ctnGeneralMenu.display_width, "Initial Character Layer:", 12); ctnGeneralMenu.addPlus(lblInitChar, 0);
        sldInitChar = new UISlider(10, 0, 12, ctnGeneralMenu.display_width - 20, 20, false, stage_file, "charLayer", 0, 0);
        ctnGeneralMenu.addPlus(sldInitChar);

        var lblZoom = new FlxText(0, 0, ctnGeneralMenu.display_width, "Stage Zoom:", 12); ctnGeneralMenu.addPlus(lblZoom, 0);
        sldZoom = new UISlider(10, 0, 12, ctnGeneralMenu.display_width - 20, 20, false, stage_file, "zoom", 0.1, 2);
        sldZoom.callback = (_value) -> {
            cameraSprite.scale.x = cameraSprite.scale.y = 1 / _value;
            cameraSprite.screenCenter();
        }
        ctnGeneralMenu.addPlus(sldZoom);
    }

    private function addLayersMenuStuff():Void {
        var ctnTabMenu:UIContainer = new UIContainer(0, 0, ctnLayersMenu.width, 50, null, Paths.image("editor_menu/tiles/outline-right-end")); ctnLayersMenu.front_group.add(ctnTabMenu);
        var ttlLayers = new FlxText(0, 0, ctnTabMenu.display_width, "< - Layers - >", 20); ctnTabMenu.addPlus(ttlLayers, 10);
        ttlLayers.alignment = CENTER;

        ctnLayersMenu.scroller.resize(null, Std.int(ctnLayersMenu.scroller.height - ctnTabMenu.height));
        ctnLayersMenu.scroller.y += ctnTabMenu.height - ctnLayersMenu.list_height + 2.5;
        ctnLayersMenu.list_height = ctnTabMenu.height + 5;

        for (_obj in stage_file.objects) {addObject(_obj);}
    }

    private function addToolboxMenuStuff():Void {
        var ctnTabMenu:UIContainer = new UIContainer(0, 0, ctnToolboxMenu.width, 50, null, Paths.image("editor_menu/tiles/outline-right-end")); ctnToolboxMenu.front_group.add(ctnTabMenu);
        var ttlToolbox = new FlxText(0, 0, ctnTabMenu.display_width, "< - Toolbox - >", 20); ctnTabMenu.addPlus(ttlToolbox, 10);
        ttlToolbox.alignment = CENTER;

        ctnToolboxMenu.scroller.resize(null, Std.int(ctnToolboxMenu.scroller.height - ctnTabMenu.height));
        ctnToolboxMenu.scroller.y += ctnTabMenu.height - ctnToolboxMenu.list_height + 2.5;

        for (i in Paths.readDirectory('assets/data/stage_objects')) {
            if (i.contains(".")) { continue;}
            var object_name:String = i.split("/").pop();

            var btnToolboxItem:UIButton = new UIButton(
                0,
                ctnTabMenu.height,
                ctnToolboxMenu.display_width,
                null,
                object_name,
                20,
                null,
                null,
                ()->{addObject(object_name);}
            );
            ctnToolboxMenu.addList(btnToolboxItem);
        }
    }

    public function setPropertiesMenu():Void {
        for (_objTab in ctnLayersMenu.list.members) {cast(_objTab, UIStageObject)._back.alpha = _objTab == curObjTab ? 1 : 0.5;}

        while(ctnPropertiesMenu.list.length > 0) {ctnPropertiesMenu.list.remove(ctnPropertiesMenu.list.members[0], true).destroy();}
        ctnPropertiesMenu.current_height = 0;

        var _objFile:File_Object = ScriptBuilder.files[curObjMenu.object];

        var ttlObject = new FlxText(0, 5, ctnPropertiesMenu.display_width, '< - ${curObjMenu.object} - >', 20); ctnPropertiesMenu.addList(ttlObject, 10);
        ttlObject.alignment = CENTER;

        var lblName = new FlxText(0, 0, ctnPropertiesMenu.display_width, "Object Name:", 12); ctnPropertiesMenu.addList(lblName, 0);
        var txtName = new UIInputText(0, 0, ctnPropertiesMenu.display_width, curObjMenu.name, 16, (_text)->{curObjTab.lblObjName.text = curObjMenu.name = _text;});
        arrayFocus.push(txtName);
        ctnPropertiesMenu.addList(txtName, 20);

        for (_var in _objFile.variables) {
            if (_var.name == "x" || _var.name == "y") { continue;}
            switch (_var.type) {
                case "bool": {
                    var chkVariable = new UICheckBox(0, 0, ctnPropertiesMenu.display_width, _var.name, 18, Reflect.getProperty(curObjMenu.variables, _var.name), (_value) -> {
                        Reflect.setProperty(curObjMenu.variables, _var.name, _value);
                        if (curObjStage == null) { return;}
                        var _dynObj = curObjStage;
                        var _dynPro = _var.name;

                        if (_var.name.split("-").length > 0) {
                            var _argList = _var.name.split("-");
                            for (i in 0..._argList.length - 1) {
                                _dynObj = Reflect.getProperty(_dynObj, _argList[i]);
                                _dynPro = _argList[i + 1];
                            }
                        }
                        
                        Reflect.setProperty(_dynObj, _dynPro, _value);
                    }); 
                    ctnPropertiesMenu.addList(chkVariable, 0);
                }
                case "float":{
                    var lblDisplay = new FlxText(0, 0, ctnPropertiesMenu.display_width, _var.name, 12);
                    ctnPropertiesMenu.addList(lblDisplay, 0);

                    if (_var.args != null) {
                        var sldDisplay = new UISlider(10, 0, 12, ctnPropertiesMenu.display_width - 20, 20, false, curObjMenu.variables, _var.name, _var.args[0], _var.args[1]);
                        sldDisplay.callback = (_value) -> {
                            if (curObjStage == null) { return;}
                            var _dynObj = curObjStage;
                            var _dynPro = _var.name;

                            if (_var.name.split("-").length > 0) {
                                var _argList = _var.name.split("-");
                                for (i in 0..._argList.length - 1) {
                                    _dynObj = Reflect.getProperty(_dynObj, _argList[i]);
                                    _dynPro = _argList[i + 1];
                                }
                            }

                            Reflect.setProperty(_dynObj, _dynPro, _value);
                        }
                        ctnPropertiesMenu.addList(sldDisplay);
                    }
                }
                case "string":{
                    var lblDisplay = new FlxText(0, 0, ctnPropertiesMenu.display_width, _var.name, 12);
                    ctnPropertiesMenu.addList(lblDisplay, 0);

                    var txtDisplay = new UIInputText(0, 0, ctnPropertiesMenu.display_width, Reflect.getProperty(curObjMenu.variables, _var.name), 16, 
                        (_text)->{Reflect.setProperty(curObjMenu.variables, _var.name, _text);},
                        (_text)->{reload();}
                    );
                    arrayFocus.push(txtDisplay);
                    ctnPropertiesMenu.addList(txtDisplay);
                }
            }
        }

        for (_attObj in curObjMenu.attributes) {
            var ctnObjectAtt:UIContainer = new UIContainer(5, 0, ctnPropertiesMenu.display_width - 10, 100, Paths.image("editor_menu/tiles/light"));
            ctnObjectAtt.list_height = ctnObjectAtt.list_width = 5;
            ctnObjectAtt.visible_front = false;
            ctnObjectAtt.resize(ctnObjectAtt.width, 10);

            var ttlAttribute = new FlxText(0, 0, ctnObjectAtt.display_width - 30, _attObj.object, 14); 
            ttlAttribute.alignment = CENTER;

            var btnDelAtt = new UIButton(ttlAttribute.width + 10, 0, 20, null, "X", 8, null, 0xfff33939, ()->{curObjMenu.attributes.remove(_attObj); setPropertiesMenu();});
            btnDelAtt.label.color = FlxColor.WHITE;

            ctnObjectAtt.addPlus(ttlAttribute, 0, false);
            ctnObjectAtt.addPlus(btnDelAtt);

            var _attFile:File_Object = ScriptBuilder.files[_attObj.object];

            for (_var in _attFile.variables) {
                switch (_var.type) {
                    case "bool": {
                        var chkVariable = new UICheckBox(0, 0, ctnObjectAtt.display_width, _var.name, 18, Reflect.getProperty(_attObj.variables, _var.name), (_value) -> {
                            Reflect.setProperty(_attObj.variables, _var.name, _value);
                        }); 
                        ctnObjectAtt.addPlus(chkVariable, 0);
                    }
                    case "float":{
                        var lblDisplay = new FlxText(0, 0, ctnObjectAtt.display_width, _var.name, 12);
                        ctnObjectAtt.addPlus(lblDisplay, 0);
    
                        if (_var.args != null) {
                            var sldDisplay = new UISlider(10, 0, 12, ctnObjectAtt.display_width - 20, 20, false, _attObj.variables, _var.name, _var.args[0], _var.args[1]);
                            ctnObjectAtt.addPlus(sldDisplay);
                        }
                    }
                    case "string":{
                        var lblDisplay = new FlxText(0, 0, ctnObjectAtt.display_width, _var.name, 12);
                        ctnObjectAtt.addPlus(lblDisplay, 0);
    
                        var txtDisplay = new UIInputText(0, 0, ctnObjectAtt.display_width, Reflect.getProperty(_attObj.variables, _var.name), 16, 
                            (_text)->{Reflect.setProperty(_attObj.variables, _var.name, _text);},
                            (_text)->{reload();}
                        );
                        arrayFocus.push(txtDisplay);
                        ctnObjectAtt.addPlus(txtDisplay);
                    }
                }
            }

            ctnObjectAtt.resize(ctnObjectAtt.width, ctnObjectAtt.height + 10);
            ctnPropertiesMenu.addList(ctnObjectAtt);
        }
        
        while(ctnAttributesMenu.list.length > 0) {ctnAttributesMenu.list.remove(ctnAttributesMenu.list.members[0], true).destroy();}
        ctnAttributesMenu.current_height = ctnAttributesMenu.y + ctnAttributesMenu.front_group.members[0].height - 10;

        for (_att in Paths.readDirectory('assets/data/stage_objects/${curObjMenu.object}')) {
            var _att_name:String = _att.split("/").pop().replace(".json", "");
            if (_att_name == curObjMenu.object) { continue;}
            var btnAttribute:UIButton = new UIButton(0, 5, ctnAttributesMenu.display_width, null, _att_name, 14, null, null, ()->{
                if (ScriptBuilder.addAttribute(curObjMenu, _att_name) == null) { return;}
                setPropertiesMenu();
            });
            ctnAttributesMenu.addList(btnAttribute);
        }
    }

    public function addObject(object_name:Dynamic):Void {
        if ((object_name is String)) {builder.add(object_name);}
        else {
            builder._add(object_name);
            for (_att in cast(object_name.attributes, Array<Dynamic>)) {ScriptBuilder.load(object_name.object, _att.object);}
        }

        var _obj:Script_Object = builder.last();

        ctnLayersMenu.addList(new UIStageObject(0, 0, ctnLayersMenu.display_width, _obj.name, _obj.object, ()->{
            builder.members.remove(_obj); 
            if (builder.members.length <= 0) {
                ctnLayersMenu.list.remove(ctnLayersMenu.list.members[0], true).destroy();
            } else {
                for (i in 0...builder.members.length) {
                    if (cast(ctnLayersMenu.list.members[i], UIStageObject)._object == builder.members[i]) { continue;}
                    ctnLayersMenu.list.remove(ctnLayersMenu.list.members[i], true).destroy(); break;
                }
            }
            reload();
        }));
        
        reload();

        sldInitChar.maxValue++;
        showTab(ctnLayersMenu);
    }

    public function reload():Void {
        builder.set("zoom", stage_file.zoom);
        builder.set("camP_1", stage_file.initCam);
        builder.set("camP_2", stage_file.finishCam);
        builder.set("initChar", stage_file.charLayer);

        stage_file.objects = builder.members;
        
        stage.loadSource(builder.build());

        var _stage_offset:Int = 0;
        for (i in 0...builder.members.length) {
            var _cur_obj:Script_Object = builder.members[i];
            var _cur_file:File_Object = ScriptBuilder.files[_cur_obj.object];
            var _cur_layer:UIStageObject = cast ctnLayersMenu.list.members[i];
            var _cur_stage:Dynamic = _cur_file.create_object ? stage.stageData[i - _stage_offset] : null;
            if (!_cur_file.create_object) {_stage_offset++;}
            
            _cur_layer._object = _cur_obj;
            _cur_layer._stage = _cur_stage;   
            if (_cur_obj == curObjMenu) {curObjStage = _cur_stage;}
        }
    }
    
    var onReload:Bool = false;
    private function getFile(_onSelect:String->Void):Void {
        if (onReload) { return;} onReload = true;

        var fDialog = new FileDialog();
        fDialog.onSelect.add(function(str) {onReload = false; _onSelect(str);});
        fDialog.browse();
	}

    override function destroy() {
        FlxG.sound.music.stop();
        super.destroy();
    }
}

class UIStageObject extends UIContainer {
    public var lblObjName:FlxText;
    public var lblObjFile:FlxText;

    public var btnDelete:UIButton;

    public var _object:Script_Object;
    public var _stage:Dynamic;

    public function new(_x:Float = 0, _y:Float = 0, _width:Float = 200, _title:String, _object:String, _callback:Void->Void):Void {
        super(_x, _y, _width, 5, Paths.image("editor_menu/tiles/light"));
        list_height = list_width = 5;
        visible_front = false; 
        _back.alpha = 0.5;
        
        lblObjName = new FlxText(0, 0, display_width - 30, _title, 20); addPlus(lblObjName);
        lblObjFile = new FlxText(0, 0, display_width, _object, 12); addPlus(lblObjFile);
        btnDelete = new UIButton(lblObjName.width + 5, 5, 30, Std.int(height - 15), "X", 12, null, 0xfff33939, _callback); add(btnDelete);

        resize(_width, Std.int(lblObjName.height + lblObjFile.height + 15));
    }
}