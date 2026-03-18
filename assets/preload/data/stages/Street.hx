
import flixel.group.FlxTypedGroup;
import flixel.FlxSprite;
import utils.Settings;
import flixel.FlxG;
import utils.Files;
import utils.Paths;
import Type;

function cache(temp):Void {
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/BG')});
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/Sky')});
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/BGP')});
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/Flechas')});
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/Flechas')});
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/BANQUETA')});
    temp.push({type:"IMAGE",instance:Paths.image('stages/street/BackBuildings')});
}

preset("initChar", 9);
preset("camP_1", [250,-3200]);
preset("camP_2", [1000,850]);
preset("zoom", 0.4);

var car_list = ["Agent_Moto", "Agent_Moto2", "Agents_Car", "Def_Cars", "Fire_Car", "Formula1", "Limusine", "RTX_Car"];
var car_group:FlxTypedGroup<FlxSprite>;

function create():Void {
    var sky = new FlxSprite(-1750, -1650).loadGraphic(Paths.image('stages/street/Sky'));
    sky.scrollFactor.set(0.1,0.1);
    push(sky);

    var city = new FlxSprite(-1500,-600).loadGraphic(Paths.image('stages/street/BackBuildings'));
    city.scrollFactor.set(0.5,1);
    push(city);

    var mall = new FlxSprite(-1410, -700).loadGraphic(Paths.image('stages/street/BG'));
    mall.scrollFactor.set(0.8, 1);
    push(mall);

    var arrow_4_position:Array<Int> = [];

    var arrow_4 = new FlxSprite(220, -260);
    arrow_4.frames = Files.getAtlas(Paths.image('stages/street/Flechas'));
    arrow_4.animation.addByPrefix("flecha","2flecha");
    if (Settings.get("Animated", "GraphicSettings")) { arrow_4.animation.play('flecha'); }
    arrow_4.scrollFactor.set(0.8, 1);
    arrow_4.flipX = true;
    push(arrow_4);

    var arrow_3 = new FlxSprite(780, -260);
    arrow_3.frames = Files.getAtlas(Paths.image('stages/street/Flechas'));
    arrow_3.animation.addByPrefix("flecha","2flecha");
    if (Settings.get("Animated", "GraphicSettings")) { arrow_3.animation.play('flecha'); }
    arrow_3.scrollFactor.set(0.8, 1);
    push(arrow_3);

    var arrow_1 = new FlxSprite(910, -70);
    arrow_1.frames = Files.getAtlas(Paths.image('stages/street/Flechas'));
    arrow_1.animation.addByPrefix("flecha","flecha");
    if (Settings.get("Animated", "GraphicSettings")) { arrow_1.animation.play('flecha'); }
    arrow_1.scrollFactor.set(0.8, 1);
    push(arrow_1);

    var arrow_2 = new FlxSprite(100, -70);
    arrow_2.frames = Files.getAtlas(Paths.image('stages/street/Flechas'));
    arrow_2.animation.addByPrefix("flecha","flecha");
    if (Settings.get("Animated", "GraphicSettings")) { arrow_2.animation.play('flecha'); }
    arrow_2.scrollFactor.set(0.8, 1);
    arrow_2.flipX = true;
    push(arrow_2);

    var bar = new FlxSprite(-1340, 130).loadGraphic(Paths.image('stages/street/BGP'));
    bar.scrollFactor.set(0.8, 1);
    push(bar);
    
    car_group = Type.createInstance(FlxTypedGroup, []);
    for (i in 0...car_list.length) {
        var new_car = new FlxSprite(0, 0);
        new_car.frames = Files.getAtlas(Paths.image('stages/street/' + car_list[i]));
        new_car.flipX = FlxG.random.bool(50);
        new_car.scrollFactor.set(0.8, 1);
        new_car.x = new_car.flipX ? bar.x + bar.width : bar.x - new_car.width;

        var speed:Float = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;

        new_car._.onSide = function() {
            new_car.flipX = !new_car.flipX;
            new_car.x = new_car.flipX ? bar.x + bar.width : bar.x - new_car.width;
            new_car.velocity.x = new_car.flipX ? -speed : speed;
        }
        new_car._.update = function(elapsed:Float) {
            if (
                (new_car.flipX && (new_car.x + new_car.width + 100) < sky.x) ||
                (!new_car.flipX && (new_car.x - new_car.width) > (sky.x + sky.width))
            ) { new_car.velocity.x = 0; }
        }

        switch (i) {
            case 0:{
                new_car.animation.addByPrefix("agentMoto", "agentMoto");
                new_car.animation.play("agentMoto");
            }
            case 1:{
                new_car.animation.addByPrefix("agentMotoAlt", "agentMotoAlt");
                new_car.animation.play("agentMotoAlt");
            }
            case 2:{
                new_car.animation.addByPrefix("AgentsCar", "AgentsCar");
                new_car.animation.play("AgentsCar");
                new_car.y -= 500;
            }
            case 3:{
                new_car.animation.addByPrefix("CarBlack", "CarBlack");
                new_car.animation.addByPrefix("CarBlue", "CarBlue");
                new_car.animation.addByPrefix("CarGreen", "CarGreen");
                new_car.animation.addByPrefix("CarGrey", "CarGrey");
                new_car.animation.addByPrefix("CarPink", "CarPink");
                new_car.animation.addByPrefix("CarRe", "CarRe");

                new_car._.onSide = function() {
                    new_car.flipX = !new_car.flipX;
                    new_car.x = new_car.flipX ? bar.x + bar.width : bar.x - new_car.width;
                    new_car.velocity.x = new_car.flipX ? -speed : speed;

                    var car_anims = ["CarBlack", "CarBlue", "CarGreen", "CarGrey", "CarPink", "CarRe"];
                    new_car.animation.play(car_anims[FlxG.random.int(0, car_anims.length - 1)]);
                }

                new_car.animation.play("CarBlack");
                new_car.y += 100;
            }
            case 4:{
                new_car.animation.addByPrefix("SD_Car", "SD_Car");
                new_car.animation.play("SD_Car");

                new_car.y -= 350;
            }
            case 5:{
                new_car.animation.addByPrefix("formula1", "formula1");
                new_car.animation.play("formula1");

                new_car.y += 200;
            }
            case 6:{
                new_car.animation.addByPrefix("Limusine", "Limusine");
                new_car.animation.play("Limusine");

                new_car.y += 150;
            }
            case 7:{
                new_car.animation.addByPrefix("RTX", "RTX");
                new_car.animation.play("RTX");

                new_car.y += 15;
            }
        }
        car_group.add(new_car);
    }
    push(car_group);

    var floor = new FlxSprite(-2000, 100).loadGraphic(Paths.image('stages/street/BANQUETA'));
    push(floor);
}

function run_car():Void {
    var cur_car = car_group.members[FlxG.random.int(0, car_group.length - 1)];
    cur_car._.onSide();
}