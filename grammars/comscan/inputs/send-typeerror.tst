import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { other = otherTst, ret = mainRet };
  Tst2 otherTst() with {};
}

actor Tst() : Go -> other: Integer, ret: RetCode { 

    control { int x; bool y; string z; }
    init { 
      x = 1;
      y = true; 
      z = "hi"; 
    }

    handler Go (e) {
    
      trigger Go with {} for other;
    
    }

}

actor Tst2(): Integer -> {

  control {}
  init {}

  handler Integer (e) {}

}