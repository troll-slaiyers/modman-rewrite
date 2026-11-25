package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import Main.ObjectType;

class BumpyModifier extends Modifier {

    @:addColumn var bumpyx: ModifierValue = 0;
    var bumpyxperiod: ModifierValue = 0;
    var bumpyxoffset: ModifierValue = 0;

    @:addColumn var bumpyy: ModifierValue = 0;
    var bumpyyperiod: ModifierValue = 0;
    var bumpyyoffset: ModifierValue = 0;

    @:alias("tipz") @:addColumn var bumpy: ModifierValue = 0;
    var bumpyperiod: ModifierValue = 0;
    var bumpyoffset: ModifierValue = 0;


    override public function modifyPos(params: ModifierParams)
    {        
        final distance = params.distance;
        final pos = params.pos;
        
        pos.x += bumpyx * Math.sin((distance + (100.0 * bumpyxoffset)) / ((bumpyxperiod * 24.0) + 24.0)) * 40;
        pos.y += bumpyy * Math.sin((distance + (100.0 * bumpyyoffset)) / ((bumpyyperiod * 24.0) + 24.0)) * 40;
        pos.z += bumpy * Math.sin((distance + (100.0 * bumpyoffset)) / ((bumpyperiod * 24.0) + 24.0)) * 40;
    }
}