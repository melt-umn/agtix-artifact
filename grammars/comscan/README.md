# 'ComSCaN' DSL Example

This is an experimental work-in-progress event-driven language that follows the
actor model, in which actors are the basic building blocks of a program. Each
'handling' actor is defined with its own (private) state consisting of C-like
declarations, and initialized for that actor an `init` block, executed when the
actor is instantiated. Since this is an event-driven language, each actor also
defines a set of event handlers and may trigger events for other actors it is
connected to, as well as actions akin to C procedures. 'Joined' actors are
those which define instances of other actors in their bodies, and have the
purpose of connecting instances of these together to define the flow of events
through a program.

## 'ComScan' Language Overview

### 1. Actors and Events

#### 1.1. Event Definitions

DSL programs define events consisting of a name and field declarations. The
fields of an event are denoted as C-like declarations of a type and a name.
When an event is triggered, definitions of all of its fields must be given.
When an event is handled, its field values can be used by qualified access -
for example `integerEvent.value` to refer to the `value` field of an instance,
with name `integerEvent`, of the `Integer` event defined below.

Events can be defined in a hierarchical way, with an event possibly 'extending'
another to say that it inherits all of the fields of that event. The event
definition `Integer2` below is an example of this. It extends the `Integer`
event with a new field `isNeg` of type `bool`. It thus has two fields; `value`
inherited from `Integer`, and `isNeg`. Actors that handle `Integer` events also
handle `Integer2` events by consequence of this hierarchical pattern. That is,
`Integer2` events can be handled by the same event handler definition as
`Integer` events. This works because all of the fields the handler is expecting
`Integer` events to have are also held by `Integer2` events. On the other hand,
a handler defined to explicitly handle `Integer2` cannot handle `Integer`.

```
event DoneEvent { };
event Integer { int value; };
event Integer2 extends Integer with { bool isNeg; };
```

Note that `Integer` is an event defined in the `events.tst` library file,
along with other library definitions [here](lib/events.tst).

#### 1.2. Actor Definitions

Most actors defined in a DSL program will be those that handle and emit events.
These define a number of event handlers and actions which are similar to
procedures in C-like languages. Their role is to receive incoming events and
decide what to do with them, possibly triggering events for other actors on its
outgoing connections. They hold state which may affect how they handle events
or perform other actions.

The key components of an actor are:

- Its 'incoming' event set - i.e. the set of events it handles.
- Its 'outgoing' connections, each defined with a name and an event set.
- The state definition(s) declaring its private state fields.
- The `init` block which initialized state fields for an actor instance.
- Its set of event handlers.
- Its set of actions, effectful procedures that do not return values.

An example of how these components are put together can be seen below, a reduced
example taken from a test program that doubles numbers and checks the result. We
describe its components here.

The actor is defined with its incoming event set denoted `Integer | DoneEvent`.
I.e. `Integer` and `DoneEvent` are the two event types that the `Doubler` actor
can handle. There is also wildcard notation `*` to say that an actor handles any
event type in the program. For example, `* -> receiver: Integer` and 
`* | DoneEvent -> receiver: Integer` are both valid actor signatures.

The connections defined for this actor are `receiver` of type `Integer` and
`doneSending` of type `DoneEvent`. As with the incoming events, these types
are non-empty sets (here singletons) of events that can be sent to particular
connections. Again the wildcard `*` may be used to say that any event type
may be sent to a given connection.

The state of the `Doubler` (defined [here](inputs/double.tst)) actor consists of
a single field, `numDoubled`, an integer. This is initialized in the `init`
block to `0`. Thus any instance of this actor will begin with its `numDoubled`
field set to `0`. State fields can be updated in the initialization block(s),
or any handler or action in the same actor. Since we follow the actor model,
state fields of a given actor cannot be directly modified by another.

The actor consists of two handlers, one for each of the event types declared in
the actor signature. In addition, there is an action `updateNum` which increments
the `numDoubled` state field. Actions are procedures akin to C functions.
Handlers on the other hand are akin to functions which can only take one
argument, the event to handle.

```
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
```

#### 1.3. Joined Actor Definitions

Joined actors are what we use to 'stitch' instances of actors together to form
a coherent program, in which actor instances are like nodes in a directed graph.
The instances defined in a joined actor can be the event-handling actors as
described previously, or other joined actors. Thus if we continue the directed
graph way of thinking about these actors, then instances of a joined actor in
another joined actor can be thought of as sub-graphs. 

The key components of a joined actor are:

- Its 'incoming' event set - i.e. the set of events it handles.
- Its 'outgoing' connections, each defined with a name and an event set.
- Its `start` actor definition.
- The instances of actors it defines within its body.

For the doubler program we describe here the key components of its `Main`
actor definition, given below. 

```
actor Main() : * -> mainRet: RetCode; start = sender {
  Sender  sender()  with { receiver = doubler, doneSending = doubler };
  Doubler doubler() with { receiver = checker, doneSending = checker };
  Checker checker() with { receiver = mainRet };
}
```

Like other actos, joined actors are defined with a signature declaring its
sets of inbound and outbound event types. The `Main` actor below has `*` as its
inbound event type, meaning that may receive any event type (although in reality
a `Main` actor never 'receives' any events - an implementation detail). The
signature consists of one connection, `mainRet` of type `RetCode`. This is a
built-in event type that communicates the return code of a program execution.
Every `Main` actor has this signature, a detail checked by the compiler.

The `start = sender` part of this example says that the first actor in the
directed graph of actors that `Main` defines is the `sender` instance defined
in its body. Any event received by a joined actor is sent to its start actor,
thus the joined actor itself does not directly handle any events.

The body defines instances of actors, here three of them. Each connection for
the actor instances must be defined in the joined actor. This is how individual
instances of actors are 'stitched' together to form a directed graph. For a
particular actor's connections either other actor instances in the joined actor
body, or the connections of that joined actor, may be used.


### 2. Statements and Expressions

Statements and expressions appear within an actor's `init`, in event handlers,
or in actions.

#### 2.0. Sequencing

Statements are written in a sequential way, similar to C. Each statement is
ended by a semi-colon.
```
<stmt1>;
<stmt2>;
```

#### 2.1. Event Access and Triggering

Fields of an event are accessed by the following expression notation:
```
<event>.<field>
```

Events are triggered by the following statement notation:
```
trigger <event> for <connection>;
```

In the example below we access and update the `value` field of an `Integer`
event called `e`, and then send it to a connection called `receiver`.

```
handler Integer (e) {
  e.value = e.value * 2;
  trigger e for receiver;
}
```

#### 2.2. Tables

Tables in the DSL are similar to C arrays, except that there is no fixed size
and a default value is assumed for keys whose table cell is not given an
explicit definition. Tables may only be declared within the `state` block of an
actor. Table values can be access and defined in the `init` block of an actor
or any action or handler.

Access a table entry value with expression:
```
<table>[<key>]
```

Update a table entry with statement:
```
<table>[<key>] = <expr>;
```

Remove a table entry with statement:
```
remove <key> from <table>;
```

In the example below we declare a table `tableAges` of key type `string` and
value type `int`, initialize it with one key-value pair in the `init` block,
and define a way to update it in the event handler for `NewAge` events.

```
event NewAge { string name; int age; };

actor AgeActor(): NewAge -> {

  state { 
    table<string, int> tableAges; 
  }

  init {
    tableAges["Luke"] = 27;
  }

  handler NewAge(e) {
    tableAges[e.name] = e.age; 
  }

}
```

#### 2.3. Declarations

As in C, declarations are defined with a name and a type.
```
<type> <id>;
```
For example:
```
int foo;
```
The user may also write statements of the form:
```
<type> <id> = <expression>;
```
Such as:
```
int foo = 3;
```

#### 2.4. Action Invocation

Actions are invoked in the following way:
```
<action-name>(<type-1> <param-name-1>, ..., <type-n> <param-name-n>);
```
For example:
```
int key = 12;
string value = "foo";

updateActorTable(key, value);
```
For some action defined as:
```
action updateActorTable(int key, string value) {
  table[key] = value;
}
```

#### 2.5. Event Matching

Events of an unknown type, that is, are only known to be `*` may be matched on.

Matching on event types is denoted:
```
match type(<event-id>) with {
  | <event-type-1> -> <stmt-1>
  | ... -> ...
  | <event-type-n> -> <stmt-n>
}
```

For example:
```
handler * (e) {
  match type(e) with {
    | Integer -> <stmt>
    | Integer2 -> <stmt>
  }
}
```

#### 2.6. Expressions

Binary operations are written in the usual way:
```
<expr> <binop> <expr>
```
With `<binop>` as one of:
- `||` or `&&` for and/or over `bool`s,
- `|` or `&` for bitwise operations,
- `+` or `-` or `*` or `/` or `%` for `int` arithmetic,
- `==` or `!=` or `>` or `>=` or `<` or `<=` for comparison,
- `>>` or `<<` for bit shifting,
- `++` for appending `string`s

Unary operations are:
```
<unop> <expr>
```

With `<unop>` as one of:
- `!` for `bool` negation
- `-` for `int` negation
- `~` for bitwise negation

Constants are `"string"`s, `true`/`false`, or integers.

`toStr(<expr>)` allows `int`s or `bool`s to be converted to `string`s, and
`scan()` allows input from the user.

Events can be instantiated as expressions in the following way:
```
<event-type> with { <field-1> = <expr-1>, ..., <field-n> = <expr-n> }
```
For example, the following expression has type `Integer`:
```
Integer with { value = 12; }
```
In expressions such as the above, every field of the corresponding event type
must be defined within the curly braces.

An expression that returns `true`/`false` if a table does/does not have a value
for a particular key is the following:
```
<table-id> haskey <key>
```
And table values are accessed by the expression:
```
<table-id>[<key>]
```

### 3. Types and Scoping

#### 3.1. Types

##### Basic Types

The basic types in the DSL are:

- `int`: for which values are the negative and non-negative integers.

- `bool`: for which values are `true`/`false`.

- `string`: for which values are `"strings of characters in quotes"`.

- `table<k, v>` where `k` and `v` are types: the generic table type

##### Event Types

Each event definition introduces a new type for that event. The definition
below introduces new type `Integer` which can then be used in successive
declarations of handlers, variables, etc.
```
event Integer { int value; };
event Integer2 extends Integer with { bool isNeg; };

actor SomeActor(): ... -> ... {
  init {
    Integer newInteger = Integer with { value = 3 };
  }
  handler Integer(e) {
    ...
  }
}
```

Event types have a hierarchical pattern. If one event extends another, the
former can be seen as a sub-type of the latter. Event handlers defined to
handle the latter event type can also be used to handle the former. Similarly,
events of the former type can be triggered for connections whose type contains 
the latter.

In the above code, `Integer2` events can be handled by the handler defined with
`Integer`.

In the current state of the DSL, definitions such as the below are not valid:
```
Integer foo = Integer2 with { value = 1, isNeg = true };
```
But this behavior may be implemented in the future.
