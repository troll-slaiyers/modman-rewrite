package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import modchart.ModifierMacro.ModifierValue;

class ExpandModifier extends Modifier
{
    @:addColumn var expand: ModifierValue = 0;
    var expandperiod: ModifierValue = 0;

    function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	

    public override function modifyDistance(params: ModifierParams)
    {                  
        if(expand != 0){
            var expandSeconds: Float = (Conductor.time / 1000) % ((Math.PI * 2) / (expandperiod + 1));
            var mult = remap(
                Math.cos(expandSeconds * (3 * (expandperiod + 1))),
                -1, 1,
                0.75, 1.75
            );

            params.distance *= remap(expand, 0, 1, 1, mult);
        }
    }
}