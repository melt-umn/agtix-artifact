import "events.tst";
import "stdio.tst";

actor Main(): * -> mainRet: RetCode; start = sender {
  Tester t()  with { stdOut = stdOut, ret = mainRet };
  StdOut stdOut() with {};
}

actor Tester(): Integer -> stdOut: String, ret: RetCode {

  control {

    table<int, int> testTableInt default 32;

  }

  init {}

  handler Integer(e) {
  
    int foo = nonexistantTable["key"];

    bool has = hasKey(testTableInt, "hi");

    testTableInt["1"] = 2;

    int i = testTableInt["hi"];

    string s = testTableInt[1];
  
  }

}
