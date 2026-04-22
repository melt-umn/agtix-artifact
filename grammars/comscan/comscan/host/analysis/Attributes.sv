grammar comscan:host:analysis;

--

monoid attribute msgs::[Message] with [], ++;

synthesized attribute type::Type;

synthesized attribute pp::String;

synthesized attribute fields::[(String, Type)];

monoid attribute eventTypes::[Decorated EventTypeDcl] with [], ++;

inherited attribute expectedConnections::[(String, Type)];

monoid attribute connections::[(String, Type)] with [], ++;

-- temporary whilst annotation occurs on constraints are broken in Silver
synthesized attribute loc::Location;