package modchart.events;

class BaseEvent {
    public var step: Float = 0;
    public var continuous: Bool = false;
    public var finished: Bool = false;

    public function new(){
    }

    public function run(){} // ow! i stubbed my toe!
    public function tick(step:Float){} //ow! again!
    
}