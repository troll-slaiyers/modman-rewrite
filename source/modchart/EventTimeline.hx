package modchart;

import haxe.Exception;
import modchart.events.BaseEvent;


class EventTimeline {
    var eventIdx: Int = 0;
    var queue: Array<BaseEvent> = [];
    var active: Array<BaseEvent> = [];

    public function new(){}

    public function add(event: BaseEvent){
        // stole from srt, just puts the event where it should be instead of sorting the entire array
        var i = queue.length;
        while (i > 0 && queue[i - 1].step > event.step)
            --i;
		
        queue.insert(i, event);
    }

    public function updateEvents(){
        while(eventIdx < queue.length && queue.length > 0 && queue[eventIdx].step <= Conductor.step){
            var ev: BaseEvent = queue[eventIdx];
            try {
                ev.run();
            }catch(e: Exception){
                trace('Event ${ev} errored out in \'run\'!\n${e}');
                ev.continuous = false;
            }

            if(ev.continuous)
                active.push(ev);

            eventIdx++;
        }

        var garbage: Array<BaseEvent> = [];
        for(i in 0...active.length){
            var activeEvent: BaseEvent = active[i];
            try {
                activeEvent.tick(Conductor.step);
            }catch(e: Exception){
                trace('Event ${activeEvent} errored out in \'tick\'!\n${e}');
                activeEvent.continuous = false;
                activeEvent.finished = true;
            }
            if(activeEvent.finished)
                garbage.push(activeEvent);
        }

        for(ev in garbage)active.remove(ev);
    }
}