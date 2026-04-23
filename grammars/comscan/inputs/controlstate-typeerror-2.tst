import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { ret = mainRet };
}

actor Tst() : Go -> ret: RetCode { 

    control { int x; bool y; string z; }
    init { 
      x = 1 + true;
      y = true & "hi"; 
      z = "hi" ++ true;
    }

    handler Go (e) {}

}
