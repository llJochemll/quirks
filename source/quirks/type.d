module quirks.type;

import std.traits;
import std.typecons;

alias isExpression = isExpressions;

@safe
template getType(alias something) {
    static if (isType!something) {
        alias getType = something;
    } else {
        alias getType = typeof(something);
    }
}  unittest {
    import fluent.asserts;

    struct S { }
    class C { }

    is(getType!int == int).should.equal(true);
    is(getType!0 == int).should.equal(true);
    is(getType!string == string).should.equal(true);
    is(getType!"text" == string).should.equal(true);
    is(getType!S == S).should.equal(true);
    is(getType!(S()) == S).should.equal(true);
    is(getType!C == C).should.equal(true);
    auto c = new C;
    is(getType!c == C).should.equal(true);
}

bool isAggregate(alias aggregate)() {
    return isAggregateType!(getType!aggregate);
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