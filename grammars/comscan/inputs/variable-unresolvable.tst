import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { ret = mainRet };
}

actor Tst() : Go -> ret: RetCode { 

    control { int x; bool y; string z; }
    init { 
      x = 1;
      y = true; 
      z = "hi"; 
    }

    handler Go (e) {
    
      int a = 1;
      bool b = true;
      string c = "hi";
      Go d = Go with {};

      f = true;
    
    }

}
