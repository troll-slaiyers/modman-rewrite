package modchart.modifiers;

import modchart.ModifierMacro.ModifierSubValue;
import modchart.ModManager.ModifierParams;
import modchart.ModifierMacro.ModifierValue;

@:base
class BeatModifier extends Modifier 
{
    var beatFactors:Array<Float> = [];

    function remap(value:Float, start1:Float, stop1:Float, start2:Float, stop2:Float):Float
        return start2 + (value - start1) * ((stop2 - start2) / (stop1 - start1));
	

    function updateBeat(pn: Int, beat:Float, offset:Float, mult:Float, accel: Float, total: Float, alternatecount: Float, alternatemarker: Float)
    {
        if(Math.isNaN(beatFactors[pn]))
            beatFactors[pn] = 0;

        if(alternatecount <= 0){
            beatFactors[pn] = 0;
            return;
        }


		var accelTime:Float = accel;
		var totalTime:Float = total;

		var beat = (beat + accelTime + offset) * (mult + 1);
		var evenBeat = Std.int(beat / alternatecount) % Math.floor(alternatemarker) != 0;

		if (beat < 0){
            beatFactors[pn] = 0;
            return;
        }

		beat %= 1;
		
		if (beat >= totalTime){
            beatFactors[pn] = 0;
            return;
        }

		var amount:Float = 0;
		if (beat < accelTime)
		{
			amount = remap(beat, 0, accelTime, 0, 1);
			amount *= amount;
		}
		else
		{
			amount = remap(beat, accelTime, totalTime, 1, 0);
			amount = 1 - (1 - amount) * (1 - amount);
		}

		if (evenBeat)
			amount *= -1;

		beatFactors[pn] = 40 * amount;
	}

}

class BeatXModifier extends BeatModifier
{
    @:addColumn @:alias("beatx", "beatx%c") var beat: ModifierValue = 0; // Th  e main modifier value
    var beatoffset: ModifierSubValue = 0; // Offsets the beat shifting
    var beatmult: ModifierSubValue = 0; // Speeds up / slows down the shifting
    var beatperiod: ModifierSubValue = 0; // Adjusts how the notes bump when it shifts
    var beataccel: ModifierSubValue = 0.2; // The time it takes to hit the bump
    var beattotal: ModifierSubValue = 0.5; // The total time the bump takes. Over 1.0, it looks weird and never hits the end of the bump.
    var beatalternatecount: ModifierSubValue = 1; // How many bumps happen before an alternation (so 2 means it bumps twice before alternating)
    var everybeat: ModifierSubValue = 2; // When does the bump alternate (2 means it'll alternate on every even beat, 3 means on every 3rd beat, etc)

    override function update(pN: Int, elapsed:Float){
		
        updateBeat(pN, Conductor.beat, beatoffset, beatmult, beataccel, beattotal, beatalternatecount, everybeat);

    }
    override function modifyPos(params: ModifierParams)
    {
        final pn = params.playerNumber;
        final distance = params.distance;

		params.pos.x += beat * (beatFactors[pn] * Math.sin((distance / ((beatperiod * 30) + 30)) + Math.PI * 0.5));
    }
}

class BeatYModifier extends BeatModifier
{
    @:addColumn var beaty: ModifierValue = 0;
    var beatyoffset: ModifierSubValue = 0;
    var beatymult: ModifierSubValue = 0;
    var beatyperiod: ModifierSubValue = 0;
    var beatyaccel: ModifierSubValue = 0.2;
    var beatytotal: ModifierSubValue = 0.5;
    var beatyalternatecount: ModifierSubValue = 1;
    var everybeaty: ModifierSubValue = 2;

    override function update(pN: Int, elapsed:Float)
		updateBeat(pN, Conductor.beat, beatyoffset, beatymult, beatyaccel, beatytotal, beatyalternatecount, everybeaty);

    override function modifyPos(params: ModifierParams)
    {
        final pn = params.playerNumber;
        final distance = params.distance;

		params.pos.y += beaty * (beatFactors[pn] * Math.sin((distance / ((beatyperiod * 30) + 30)) + Math.PI * 0.5));
    }
}

class BeatZModifier extends BeatModifier
{
    @:addColumn var beatz: ModifierValue = 0;
    var beatzoffset: ModifierSubValue = 0;
    var beatzmult: ModifierSubValue = 0;
    var beatzperiod: ModifierSubValue = 0;
    var beatzaccel: ModifierSubValue = 0.2;
    var beatztotal: ModifierSubValue = 0.5;
    var beatzalternatecount: ModifierSubValue = 1;
    var everybeatz: ModifierSubValue = 2;

    override function update(pN: Int, elapsed:Float)
		updateBeat(pN, Conductor.beat, beatzoffset, beatzmult, beatzaccel, beatztotal, beatzalternatecount, everybeatz);

    override function modifyPos(params: ModifierParams)
    {
        final pn = params.playerNumber;
        final distance = params.distance;

		params.pos.z += beatz * (beatFactors[pn] * Math.sin((distance / ((beatzperiod * 30) + 30)) + Math.PI * 0.5));
    }
}