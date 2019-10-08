module quirks.type;

static import std.traits;
import std.typecons;

/// Alias for std.traits.isExpressions
alias isExpression = std.traits.isExpressions;

/++
+ Returns the same as TypeOf, but but does away with pointers
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
+ auto s = new S;
+ 
+ TypeOf!int; // int
+ TypeOf!number; // int
+ TypeOf!(S**); // S
+ TypeOf!s; // S
+ ---
+/
@safe
template SimpleTypeOf(alias thing) {
    alias Type = TypeOf!thing;

    static if (isPointer!Type) {
        static if (isPointer!(std.traits.PointerTarget!Type)) {
            alias SimpleTypeOf = SimpleTypeOf!(std.traits.PointerTarget!Type);
        } else {
            alias SimpleTypeOf = std.traits.PointerTarget!Type;
        }
    } else {
        alias SimpleTypeOf = Type;
    }
} unittest {
    import fluent.asserts;
    
    is(SimpleTypeOf!(void) == void).should.equal(true);
    is(SimpleTypeOf!(void*) == void).should.equal(true);
    is(SimpleTypeOf!(void**) == void).should.equal(true);
    is(SimpleTypeOf!(string) == string).should.equal(true);
    is(SimpleTypeOf!(string*) == string).should.equal(true);
    is(SimpleTypeOf!(string**) == string).should.equal(true);
}

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
+ TypeOf!s; // S
+ ---
+/
@safe
template TypeOf(alias thing) {
    static if (std.traits.isType!thing || !__traits(compiles, typeof(thing))) {
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

/// Returns std.traits.isAggregate!(TypeOf!thing)
@safe
pure nothrow auto isAggregate(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isAggregateType!Type;
    } else {
        return false;
    }
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

/// Returns std.traits.isArray!(TypeOf!thing)
@safe
pure nothrow auto isArray(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isArray!Type;
    } else {
        return false;
    }
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

/// Returns std.traits.isAssociativeArray!(TypeOf!thing)
@safe
pure nothrow auto isAssociativeArray(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isAssociativeArray!Type;
    } else {
        return false;
    }
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

/// Returns std.traits.isBasic!(TypeOf!thing)
@safe
pure nothrow auto isBasic(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isBasicType!Type;
    } else {
        return false;
    }
} unittest {
    import fluent.asserts;

    struct S { }

    S s;

    isBasic!int.should.equal(true);
    isBasic!0.should.equal(true);
    isBasic!string.should.equal(false);
    isBasic!"hello".should.equal(false);
    isBasic!S.should.equal(false);
    isBasic!s.should.equal(false);
}

/// Returns std.traits.isBuiltin!(TypeOf!thing)
@safe
pure nothrow auto isBuiltin(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isBuiltinType!Type;
    } else {
        return false;
    }
} unittest {
    import fluent.asserts;

    struct S { }

    S s;

    isBuiltin!int.should.equal(true);
    isBuiltin!0.should.equal(true);
    isBuiltin!string.should.equal(true);
    isBuiltin!"hello".should.equal(true);
    isBuiltin!S.should.equal(false);
    isBuiltin!s.should.equal(false);
}

@safe
pure nothrow auto isModule(alias thing)() {
    return __traits(isModule, thing);
} unittest {
    import fluent.asserts;

    isModule!(std.traits).should.equal(true);
    isModule!(std.traits.hasNested).should.equal(false);
}

/// Returns std.traits.isNumeric!(TypeOf!thing)
@safe
pure nothrow auto isNumeric(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isNumeric!Type;
    } else {
        return false;
    }
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

/// Returns std.traits.isPointer!(TypeOf!thing)
@safe
pure nothrow static auto isPointer(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isPointer!Type;
    } else {
        return false;
    }
} unittest {
    import fluent.asserts;

    struct S { }
    class C { }

    auto a = 42;
    auto b = "hello";

    auto s = S();
    auto sr = new S;
    auto c = new C;
    
    isPointer!(int*).should.equal(true);
    isPointer!(string*).should.equal(true);
    isPointer!(S*).should.equal(true);
    isPointer!(sr).should.equal(true);
    isPointer!(C*).should.equal(true);

    isPointer!(int).should.equal(false);
    isPointer!(a).should.equal(false);
    isPointer!(string).should.equal(false);
    isPointer!(b).should.equal(false);
    isPointer!(S).should.equal(false);
    isPointer!(s).should.equal(false);
    isPointer!(C).should.equal(false);
}

/// Returns std.traits.isSomeString!(TypeOf!thing)
@safe
pure nothrow static auto isSomeString(alias thing)() {
    alias Type = TypeOf!thing;

    static if (std.traits.isType!Type) {
        return std.traits.isSomeString!Type;
    } else {
        return false;
    }
} unittest {
    import fluent.asserts;
    
    isSomeString!string.should.equal(true);
    isSomeString!(wchar[]).should.equal(true);
    isSomeString!(dchar[]).should.equal(true);
    isSomeString!"aaa".should.equal(true);
    isSomeString!(const(char)[]).should.equal(true);

    isSomeString!int.should.equal(false);
    isSomeString!(int[]).should.equal(false);
    isSomeString!(byte[]).should.equal(false);
    isSomeString!null.should.equal(false);
    isSomeString!(char[4]).should.equal(false);
}