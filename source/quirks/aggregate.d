module quirks.aggregate;

import quirks.utility;
import std.algorithm;
import std.array;
import std.functional: unaryFun;
import std.traits;

/**
* Returns the same as __traits(getMember, aggredate, name)
*/
@safe
pure auto getMember(alias aggregate, string name)() if (isAggregateType!(typeof(aggregate))) {
    static assert(hasMember!(typeof(aggregate), name), typeof(aggregate).stringof ~ " has no member named" ~ name);

    return __traits(getMember, aggregate, name);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    getMember!(S(), "id").should.equal(__traits(getMember, S(), "id"));
}

/**
* Returns the same as __traits(allMembers, T)
*/
@safe
pure auto getMembers(T)() if (isAggregateType!T) {
    return [__traits(allMembers, T)];
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }
}

/**
* Returns the same as __traits(allMembers, T), filtered with the provided predicate
*/
@safe
pure auto getMembers(T, alias predicate)() if (isAggregateType!T && is(typeof(unaryFun!predicate))) {
    return [__traits(allMembers, T)].filter!predicate;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }
}

/**
* Returns true if a member can be found with the given predicate on aggregate, false otherwise.
*/
@safe
pure bool hasMember(T, alias predicate)() if (isAggregateType!T && is(typeof(unaryFun!predicate))) {
    return [__traits(allMembers, T)].canFind!(predicate);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    hasMember!(S, (member => member == "id")).should.equal(true);
    hasMember!(S, (member => member == "name")).should.equal(true);
    hasMember!(S, (member => member == "doesNotExist")).should.equal(false);

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    hasMember!(C, (member => member == "id")).should.equal(true);
    hasMember!(C, (member => member == "name")).should.equal(true);
    hasMember!(C, (member => member == "doesNotExist")).should.equal(false);
}

/**
* Returns true if a member can be found on aggregate with the given memberName, false otherwise.
*/
@safe 
pure bool hasMember(T, string memberName)() if (isAggregateType!T) {
    return [__traits(allMembers, T)].canFind(memberName);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    hasMember!(S, "id").should.equal(true);
    hasMember!(S, "name").should.equal(true);
    hasMember!(S, "doesNotExist").should.equal(false);

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    hasMember!(C, "id").should.equal(true);
    hasMember!(C, "name").should.equal(true);
    hasMember!(C, "doesNotExist").should.equal(false);
}

/**
* Returns true if a field can be found on aggregate with the given fieldName, false otherwise.
*/
@safe
pure bool hasField(T, string fieldName)() if (isAggregateType!T) {
    static if (!hasMember!(T, fieldName)) {
        return false;
    } else {
        mixin(interpolateMixin(q{
            return !isCallable!(T.${fieldName});
        }));
    }
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    hasField!(S, "id").should.equal(true);
    hasField!(S, "name").should.equal(false);
    hasField!(S, "doesNotExist").should.equal(false);

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    hasField!(C, "id").should.equal(true);
    hasField!(C, "name").should.equal(false);
    hasField!(C, "doesNotExist").should.equal(false);
}

/**
* Returns true if a method can be found on aggregate with the given methodName, false otherwise.
*/
@safe 
pure bool hasMethod(T, string methodName)() if (isAggregateType!T) {
    static if (!hasMember!(T, methodName)) {
        return false;
    } else {
        mixin(interpolateMixin(q{
            return isCallable!(T.${methodName});
        }));
    }
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    hasMethod!(S, "id").should.equal(false);
    hasMethod!(S, "name").should.equal(true);
    hasMethod!(S, "doesNotExist").should.equal(false);

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    hasMethod!(C, "id").should.equal(false);
    hasMethod!(C, "name").should.equal(true);
    hasMethod!(C, "doesNotExist").should.equal(false);
}