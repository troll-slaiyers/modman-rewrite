package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import Main.ObjectType;

class TipsyModifier extends Modifier {
    @:addColumn var tipsyx: ModifierValue = 0;
    var tipsyxspeed: ModifierValue = 0;
    var tipsyxoffset: ModifierValue = 0;

    @:addColumn var tipsy: ModifierValue = 0;
    var tipsyspeed: ModifierValue = 0;
    var tipsyoffset: ModifierValue = 0;

    @:alias("tipz") @:addColumn var tipsyz: ModifierValue = 0;
    var tipsyzspeed: ModifierValue = 0;
    var tipsyzoffset: ModifierValue = 0;

    override public function modifyPos(params: ModifierParams)
    {
        final time = params.songTime;
        final pos = params.pos;
        final column = params.column;

        var sTime: Float = time * 0.001;
        
        pos.x += tipsyx * Math.cos((sTime * ((tipsyxspeed * 1.2) + 1.2) + column * ((tipsyxoffset * 1.8) + 1.8) )) * 64 * 0.4;
        pos.y += tipsy * Math.cos((sTime * ((tipsyspeed * 1.2) + 1.2) + column * ((tipsyoffset * 1.8) + 1.8) )) * 64 * 0.4;
        pos.z += tipsyz * Math.cos((sTime * ((tipsyzspeed * 1.2) + 1.2) + column * ((tipsyzoffset * 1.8) + 1.8) )) * 64 * 0.4;
        
    }
}