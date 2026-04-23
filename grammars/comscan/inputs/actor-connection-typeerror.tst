import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { receiver = tst2, ret = mainRet };
  Tst2 tst2() with {};
}

actor Tst() : Go -> receiver:Go, ret: RetCode { 

    control { int x; bool y; string z; }
    init { 
      x = 1;
      y = true; 
      z = "hi"; 
    }

    handler Go (e) {}

}

actor Tst2(): Integer -> {

  handler Integer(e) {}

}
