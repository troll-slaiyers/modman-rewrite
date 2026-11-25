package modchart;

import modchart.ModManager.ModifierParams;
import Main.ObjectType;
import h3d.Vector as Vector3;

@:structInit class RenderInfo
{
    public var alpha: Float = 1;
    public var flashColor: Int = 0x00FFFFFF; // TODO: flxcolor
    public var rotation: Vector3 = new Vector3(0, 0, 0); // this will be replaced by modifyVert when we flixelize this
}

@:keep
@:autoBuild(modchart.ModifierMacro.build())
class Modifier {
    #if true // Mostly internal variables
    var prefix: String = '';
    public var parent: ModManager; // Where the modifier is from
    public var values: Array<Map<String, Float>> = []; // Target values
    public var active: Array<Bool> = []; // If this modifier *will be* active for a specific player
    public var finalizedValues: Array<Map<String, Float>> = []; // Final values after nodes etc
    public var finalizedActive: Array<Bool> = []; // If this modifier is *currently* active for a specific player
    #end
    
    public var priority: Int = 0; // Sets where the mod exists in the list
    public function new(parent: ModManager) 
    {
        this.parent = parent;
    }


    #if true // Stubs you should be replacing in your modifiers if required
    public function modifyPos(params: ModifierParams){}
    public function modifyScale(time: Float, beat: Float, distance: Float, scale: Vector3, column: Int, player: Int, objectType: ObjectType){}
    public function modifyRenderInfo(time: Float, beat: Float, distance: Float, unmodifiedDistance: Float, renderInfo: RenderInfo, column: Int, player: Int, objectType: ObjectType){}
    public function modifyDistance(params: ModifierParams){}
    public function update(pN: Int, deltaTime:Float){}
    #end

    #if true // Code usually handled by the macro, but can be modified on your own if you prefer or if you're doing weird stuff
    public function getValueInfo(): Map<String, String>
    {
        return [];
    }

    public function addNewValues() {
        active.push(false);
        finalizedActive.push(false);

        values.push([]);
        finalizedValues.push([]);
    }

    public function isActive(values: Map<String, Float>){
        for(_ => val in values){
            if(val != 0.0)
                return true;
        }
        return false;
    }
    #end

    #if true // Code for getting values etc, you shouldn't touch these unless necessary
    public function reset(){
        for(pN in 0...values.length){
            var playerValues: Map<String, Float> = values[pN];
            for(k => v in playerValues)
                finalizedValues[pN].set(k, v);   
        }

        finalizedActive = active.copy();
    }

    public function getValue(name: String, pN: Int): Float
    {
        if(pN >= finalizedValues.length)return 0;
        return finalizedValues[pN].get(name);
    }
    
    public function getTargetValue(name: String, pN: Int): Float
    {
        if(pN >= values.length)return 0;
        return values[pN].get(name);
    }

    public function setValue(name: String, value: Float, pN: Int = -1)
    {
        if(pN == -1){
            for(i in 0...values.length)
                setValue(name, value, i);
            
        } else {
            if(pN < values.length){
                if(values[pN].exists(name))
                    values[pN].set(name, value);
                
            }
            active[pN] = isActive(values[pN]); 
        }
    }

    public function setCurrentValue(name: String, value: Float, pN: Int = -1)
    {
        if(pN == -1){
            for(i in 0...finalizedValues.length)
                setCurrentValue(name, value, i);
            
        } else {
            if(pN < finalizedValues.length){
                if(finalizedValues[pN].exists(name))
                    finalizedValues[pN].set(name, value);
            }
            finalizedActive[pN] = isActive(finalizedValues[pN]); 
        }
    }
    #end
}