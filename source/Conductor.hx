package;


// I hate time signatures it turns out
@:structInit
class TimeSegment {
	public var time:Float = 0;
	public var bpm:Float = 60;

	public var startBeat:Float = 0;
	public var startStep:Float = 0;
	public var startMeasure:Float = 0;

	// Time signatures are expressed as measureNotes / notation
	// A measure should have measureNotes notations (i.e 3/8 means each measure is 3 8ths)
	// Notation is effectively speed then
	public var measureNotes:Float = 4;
	public var notation:Float = 4;

	public function getBeatLength() {
		return ((60 / bpm) * (4 / notation)) * 1000;
	}

	public function getStepLength() {
		return (60 / bpm) * 0.25 * 1000;
	}

	public function getMeasureLength() {
		return getBeatLength() * measureNotes;
	}

	public function getBeat(at:Float) {
		return startBeat + (at - time) / getBeatLength();
	}

	public function getStep(at:Float) {
		return startStep + (at - time) / getStepLength();
	}

	public function getMeasure(at:Float) {
		return startMeasure + (at - time) / getMeasureLength();
	}

	public function toString(){
		return 'Time: $time | BPM: $bpm | Time Sig: $measureNotes/$notation | Start Beat: $startBeat | Start Measure: $startMeasure | Start Step: $startStep';
	}
}

typedef BeatInfo = { // Returned by getBeatInfo
	beat: Float,
	step: Float,
	measure: Float,
	segment: TimeSegment
}

// TODO: The Great Member
class Conductor {
	
	// These should be moved away -Neb
	private inline static final _internalJackLimit:Float = 192 / 16;
	public inline static final ROWS_PER_BEAT:Int = 48;

	public static var timeSegments(default, set): Array<TimeSegment> = [];
	@:noCompletion inline static function set_timeSegments(value: Array<TimeSegment>){
		value.sort((a,b) -> return Std.int(a.time - b.time));
		return timeSegments = value;
	}
	
	static var beatInfo: BeatInfo = {beat: 0, step: 0, measure: 0, segment: null};
	
	public static var time: Float = 0;

	@:isVar public static var beat(get, null): Float;
	@:noCompletion inline static function get_beat()
		return beatInfo.beat;

	@:isVar public static var step(get, null): Float;
	@:noCompletion inline static function get_step()
		return beatInfo.step;

	@:isVar public static var measure(get, null): Float;
	@:noCompletion inline static function get_measure()
		return beatInfo.measure;

	public static var roundedStep: Int = 0;
	public static var roundedBeat: Int = 0;
	public static var roundedMeasure: Int = 0;	


	public static var offset:Float = 0;

	
	// If we need speed we can binary search! But for now who gaf
	// This *should* be sorted
	public static function getSegmentFromTime(time: Float): TimeSegment 
	{
		if(timeSegments.length == 0)return {};
		if(timeSegments.length == 1)return timeSegments[0];

		var seg: TimeSegment = timeSegments[0];
		for (segment in timeSegments){
			if(segment.time <= time)
				seg = segment;
			else if(segment.time > time)
				return seg;
		}

		return seg;
	}

	public static function getSegmentFromBeat(beat:Float):TimeSegment {
		if(timeSegments.length == 0)return {};
		if(timeSegments.length == 1)return timeSegments[0];

		var seg: TimeSegment = timeSegments[0];
		for (segment in timeSegments){
			if(segment.startBeat <= beat)
				seg = segment;
			else if(segment.startBeat > beat)
				return seg;
		}

		return seg;
	}

	public static function getBeatInfoFromTime(time: Float, ?existingInfo:BeatInfo): BeatInfo{
		var seg: TimeSegment = getSegmentFromTime(time);
		var info: BeatInfo = existingInfo != null ? existingInfo : {
			beat: 0,
			measure: 0,
			step: 0,
			segment: seg
		}

		info.beat = seg.getBeat(time);
		info.measure = seg.getMeasure(time);
		info.step = seg.getStep(time);

		return info;

	}
	
	public static function updateTime(time:Float){		
		beatInfo = getBeatInfoFromTime(time, beatInfo);
		
		
		if(Math.floor(beatInfo.measure) != roundedMeasure){
			roundedMeasure = Math.floor(beatInfo.measure);
		}

		if(Math.floor(beatInfo.beat) != roundedBeat){
			roundedBeat = Math.floor(beatInfo.beat);
		}

		if(Math.floor(beatInfo.step) != roundedStep){
			roundedStep = Math.floor(beatInfo.step);
		}

	}

	public static function getRows(beat: Float){
		return ROWS_PER_BEAT * getSegmentFromBeat(beat).measureNotes;
	}

	public static function finalizeTimeSegments(){
		for(i in 1...timeSegments.length){
			var segment: TimeSegment = timeSegments[i];
			var lastSegment: TimeSegment = timeSegments[i - 1];

			segment.startStep = lastSegment.getStep(segment.time);
			segment.startBeat =  lastSegment.getBeat(segment.time);
			segment.startMeasure =  lastSegment.getMeasure(segment.time);
		}
	}

	public static function mapTimeSegments(){
		// TODO: load time segments from a file
		timeSegments = [
			{
				time: 0,
				bpm: 120
			}
		];

		finalizeTimeSegments();
	}

}
