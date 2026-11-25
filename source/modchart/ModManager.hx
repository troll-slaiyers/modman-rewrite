package modchart;

import Main.ObjectType;
import modchart.ModifierMacro.ModifierBool;
import modchart.ModifierMacro.ModifierValue;
import modchart.events.ModEvent;
import sys.thread.Condition;
import h3d.Vector as Vector3;



@:structInit class ModifierParams
{
    public var strumBeat: Float;
    public var strumTime: Float;
    public var column: Int;
    public var playerNumber: Int;
    public var objectType: ObjectType;

    public var songTime: Float = 0;
    public var songBeat: Float = 0;
    public var unmodifiedDistance: Float = 0;
    public var distance: Float = 0;
    public var pos: Vector3 = new Vector3();
}

@:structInit class ModifierValueInfo 
{
    public var instance: Modifier;
    public var valueName: String; // for aliases + nodes

    public inline function set(val: Float, pN: Int)
        instance.setValue(valueName, val, pN);
 
    public inline function get(pN: Int)
        return instance.getValue(valueName, pN);

}

typedef NodeCallback = (values:Array<Float>, player:Int) -> Array<Float>;

@:structInit class Node 
{
    public var inputs: Array<ModifierValueInfo> = [];
    public var outputs: Array<ModifierValueInfo> = [];
    public var callback: NodeCallback;
}

class GlobalValues extends Modifier 
{
    public var xmod: ModifierValue = 1;
    public var cmod: ModifierValue = 0;

    public var absolutecmod: ModifierBool = false;
    public var movepastreceptors: ModifierBool = false;
}

class ModManager 
{
    public var playerCount(default, set): Int = 2;
    function set_playerCount(val: Int){
        for(mod in modifiers){
            if(mod.values.length < val){
                for(i in mod.values.length...val){
                    mod.addNewValues();
                }
            }
        }

        return playerCount = val;
    }

    public var globals: GlobalValues;

    public static var modifiersToAdd: Array<Class<Modifier>>;
    
    var timeline: EventTimeline;

    var modifiers: Array<Modifier> = []; // All modifiers that affect notes
    var auxModifiers: Array<Modifier> = []; // Auxilary modifiers (they only store values)

    var modifierValues: Map<String, ModifierValueInfo> = [];
    var nodes: Array<Node> = [];

    public var workingPlayer: Int = 0;
    public var workingColumn: Int = 0;

    function getInstance(inputCls:Class<Modifier>) 
    { // taken from Srt snce its kind of important and theres not many better ways anyway
		for (mod in modifiers) {
			if (Std.isOfType(mod, inputCls))
				return mod;
		}
		return addModifier(Type.createInstance(inputCls, [this]));
	}

    public function new() 
    {
        timeline = new EventTimeline();

        for(mod in modifiersToAdd)
            getInstance(mod);

        globals = cast getInstance(GlobalValues);

    }

    public function addAux(name: String, value: Float) 
    {
        var aux: AuxModifier = new AuxModifier(this, name, value);
        auxModifiers.push(aux);
        
        modifierValues.set(name, {
            instance: aux,
            valueName: "value"
        });

        for(i in aux.values.length...playerCount)
            aux.addNewValues();

        return aux;
    }

    public function addModifier(modifier: Modifier)
    {
        if(!modifiers.contains(modifier)){
            var i = modifiers.length;
            while (i > 0 && modifiers[i - 1].priority > modifier.priority)
                --i;
            
            modifiers.insert(i, modifier);
        }

        for(name => valueName in modifier.getValueInfo()){
            modifierValues.set(name, {
                instance: modifier,
                valueName: valueName
            });
        }

        for(i in modifier.values.length...playerCount)
            modifier.addNewValues();

        return modifier;
    }

    public function getDistance(time: Float, currentTime: Float){
       return (time - currentTime) * 0.45;
    }

    inline function callOnActive(pN: Int, callback: Modifier -> Void)
    {
        for(mod in modifiers){
            if(!mod.finalizedActive[pN])continue;
            callback(mod);
        }
    }

    public function modifyDistance(params: ModifierParams, speed: Float = 1)
    {
        workingColumn = params.column;
        workingPlayer = params.playerNumber;

        final cmod = globals.cmod;
        if(cmod != 0 || globals.absolutecmod)
            speed = cmod;   
        
        if(!globals.movepastreceptors && params.distance < 0){
            params.distance *= speed * globals.xmod;
            return;
        }

        callOnActive(workingPlayer, mod -> mod.modifyDistance(params));

        params.distance *= speed * globals.xmod;
    }
    
    public function getPos(params: ModifierParams)
    {
        params.pos.x = 75 * (params.column - (4 - 1) * 0.5); //(column * 75) - (75 * 3) * 0.5;
        params.pos.y = (Main.PLAYER_HEIGHT / 2) - params.distance;
        params.pos.z = 0;
        
        workingPlayer = params.playerNumber;
        workingColumn = params.column;

        callOnActive(workingPlayer, mod -> mod.modifyPos(params));

        return params.pos;
    }


    inline function validateModifier(modName: String)
    {
        var modifierInfo: ModifierValueInfo = modifierValues.get(modName.toLowerCase());

        if(modifierInfo == null){
            trace('$modName does not have an associated modifier!');
            return null;
        }

        var modifier: Modifier = modifierInfo.instance;
        if(modifier == null){
            trace('${modName}\'s modifier hasn\'t loaded!');
            return null;
        }

        trace(modName, modifierInfo.valueName);
        return modifierInfo;
    }

    public function queueEase(step:Float, endStep:Float, modName:String, target:Float, style:EasingFunc, player:Int = -1, ?startVal:Float)
    {
        var modifierInfo: ModifierValueInfo = validateModifier(modName);
        if(modifierInfo == null)return;
        var modifier: Modifier = modifierInfo.instance;
        var valueName: String = modifierInfo.valueName;

		if (player == -1)
			for (pN in 0...modifier.values.length)
				timeline.add(new ModEvent(modifier, valueName, step, target, pN, endStep, style));
		else
			timeline.add(new ModEvent(modifier, valueName, step, target, player, endStep, style));
    }
    
    public function queueSet(step:Float, modName:String, target:Float, player:Int = -1, ?startVal:Float)
    {
        var modifierInfo: ModifierValueInfo = validateModifier(modName);
        if(modifierInfo == null)return;
        var modifier: Modifier = modifierInfo.instance;
        var valueName: String = modifierInfo.valueName;

		if (player == -1)
			for (pN in 0...modifier.values.length)
				timeline.add(new ModEvent(modifier, valueName, step, target, pN));
		else
			timeline.add(new ModEvent(modifier, valueName, step, target, player));
    }

    public function setValue(modName: String, target: Float, player:Int = -1)
    {
        var modifierInfo: ModifierValueInfo = validateModifier(modName);
        if(modifierInfo == null)return;

        modifierInfo.set(target, player);
    }

    public function getValue(modName: String, player:Int = -1): Float
    {
        var modifierInfo: ModifierValueInfo = validateModifier(modName);
        if(modifierInfo == null)return 0;
        return modifierInfo.get(player);
    }

    public function setCurrentValue(modName: String, target: Float, player:Int = -1)
    {
        var modifierInfo: ModifierValueInfo = validateModifier(modName);
        if(modifierInfo == null)return;
        var modifier: Modifier = modifierInfo.instance;
        var valueName: String = modifierInfo.valueName;

        modifier.setCurrentValue(valueName, target, player);
    }

    public function getTargetValue(modName: String, player:Int = -1): Float
    {
        var modifierInfo: ModifierValueInfo = validateModifier(modName);
        if(modifierInfo == null)return 0;
        var modifier: Modifier = modifierInfo.instance;
        var valueName: String = modifierInfo.valueName;

        return modifier.getTargetValue(valueName, player);
    }


    public function makeNode(inputs: Array<String>, callback: NodeCallback, outputs: Array<String>)
    {
        var modifierInputs: Array<ModifierValueInfo> = [];
        var modifierOutputs: Array<ModifierValueInfo> = [];
        for(inputName in inputs){
            var modifierInfo: ModifierValueInfo = validateModifier(inputName);

            if(modifierInfo == null)
                trace(inputName + " is not a valid modifier for Node input");
            else
                modifierInputs.push(modifierInfo);
        }

        for(outputName in outputs){
            var modifierInfo: ModifierValueInfo = validateModifier(outputName);
            
            if(modifierInfo == null)
                trace(outputName + " is not a valid modifier for Node output");
            else
                modifierOutputs.push(modifierInfo);
        }

        var node: Node = {
            inputs: modifierInputs,
            outputs: modifierOutputs,
            callback: callback
        }

        nodes.push(node);
        
        return node;
    }


    public function update(dt: Float)
    {
        timeline.updateEvents();

        for(mod in modifiers)
            mod.reset();
        
        for(mod in auxModifiers)
            mod.reset();

        for(node in nodes)
        {
            for(pn in 0...playerCount){
                var isRunning = false;
                var inputValues: Array<Float> = [];
                for(input in node.inputs)
                {
                    isRunning = isRunning || input.instance.active[pn];
                    inputValues.push(input.get(pn));
                }


                if(!isRunning)continue;

                var outputValues: Array<Float> = node.callback(inputValues, pn);
                if(outputValues.length < node.outputs.length)
                    outputValues.resize(node.outputs.length);

                for(idx in 0...node.outputs.length){
                    var modifierInfo: ModifierValueInfo = node.outputs[idx];
                    var value: Float = outputValues[idx];

                    if(node.inputs.contains(modifierInfo))
                        modifierInfo.instance.setCurrentValue(modifierInfo.valueName, value, pn);
                    else 
                        modifierInfo.instance.setCurrentValue(modifierInfo.valueName, modifierInfo.get(pn) + value, pn);
                }
                
            }
        }

        // might be replaced with a .prepare, similar to what N2X has
        for(pN in 0...playerCount){
            for(mod in modifiers){
                if(!mod.finalizedActive[pN])continue;

                mod.update(pN, dt);
            }
        }
        
        
    }
}