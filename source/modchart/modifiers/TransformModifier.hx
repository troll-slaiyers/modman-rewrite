package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import modchart.ModifierMacro.ModifierValue;
import Main.ObjectType;

class TransformModifier extends Modifier 
{
    @:addColumn @:alias("transform%cx") var transformx: ModifierValue = 0;
    @:addColumn @:alias("transform%cy") var transformy: ModifierValue = 0;
    @:addColumn @:alias("transform%cz") var transformz: ModifierValue = 0;

    @:addColumn @:alias("transformreceptor%cx") var transformreceptorx: ModifierValue = 0;
    @:addColumn @:alias("transformreceptor%cy") var transformreceptory: ModifierValue = 0;
    @:addColumn @:alias("transformreceptor%cz") var transformreceptorz: ModifierValue = 0;

    @:addColumn var movex: ModifierValue = 0;
    @:addColumn var movey: ModifierValue = 0;
    @:addColumn var movez: ModifierValue = 0;
    
    @:addColumn var moverx: ModifierValue = 0;
    @:addColumn var movery: ModifierValue = 0;
    @:addColumn var moverz: ModifierValue = 0;

    var flip: ModifierValue = 0;
    var invert: ModifierValue = 0;

    override public function modifyPos(params: ModifierParams)
    {
        final pos = params.pos;
        final column = params.column;
        final invertDistance: Float = Main.ARROW_SIZE * ((column % 2 == 0) ? 1 : -1);
        final flipDistance: Float = Main.ARROW_SIZE * 2 * (((4 - 1) * 0.5) - column); // TODO: change 4 to key count

        pos.x += transformx + (Main.ARROW_SIZE * movex) + (flip * flipDistance) + (invert * invertDistance);
        pos.y += transformy + (Main.ARROW_SIZE * movey);
        pos.z += transformz + (Main.ARROW_SIZE * movez);

        if(params.objectType == RECEPTOR){
            pos.x += transformreceptorx;
            pos.y += transformreceptory;
            pos.z += transformreceptorz;

            pos.x += Main.ARROW_SIZE * moverx;
            pos.y += Main.ARROW_SIZE * movery;
            pos.z += Main.ARROW_SIZE * moverz;
        }


        
    }

}