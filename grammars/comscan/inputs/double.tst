import "events.tst";
import "stdio.tst";

event DoneEvent {};

actor Main() : * -> mainRet: RetCode; start = sender {
  Sender  sender()  with { receiver = doubler, doneSending = doubler };
  Doubler doubler() with { receiver = checker, doneSending = checker };
  Checker checker() with { receiver = mainRet };
}


actor Doubler() : Integer | DoneEvent -> 
  receiver: Integer, doneSending: DoneEvent {
        
    control { int numDoubled; }
    init { numDoubled = 0; }

    handler Integer (e) {
      print("Doubler received Integer event with value " ++ toString(e.value) ++ "\n");
      e.value = e.value * 2;
      print("\tDoubler sending Integer event with value " ++ toString(e.value) ++ "\n");
      updateNum();
      trigger e for receiver;
    }

    handler DoneEvent (e) {
      print("Doubler received DoneEvent after doubling " ++ toString(numDoubled) ++ " numbers \n");
      trigger e for doneSending;
      print("\tDoubler sending DoneEvent\n");
    }

    action updateNum() {
      numDoubled = numDoubled + 1;
    }

}


actor Sender() : Integer -> receiver: Integer, doneSending: DoneEvent {

  control { }

  init {

    print("===================================\n");
    print("===== Double program starting =====\n");

    Integer first = Integer with { value = 2 };
    Integer second = Integer with { value = 3 };

    trigger first for receiver;
    trigger second for receiver;

    DoneEvent done = DoneEvent with {};
    trigger done for doneSending;

  }

  handler Integer(e) {}

}


actor Checker() : Integer | DoneEvent -> receiver: RetCode {

  control { bool passed; }
  init { passed = true; }

  handler Integer (e) {  // or all as handlers
    print("Checker received Integer e with value " ++ toString(e.value) ++ "\n");
    if (e.value % 2 != 0) {
      print("\tValue was not even, failed\n");
      updatePassed(false);
    } else {
      print("\tValue was even, passed\n");
    }
  }

  handler DoneEvent (e) {
    print("Checker received DoneEvent\n");
    int resCode;
    if (passed) {
      print("\tAll tests passed\n");
      resCode = 0;
    }
    else {
      print("\tTesting failed\n");
      resCode = -1;
    }
    RetCode ret = RetCode with { code = resCode };
    trigger ret for receiver;

    print("===== Double program complete =====\n");
    print("===================================\n");
  }

  action updatePassed (bool result) {
    print("\tUpdating passed...\n");
    passed = passed && result;
  }

}
