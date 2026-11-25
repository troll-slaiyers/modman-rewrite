package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import Main.ObjectType;

class DrunkModifier extends Modifier
{
    @:addColumn var drunk: ModifierValue = 0;
    var drunkspeed: ModifierSubValue = 0;
    var drunkperiod: ModifierSubValue = 0;
    var drunkoffset: ModifierSubValue = 0;

    @:addColumn var drunky: ModifierValue = 0;
    var drunkyspeed: ModifierSubValue = 0;
    var drunkyperiod: ModifierSubValue = 0;
    var drunkyoffset: ModifierSubValue = 0;

    @:addColumn var drunkz: ModifierValue = 0;
    var drunkzspeed: ModifierSubValue = 0;
    var drunkzperiod: ModifierSubValue = 0;
    var drunkzoffset: ModifierSubValue = 0;

    override public function modifyPos(params: ModifierParams)
    {
        final time = params.songTime;
        final column = params.column;
        final distance = params.distance;
        final pos = params.pos;

        var sTime: Float = time * 0.001;

        var anglex: Float = sTime * (1 + drunkspeed) + column * ((drunkoffset * 0.2) + 0.2) + distance * ((drunkperiod * 10) + 10) / 720;
        var angley: Float = sTime * (1 + drunkyspeed) + column * ((drunkyoffset * 0.2) + 0.2) + distance * ((drunkyperiod * 10) + 10) / 720;
        var anglez: Float = sTime * (1 + drunkzspeed) + column * ((drunkzoffset * 0.2) + 0.2) + distance * ((drunkzperiod * 10) + 10) / 720;

        pos.x += drunk * Math.cos(anglex) * 32;
        pos.y += drunky * Math.cos(angley) * 32;
        pos.z += drunkz * Math.cos(anglez) * 32;
    }
}