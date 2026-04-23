import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = hello {
  Hello hello() with { ret = mainRet };
}

actor Hello() : Go -> ret: RetCode { 
    control { }
    init { }
    handler Go (e) {
      print("Hello, world!\n");
      trigger RetCode with { code = 0 } for ret;
    }

}
