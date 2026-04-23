import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { ret = mainRet };
}

event Foo { int a; };
event Bar extends Baz with { int b; };

actor Tst() : Go -> ret: RetCode { 

    control { int x; bool y; string z; }
    init { 
      x = 1;
      y = true; 
      z = "hi"; 
    }

    handler Go (e) {}

}
