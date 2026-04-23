import "events.tst";

event Scan { };

actor StdIn() : Scan -> Out:String {
  control { }
  init { }

  handler Scan (s) {
    string input;
    input = scan();
    trigger String with { value = input } for Out;
  }
}

actor StdOut() : String ->  {
  control { }
  init { }
  handler String (str) {
    print(str.value);
  }
}

// Helper to delegate events to the appropriate actors (stdin or stdout)
actor StdIOHelper() : Scan | String -> StdIn: Scan, StdOut: String {
  control { }
  init {}
  handler Scan (e) {
    trigger e for StdIn;
  }

  handler String (e) {
    trigger e for StdOut;
  }
}

// Actor that combines StdIn and StdOut, allowing their events to be handled in the same buffer; hence sequentially
actor StdIO() : Scan | String -> Out: String; start = helper {
  StdIOHelper helper() with { StdIn = stdin, StdOut = stdout };
  StdIn stdin() with { Out = Out };
  StdOut stdout() with { };
}
