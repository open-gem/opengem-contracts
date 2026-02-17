import "../../traits/utils/counter.tact";

contract CounterImp with Counter {
    counter: Int;
    init(){
        self.counter = 0;
    }

    receive("increment"){
        self.increment();
    }

    receive("decrement"){
        self.decrement();
    }

    receive("current"){
        self.current();
    }
}