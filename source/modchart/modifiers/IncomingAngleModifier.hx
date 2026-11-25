package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import hxd.Math;

class IncomingAngleModifier extends Modifier
{
    public function new(parent: ModManager){
        super(parent);
        priority = 10; // should always go last
    }
    

    @:addColumn var incomingangle: ModifierValue = 0;

    override public function modifyPos(params: ModifierParams)
    {
        if(params.objectType == RECEPTOR)return;

        final pos = params.pos;
        final column = params.column;

        final angle = Math.degToRad(incomingangle);
        
        pos.x -= Main.receptors[column].params.pos.x;
        pos.y -= Main.receptors[column].params.pos.y;
        pos.z -= Main.receptors[column].params.pos.z;

        var point = pos.to2D();
        point.rotate(angle);
        
        pos.x = point.x;
        pos.y = point.y;

        pos.x += Main.receptors[column].params.pos.x;
        pos.y += Main.receptors[column].params.pos.y;
        pos.z += Main.receptors[column].params.pos.z;
    }
}