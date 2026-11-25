package modchart.events;

typedef EasingFunc = Float -> Float;

// Handles both set and ease events depending on if it has an endStep etc set

class ModEvent extends BaseEvent {
    // Required properties
    var name: String;
    var target: Float = 0;
    var fieldNum: Int = -1;
    var mod: Modifier;


    // Ease properties
    var length: Float = 0; // How long it will last, if it is eased
    var easeFunc: EasingFunc;
    var startValue: Null<Float> = null;

    
    public function new(modifier: Modifier, valueName: String, step:Float, target: Float, player:Int, ?endStep:Float, ?ease: EasingFunc, ?start: Float) {
        super();
        if(modifier.values[player] == null)
            throw 'Invalid player number of ${player}';


        this.mod = modifier;
        this.name = valueName;
        this.target = target;
        this.step = step;
        this.fieldNum = player;

        if(endStep != null){
            length = endStep - step;
            ease ??= prog -> prog;
            easeFunc = ease;
            
            startValue = start;
            continuous = true;
        }
    }

    override function run(){
        if(!mod.values[fieldNum].exists(name)){
            finished = true;
            continuous = false;
            trace('Value $name does not exist in modifier ${mod}!');
            return;
        }

        if(continuous){
            if(startValue == null)
                startValue = mod.getValue(name, fieldNum);
        }else
            mod.setValue(name, target, fieldNum);
        

    }

    override function tick(current: Float){
        var endStep: Float = step + length;
        if(current > endStep){
            finished = true;
            mod.setValue(name, target, fieldNum);
        }else{
            var progress: Float = (current - step) / length;
            var change: Float = (target - startValue);
            var value: Float = startValue + change * easeFunc(progress);
            mod.setValue(name, value, fieldNum);
        }

    }
}