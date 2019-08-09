module quirks.type;

import std.traits;
import std.typecons;

alias isExpression = isExpressions;

@safe
template TypeOf(alias thing) {
    static if (isType!thing) {
        alias TypeOf = thing;
    } else {
        alias TypeOf = typeof(thing);
    }
}  unittest {
    import fluent.asserts;

    struct S { }
    class C { }

    is(TypeOf!int == int).should.equal(true);
    is(TypeOf!0 == int).should.equal(true);
    is(TypeOf!string == string).should.equal(true);
    is(TypeOf!"text" == string).should.equal(true);
    is(TypeOf!S == S).should.equal(true);
    is(TypeOf!(S()) == S).should.equal(true);
    is(TypeOf!C == C).should.equal(true);
    auto c = new C;
    is(TypeOf!c == C).should.equal(true);
}

@safe
pure nothrow auto isAggregate(alias aggregate)() {
    return isAggregateType!(TypeOf!aggregate);
} unittest {
    import fluent.asserts;

    struct S { }
    class C { }

    S s;
    auto c = new C;

    isAggregate!int.should.equal(false);
    isAggregate!int.should.equal(false);
    isAggregate!string.should.equal(false);
    isAggregate!string.should.equal(false);
    isAggregate!S.should.equal(true);
    isAggregate!s.should.equal(true);
    isAggregate!C.should.equal(true);
    isAggregate!c.should.equal(true);
}

@safe
pure nothrow auto isArray(alias aggregate)() {
    return isArray!(TypeOf!aggregate);
}

@safe
pure nothrow auto isAssociativeArray(alias aggregate)() {
    return isAssociativeArray!(TypeOf!aggregate);
}