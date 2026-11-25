import h3d.Engine;
import hxd.Window;
import h2d.Text;
import hxd.Key;
import hxd.Math;
import h3d.scene.Object;
import sys.thread.Condition;
import modchart.events.ModEvent;
import h3d.Vector;
import modchart.ModManager;
import h2d.Slider;
import h3d.scene.Mesh;
import h3d.prim.Cube;

@:structInit class NoteThing {
    public var mesh: Object;
    public var column: Int;
    public var time: Float;
    public var beat: Float = 0;
    public var params: ModifierParams;
}

@:structInit class Receptor {
    public var mesh: Mesh;
    public var column: Int;
    public var params: ModifierParams;
}

enum ObjectType {
    RECEPTOR;
    NOTE;
}

class Main extends hxd.App
{
    public static final ARROW_SIZE = 75;
    public static final PLAYER_HEIGHT: Float = 720 - (70 + Main.ARROW_SIZE);
    var slider: Slider;
    var mgr: ModManager;

    var txt: Text;
    
    var maxTime: Float = 0;

    public static var notes: Array<NoteThing> = [];
    public static var receptors: Array<Receptor> = [];

    var colors = [
        0xdf88e2,
        0x00ffff,
        0x88e290,
        0xe03939
    ];

    inline public static function triangle(angle:Float) {
        var fAngle:Float = angle % (Math.PI * 2.0);
        if (fAngle < 0.0)
            fAngle += Math.PI * 2.0;
        
        var result:Float = fAngle / Math.PI;
        
        if (result < 0.5) {
            return 2.0 * result;
        }
        else if (result < 1.5) {
            return -2.0 * result + 2.0;
        }
        else {
            return 2.0 * result - 4.0;
        }
    }

    function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));

    var degrees: Array<Float> = [90, 0, 180, -90];

    override function init() 
    {
        Conductor.mapTimeSegments();

        var cube = new Cube(64, 4, 64, true);

        /*
            public var strumBeat: Float;
    public var strumTime: Float;
    public var column: Int;
    public var playerNumber: Int;
    public var objectType: ObjectType;

    public var songTime: Float;
    public var songBeat: Float;
    public var unmodifiedDistance: Float;
    public var distance: Float;
    public var pos: Vector3;
    */
        for(i in 0...4){
            var mesh = new Mesh(cube, null, s3d);
            mesh.material.color.setColor(colors[i]);
            mesh.material.shadows = false;
            mesh.x = (1280 / 2 + i * 64) - 96;
            mesh.y = -500;
            receptors.push({
                mesh: mesh,
                column: i,
                params: {
                    strumBeat: 0,
                    strumTime: 0,
                    column: i,
                    playerNumber: 0,
                    objectType: RECEPTOR
                }
            });
        }

        var cache = new h3d.prim.ModelCache();
        cache.loadLibrary(hxd.Res.Cel);
        

        var col = 0;
        var inv = false;
        for(i in 0...6){
            var mesh = cache.loadModel(hxd.Res.Cel);

            for(m in mesh.getMaterials()){
                m.shadows = false;
                m.blendMode = Alpha;
                m.mainPass.depthWrite = true;
                m.mainPass.depthTest = LessEqual;
            }

            mesh.rotate(Math.degToRad(degrees[col]), 0, Math.degToRad(90));
            
            s3d.addChild(mesh);

            var time: Float = (i + 1) * 250;
            var beat: Float = Conductor.getBeatInfoFromTime(time).beat;
            notes.push({
                time: time,
                column: col,
                beat: beat,
                mesh: mesh,
                params: {
                    strumBeat: beat,
                    strumTime: time,
                    column: col,
                    playerNumber: 0,
                    objectType: NOTE
                }
            });

            if(inv)
                col -= 1;
            else 
                col += 1;

            if(col == 0)
                inv = false;
            else if(col == 3)
                inv = true;

        }

        maxTime = Math.max(notes[notes.length - 1].time * 1, 1000);

        cache.dispose();

        cast(s3d.lightSystem,h3d.scene.fwd.LightSystem).ambientLight.set(1, 1, 1);
        
        s3d.camera = new Camera3D2D();

        var engine = h3d.Engine.getCurrent();
		if( engine != null )
			s3d.camera.screenRatio = engine.width / engine.height;

        slider = new Slider(250, 10, s2d);
        slider.onChange = function() {
            Conductor.time = slider.value * (60 * 1000);
            Conductor.updateTime(Conductor.time);
        };
        mgr = new ModManager();

        var aux = mgr.addAux("bullshit", 0);

        mgr.makeNode(["bullshit"], (inputs: Array<Float>, pN:Int) -> {
            return [inputs[0]];
        }, ["beaty"]);

        mgr.setValue("beat", 1);
        mgr.setValue("bullshit", 1);

        txt = new Text(hxd.res.DefaultFont.get(), s2d);
        txt.y += 100;
        txt.text = "FUCK";

        Window.getInstance().vsync = false;
    }

    var frames: Int = 0;
    var updateTimer:Float = 0;
    var playing = true;
    override function update(dt: Float)
    {
        frames++;
        updateTimer += dt;
        if(Key.isPressed(Key.SPACE))
            playing = !playing;
        

        if(playing){
            Conductor.time += (dt * 1000);
            Conductor.updateTime(Conductor.time);
        }
        slider.value = Conductor.time / (60 * 1000);
        mgr.update(dt);
        

        for(receptor in receptors){
            receptor.params.songTime = Conductor.time;
            receptor.params.songBeat = Conductor.beat;
            var pos: Vector = mgr.getPos(receptor.params);
            receptor.mesh.x = 1280 / 2 + pos.x;
            receptor.mesh.z = -(720 / 2) + pos.y;
            receptor.mesh.y = pos.z;
        }
        
        for(note in notes){
            final time: Float = note.time + Math.ceil((Conductor.time - note.time) / maxTime) * maxTime;
            
            note.params.songBeat = Conductor.beat;
            note.params.songTime = Conductor.time;

            final origDist: Float = mgr.getDistance(time, Conductor.time);
            note.params.unmodifiedDistance = origDist;
            note.params.distance = origDist;
            mgr.modifyDistance(note.params);

            note.mesh.setRotation(Math.degToRad(degrees[note.column]), 0, Math.degToRad(90));
            

            var pos: Vector = mgr.getPos(note.params);
            note.mesh.x = 1280 / 2 + pos.x;
            note.mesh.z = -(720 / 2) + pos.y;
            note.mesh.y = pos.z;
        }

        if(updateTimer > 1){
            updateTimer = 0;
            txt.text = Std.string(frames) + " FPS";
            frames = 0;
        }
    }

    static function main() {
        hxd.Res.initEmbed();
        new Main();
    }
}