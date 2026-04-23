import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { ret = mainRet };
}

actor Tst() : Go -> ret: RetCode { 

    control { int x; bool y; string z; }
    init { 
      x = true;
      y = "hi"; 
      z = 1; 
    }

    handler Go (e) {}

}
