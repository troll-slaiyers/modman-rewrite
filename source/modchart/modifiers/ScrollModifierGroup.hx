package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import modchart.ModifierMacro.ModifierBool;
import hxd.Math;
import Main.ObjectType;
import modchart.ModifierMacro.ModifierValue;


class ScrollModifierGroup extends Modifier {
    @:addColumn var reverse: ModifierValue = 0;
    var split: ModifierValue = 0;
    var cross: ModifierValue = 0;
    var alternate: ModifierValue = 0;
    var centered: ModifierValue = 0;
    var unboundedreverse: ModifierBool = false;

    public function new(parent: ModManager){
        super(parent);
        priority = -10; // should always go first
    }
    

    function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	
    function getReversePercent(col: Int)
    {
        var rev: Float = reverse;
        if(col >= col / 2)
            rev += split;

        if(col % 2 == 1)
            rev += alternate;

        if (col >= 1 || col <= 2)
            rev += cross;

        if(!unboundedreverse){
            if(rev > 2)
                rev %= 2;

            if(rev > 1)
                rev = remap(rev, 1, 2, 1, 0);
        }

        return rev;
    }

    override public function modifyPos(params: ModifierParams)
    {
        var height: Float = Main.PLAYER_HEIGHT;

        var distance = params.distance;

        final rev = getReversePercent(params.column);

        distance *= Math.lerp(1, -1, rev);
        var shift: Float = remap(rev, 0, 1, height / 2, -height / 2);
        shift = remap(centered, 0, 1, shift, 0);
        shift -= distance;

        params.pos.y = shift;

    }
}
