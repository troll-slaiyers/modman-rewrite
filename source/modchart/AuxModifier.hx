package modchart;

@:base
class AuxModifier extends Modifier
{
    var name: String = '';
    var def: Float = 0;

    public function new(parent: ModManager, name: String, def: Float)
    {
        super(parent);
        this.name = name;
        this.def = def;
    }
    
    override function reset(){
        for(pN in 0...values.length){
            var playerValues: Map<String, Float> = values[pN];
            finalizedValues[pN].set("value", playerValues.get("value"));
        }

        finalizedActive = active.copy();
    }

    override function addNewValues()
    {
        values.push([
            "value" => def
        ]);

        finalizedValues.push([
            "value" => def
        ]);

        active.push(false);
        finalizedActive.push(false);
    }

    override function isActive(values: Map<String, Float>)
        return values.get("value") != def;
}