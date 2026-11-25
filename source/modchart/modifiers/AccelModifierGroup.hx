package modchart.modifiers;

import modchart.ModManager.ModifierParams;
import Main.ObjectType;
import modchart.ModifierMacro.ModifierValue;
import h3d.Engine;
import hxd.Math;
import modchart.ModifierMacro.ModifierBool;


// naming it this since it handles all acceleration modifiers
class AccelModifierGroup extends Modifier 
{
    public function new(parent: ModManager){
        super(parent);
        priority = -1;
    }

    @:addColumn var brake: ModifierValue = 0;
    @:addColumn var boost: ModifierValue = 0;
    @:addColumn var boomerang: ModifierValue = 0;
    @:addColumn var wave: ModifierValue = 0;
    @:addColumn var parabolay: ModifierValue = 0;

    var waveperiod: ModifierValue = 0;
    
    function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
		return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	
    public override function modifyDistance(params: ModifierParams)
    {
        final unmodifiedDistance = params.unmodifiedDistance;
        var distance = params.distance;
        
        final effectHeight: Float = Engine.getCurrent().height;

        final boost = boost; // cache value (we should absolutely cache this per-frame in the getter tbh)
        if(boost != 0){
            var off = unmodifiedDistance * 1.5 / ((unmodifiedDistance + effectHeight / 1.2) / effectHeight);
            distance += Math.clamp(boost * (off - unmodifiedDistance), -600, 600);
        }

        final brake = brake;
        if(brake != 0){
            var scale = remap(unmodifiedDistance, 0, effectHeight, 0, 1);
            var newDistance = unmodifiedDistance * scale;
            distance += Math.clamp(brake * (newDistance - unmodifiedDistance), -600, 600);
        }

        final wave = wave;
        if(wave != 0)
            distance += wave * 40 * Math.sin(unmodifiedDistance / (114 * (1 + waveperiod)));

        // I'd like this to be with the other parabola modifiers, but due to boomerang and wanting accuracy w/ ITG, it has to go here
        final parabolay = parabolay;
        if(parabolay != 0)
            distance += parabolay * (unmodifiedDistance / Main.ARROW_SIZE) * (unmodifiedDistance / Main.ARROW_SIZE);

        // if this has issues with drawing then we'll probably need to split this into a new modifier so we can get data from it without calling the whole-ass modifier
        // (or add a new struct for output variables from distance mods)
        // ((or super hardcode boomerang bullshit))
        final boomerang = boomerang;
        if(boomerang != 0)
            distance = boomerang * (-1*distance*distance/720) + 1.5*distance;
        
        params.distance = distance;
    }


}