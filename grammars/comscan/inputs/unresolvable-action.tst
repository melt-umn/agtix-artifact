import "events.tst";

event Go {};

actor Main() : * -> mainRet: RetCode; start = tst {
  Tst tst() with { ret = mainRet };
}

actor Tst() : Go -> ret: RetCode { 

    control {}
    init {}

    handler Go (e) {
      nonexistantAction();
    }

}
