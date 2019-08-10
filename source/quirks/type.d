module quirks.type;

static import std.traits;
import std.typecons;

alias isExpression = std.traits.isExpressions;

/++
+ Returns the type of thing. Accepts both expressions and types.
+ 
+ Example:
+ ---
+ struct S {
+     long id;
+     int age;
+     string name() {
+         return "name";
+     }
+ }
+ int number;
+ S s;
+ 
+ TypeOf!int; // int
+ TypeOf!number; // int
+ TypeOf!S; // S
+ TypeOf!s; // s
+ ---
+/
@safe
template TypeOf(alias thing) {
    static if (std.traits.isType!thing) {
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

/// Return std.traits.isAggregate!(TypeOf!thing)
@safe
pure nothrow auto isAggregate(alias thing)() {
    return std.traits.isAggregateType!(TypeOf!thing);
} unittest {
    import fluent.asserts;

    struct S { }
    class C { }

    S s;
    auto c = new C;

    isAggregate!int.should.equal(false);
    isAggregate!0.should.equal(false);
    isAggregate!string.should.equal(false);
    isAggregate!"hello".should.equal(false);
    isAggregate!S.should.equal(true);
    isAggregate!s.should.equal(true);
    isAggregate!C.should.equal(true);
    isAggregate!c.should.equal(true);
}

/// Return std.traits.isArray!(TypeOf!thing)
@safe
pure nothrow auto isArray(alias thing)() {
    return std.traits.isArray!(TypeOf!thing);
} unittest {
    import fluent.asserts;

    struct S { }

    S[] s;

    isArray!int.should.equal(false);
    isArray!0.should.equal(false);
    isArray!string.should.equal(std.traits.isArray!string);
    isArray!"hello".should.equal(std.traits.isArray!string);
    isArray!(S[]).should.equal(true);
    isArray!s.should.equal(true);
}

/// Return std.traits.isAssociativeArray!(TypeOf!thing)
@safe
pure nothrow auto isAssociativeArray(alias thing)() {
    return std.traits.isAssociativeArray!(TypeOf!thing);
} unittest {
    import fluent.asserts;

    struct S { }

    S[string] s1;
    S[char] s2;

    isAssociativeArray!int.should.equal(false);
    isAssociativeArray!0.should.equal(false);
    isAssociativeArray!string.should.equal(false);
    isAssociativeArray!"hello".should.equal(false);
    isAssociativeArray!(S[string]).should.equal(true);
    isAssociativeArray!s1.should.equal(true);
    isAssociativeArray!s2.should.equal(true);
}

/// Return std.traits.isNumeric!(TypeOf!thing)
@safe
pure nothrow auto isNumeric(alias thing)() {
    return std.traits.isNumeric!(TypeOf!thing);
} unittest {
    import fluent.asserts;

    struct S { }

    S s;

    isNumeric!int.should.equal(true);
    isNumeric!0.should.equal(true);
    isNumeric!double.should.equal(true);
    isNumeric!(0.0).should.equal(true);
    isNumeric!string.should.equal(false);
    isNumeric!"hello".should.equal(false);
    isNumeric!S.should.equal(false);
    isNumeric!s.should.equal(false);
}