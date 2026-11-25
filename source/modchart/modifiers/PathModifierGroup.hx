package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import modchart.ModifierMacro.ModifierValue;

class PathModifierGroup extends Modifier 
{
    @:alias("attenuate") var attenuatex: ModifierValue = 0;
    var attenuatey: ModifierValue = 0;
    var attenuatez: ModifierValue = 0;
    var attenuateoffset: ModifierValue = 0;

    @:addColumn var xmode: ModifierValue = 0;

    override public function modifyPos(params: ModifierParams)
    {
        final usedDistance: Float = params.distance;
        final column: Int = params.column;
        final pos = params.pos;
        final player = params.playerNumber;

        final xOffset = 75 * (column - (4 - 1) * 0.5);
        final attenuateFactor:Float = (attenuateoffset + usedDistance) / 75;
		pos.x += attenuatex * attenuateFactor * attenuateFactor * (xOffset / 75);
		pos.x += attenuatey * attenuateFactor * attenuateFactor * (xOffset / 75);
        pos.x += attenuatez * attenuateFactor * attenuateFactor * (xOffset / 75);

        if(player % 2 == 1)
            pos.x += xmode * usedDistance;
        else 
            pos.x -= xmode * usedDistance;
		

    }
}