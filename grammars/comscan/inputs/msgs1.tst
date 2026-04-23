import "events.tst";

event M1 { int a; int b; };
event M2 extends M1 with { int c; int d; };
event M3 extends M1 with { int e; };

actor Main(): * -> mainRet: RetCode; start = tester {
  Tester tester with { receiver = a, done = mainRet };
  A a with { connectB = b };
  B b with { connectA = a, next = tester };  
}

actor A() : M1|M2 -> connectB: M2|M3 {

    control {}

    handler M1 (e) { 
      trigger M2 with { a = e.a, b = e.b, c = e.a, d = e.b } for connectB;
    }

    handler M2 (e) { 
      trigger M3 with { a = e.a, e = e.c * e.d, b = e.b } for connectB;
    }
}

actor B() : M2|M3 -> connectA: M2, next: M3 {
    
    control {}
    init {}

    handler M2 (e) {
      trigger M2 with { a = 1, b = 2, c = e.d, d = e.c } for connectA;
    }

    handler M3 (e) {
      e.e = e.e * 2;
      trigger e for next;
    }

}

actor Tester() : M3 -> receiver: M1|M2, done: RetCode {

  control { int receivedBack; int expectedBack; }

  init {

    M1 first  = M1 with { a = 1, b = 1 };
    M2 second = M2 with { a = 1, b = 1, c = 0, d = 0 };

    trigger first  for receiver;
    trigger second for receiver;

    receivedBack = 0;
    expectedBack = 2;

  }

  handler M3 (e) {
    incrementReceived();
  }

  action incrementReceived () {
    receivedBack = receivedBack + 1;
    if (receivedBack == expectedBack)
      trigger (RetCode with {code = 0}) for done;
  }

}
