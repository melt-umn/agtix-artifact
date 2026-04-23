import "events.tst";
import "stdio.tst";

event IPv6 { int srcIP; };
event FirewallControl { int actn; int address; };

event FirewallInfo { int droppedPackets; };

event EventDoneEvent { int srcIP; bool dropped; };
event EventPassed {};

actor Main(): * -> mainRet: RetCode; start = s
{
    triggerer s with {receiver = f, main = mainRet, stdOut = stdOut };
    Firewall f() with {stdOut = stdOut, controller = s, drop = d, forward = p };
    Receiver p(true)  with { inform = s, stdOut = stdOut };
    Receiver d(false) with { inform = s, stdOut = stdOut };
    StdOut stdOut() with {};
}


actor Receiver(bool isPassedReceiver) : IPv6 -> inform: EventDoneEvent, stdOut: String
{
    control { bool isPassed; }
    init { isPassed = isPassedReceiver; }
    handler IPv6 (e) { informReceiver(e); }
    action informReceiver(IPv6 e) {
      if isPassed {
          trigger String with { value = ("Receiver with isPassed true received an IPv6 packet with src " ++ toString(e.srcIP) ++ "\n") } for stdOut;
      } else {
          trigger String with { value = ("Receiver with isPassed false received an IPv6 packet with src " ++ toString(e.srcIP) ++ "\n") } for stdOut;
      }
      trigger (EventDoneEvent with {dropped = !isPassed, srcIP = e.srcIP}) for inform;
    }
}


actor triggerer() : IPv6|FirewallInfo|EventDoneEvent ->
    receiver: IPv6|FirewallControl,
    main: RetCode,
    stdOut: String
{

    control { 
      int expectDropped;
      int expectPassed; 
      int dropped;
      int passed;
    }

    init {

      trigger String with { value = ("===================================\n") } for stdOut;
      trigger String with { value = ("===== Double program starting =====\n") } for stdOut;

      expectDropped = 1;
      expectPassed = 1;

      dropped = 0;
      passed = 0;

      trigger (FirewallControl with { actn = 1, address = 2 }) for receiver;

      trigger (IPv6 with { srcIP = 1 }) for receiver;
      trigger (IPv6 with { srcIP = 2 }) for receiver;

    }

    handler EventDoneEvent (e) { 
      if (e.dropped) {
          trigger String with { value = ("Packet was DROPPED with src IP " ++ toString(e.srcIP) ++ "\n") } for stdOut;
          dropped = dropped + 1;
      } else {
          trigger String with { value = ("Packet was PASSED with src IP " ++ toString(e.srcIP) ++ "\n") } for stdOut;
          passed = passed + 1;
      }
      triggerRetIfReady();
    }

    handler IPv6 (e) {}
    handler FirewallInfo (e) {}

    action triggerRetIfReady() {
      if (dropped + passed == expectDropped + expectPassed) {
          int retCode;
          if (dropped == expectDropped && passed == expectPassed)
              retCode = 0;
          else
              retCode = -1;
          trigger String with { value = ("===== Double program complete =====\n") } for stdOut;
          trigger String with { value = ("===================================\n") } for stdOut;
          trigger RetCode with { code = retCode } for main;
      }
    }

}


actor Firewall() : IPv6 | FirewallControl ->
         forward: IPv6,
         drop: IPv6,
         controller: FirewallInfo,
         stdOut: String {
    
    control {
      table<int, int> dropTable;
      int droppedPackets;
    }

    init { droppedPackets = 0; }

    handler IPv6 (e) {
        trigger String with { value = ("Firewall received IPv6 packet with source IP " ++ toString(e.srcIP) ++ "\n") } for stdOut;
        if (dropTable[e.srcIP] == 1) {
            trigger String with { value = ("\tDrop table has 1 for its source IP, DROPPED\n") } for stdOut;
            trigger e for drop;
        } else {
            trigger String with { value = ("\tDrop table does not have 1 for its source IP, PASSED\n") } for stdOut;
            trigger e for forward;
        }
    }

    handler FirewallControl (e) {
      if (e.actn == 0){
          trigger String with { value = ("Told control to pass IPv6 packets with source IP " ++ toString(e.address) ++ "\n") } for stdOut;
          remove e.address from dropTable;
      }
      else if (e.actn == 1){
          trigger String with { value = ("Told control to drop IPv6 packets with source IP " ++ toString(e.address) ++ "\n") } for stdOut;
          dropTable[e.address] = 1;
      }
      else {
          trigger String with { value = ("Told control to trigger info\n") } for stdOut;
          trigger (FirewallInfo with {droppedPackets = droppedPackets}) for controller;
      }
    }

}
