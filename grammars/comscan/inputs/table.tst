import "events.tst";
import "stdio.tst";

actor Main(): * -> mainRet: RetCode; start = sender {
  Tester t()  with { stdOut = stdOut, ret = mainRet };
  StdOut stdOut() with {};
}

actor Tester(): Integer -> stdOut: String, ret: RetCode {

  control {

    table<int, int> testTableInt default 32;

    table<int, string> testTableString default "foo";

    table<string, string> testTableString2 default "bar";

  }

  init {

    trigger String with { value = "----------\n" } for stdOut;

    trigger String with 
      { value = ("testTableInt[0]: " ++ toString(testTableInt[0]) ++ "\n") } for stdOut;

    trigger String with 
      { value = ("testTableString[0]: " ++ testTableString[0] ++ "\n") } for stdOut;

    trigger String with 
      { value = ("testTableString2[0]: " ++ testTableString2["baz"] ++ "\n") } for stdOut;

    trigger String with { value = "----------\n" } for stdOut;
    trigger RetCode with { code = 0 } for ret;
  }

  handler Integer(e) {}

}
