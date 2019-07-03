module quirks.aggregate;

import quirks.functional : getReturnType;
import quirks.type : getType, isAggregate, isExpression;
import quirks.utility;
import std.algorithm;
import std.array;
import std.conv;
import std.functional : forward, unaryFun;
import std.meta;
import std.traits;
import std.typecons;

/**
* Returns an struct containing the name and type of the field
*/
@safe
pure auto getField(alias aggregate, string fieldName)() if (isAggregate!aggregate) {
    static assert(hasField!(aggregate, fieldName));

    return AggregateField!(getType!(__traits(getMember, aggregate, fieldName)), __traits(getMember, getType!aggregate, fieldName).stringof)();
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name;
    }

    class C {
        long id;
        string name;
    }

    S s;
    auto c = new C;

    getField!(S, "id").name.should.equal("id");
    is(getField!(S, "id").type == long).should.equal(true);
    getField!(s, "id").name.should.equal("id");
    is(getField!(s, "id").type == long).should.equal(true);
    getField!(S, "name").name.should.equal("name");
    is(getField!(S, "name").type == string).should.equal(true);
    getField!(s, "name").name.should.equal("name");
    is(getField!(s, "name").type == string).should.equal(true);

    getField!(C, "id").name.should.equal("id");
    is(getField!(C, "id").type == long).should.equal(true);
    getField!(c, "id").name.should.equal("id");
    is(getField!(c, "id").type == long).should.equal(true);
    getField!(C, "name").name.should.equal("name");
    is(getField!(C, "name").type == string).should.equal(true);
    getField!(c, "name").name.should.equal("name");
    is(getField!(c, "name").type == string).should.equal(true);
}

/**
* Returns a tuple of structs containing the name and type of the fields of the given aggregate
*/
@safe
template getFields(alias aggregate) if (isAggregate!aggregate) {
    auto getFieldsMixinList() {
        string[] members;

        static foreach (memberName; getMemberNames!aggregate) {
            static if (!isCallable!(getType!(__traits(getMember, aggregate, memberName)))) {
                members ~= `getField!(aggregate, "` ~ memberName ~ `")`;
            }
        }

        return members;
    }

    mixin(interpolateMixin(q{
        alias getFields = AliasSeq!(${getFieldsMixinList.join(",")});
    }));
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    S s;
    auto c = new C;

    getFields!(S).length.should.equal(1);
    getFields!(s).length.should.equal(1);

    getFields!(C).length.should.equal(1);
    getFields!(c).length.should.equal(1);
}

@safe
template getMethods(alias aggregate, Nullable!string name) if (isAggregate!aggregate) {
    auto getMethodsMixinList() {
        string[] methods;

        static foreach (memberName; getMemberNames!aggregate) {
            static if (isCallable!(typeof(getMember!(aggregate, memberName)))) {
                static if (name.isNull || memberName == name) {
                    methods ~= `getMember!(aggregate, "` ~ memberName ~ `")`;
                }
            }
        }

        return methods;
    }

    mixin(interpolateMixin(q{
        alias getMethods = AliasSeq!(${getMethodsMixinList.join(",")});
    }));
}

/**
* Returns the same as __traits(allMembers, T), excluding this and Monitor
*/
@safe
pure auto getMemberNames(alias aggregate)() if (isAggregate!aggregate) {
    return [__traits(allMembers, getType!aggregate)].filter!(name => name != "this" && name != "Monitor").array;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    S s;
    auto c = new C;

    getMemberNames!S.length.should.equal(2);
    getMemberNames!s.length.should.equal(2);

    getMemberNames!C.length.should.equal(2 + 5);
    getMemberNames!c.length.should.equal(2 + 5);
}

/**
* Returns the same as __traits(allMembers, T), filtered with the provided predicate
*/
@safe
pure auto getMemberNames(alias aggregate, alias predicate)() if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    return getMemberNames!aggregate.filter!predicate.array;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    S s;
    auto c = new C;

    getMemberNames!(S, name => name == "id").length.should.equal(1);
    getMemberNames!(s, name => name == "id").length.should.equal(1);
    getMemberNames!(S, name => name == "name").length.should.equal(1);
    getMemberNames!(s, name => name == "name").length.should.equal(1);
    getMemberNames!(S, name => name == "doesNotExist").length.should.equal(0);
    getMemberNames!(s, name => name == "doesNotExist").length.should.equal(0);

    getMemberNames!(C, name => name == "id").length.should.equal(1);
    getMemberNames!(c, name => name == "id").length.should.equal(1);
    getMemberNames!(C, name => name == "name").length.should.equal(1);
    getMemberNames!(c, name => name == "name").length.should.equal(1);
    getMemberNames!(C, name => name == "doesNotExist").length.should.equal(0);
    getMemberNames!(c, name => name == "doesNotExist").length.should.equal(0);
}

/**
* Returns true if a member can be found on aggregate with the given memberName, false otherwise.
*/
@safe 
pure bool hasMember(alias aggregate, string memberName)() if (isAggregate!aggregate) {
    return getMemberNames!aggregate.canFind(memberName);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    S s;
    auto c = new C;

    hasMember!(S, "id").should.equal(true);
    hasMember!(s, "id").should.equal(true);
    hasMember!(S, "name").should.equal(true);
    hasMember!(s, "name").should.equal(true);
    hasMember!(S, "doesNotExist").should.equal(false);
    hasMember!(s, "doesNotExist").should.equal(false);

    hasMember!(C, "id").should.equal(true);
    hasMember!(c, "id").should.equal(true);
    hasMember!(C, "name").should.equal(true);
    hasMember!(c, "name").should.equal(true);
    hasMember!(C, "doesNotExist").should.equal(false);
    hasMember!(c, "doesNotExist").should.equal(false);
}

/**
* Returns true if a field can be found on aggregate with the given fieldName, false otherwise.
*/
@safe
pure auto hasField(alias aggregate, string fieldName)() if (isAggregate!aggregate) {
    return getMemberNames!aggregate.canFind(fieldName) && __traits(compiles, __traits(getMember, aggregate, fieldName).stringof);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        string name() {
            return "name";
        }
    }
    
    S s;
    auto c = new C;

    hasField!(S, "id").should.equal(true);
    hasField!(s, "id").should.equal(true);
    hasField!(S, "name").should.equal(false);
    hasField!(s, "name").should.equal(false);
    hasField!(S, "doesNotExist").should.equal(false);
    hasField!(s, "doesNotExist").should.equal(false);

    hasField!(C, "id").should.equal(true);
    hasField!(c, "id").should.equal(true);
    hasField!(C, "name").should.equal(false);
    hasField!(c, "name").should.equal(false);
    hasField!(C, "doesNotExist").should.equal(false);
    hasField!(c, "doesNotExist").should.equal(false);
}

@safe
pure auto hasField(alias aggregate, alias predicate)() if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    return filterTuple!(predicate, getFields!aggregate).length > 0;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
    }

    S s;
    auto c = new C;

    hasField!(S, field => is(field.type == long)).should.equal(true);
    hasField!(s, field => is(field.type == long)).should.equal(true);
    hasField!(S, field => is(field.type == string)).should.equal(false);
    hasField!(s, field => is(field.type == string)).should.equal(false);
    hasField!(S, field => isNumeric!(field.type)).should.equal(true);
    hasField!(s, field => isNumeric!(field.type)).should.equal(true);
    hasField!(S, field => isArray!(field.type)).should.equal(false);
    hasField!(s, field => isArray!(field.type)).should.equal(false);
    hasField!(S, field => field.name == "id").should.equal(true);
    hasField!(s, field => field.name == "id").should.equal(true);
    hasField!(S, field => field.name == "name").should.equal(false);
    hasField!(s, field => field.name == "name").should.equal(false);
    hasField!(S, field => field.name == "doesNotExist").should.equal(false);
    hasField!(s, field => field.name == "doesNotExist").should.equal(false);
}

/**
* Returns true if a method can be found on aggregate with the given methodName, false otherwise.
*/
@safe 
pure bool hasMethod(alias aggregate, string methodName)() if (isAggregate!aggregate) {
    return hasMember!(aggregate, methodName) && !hasField!(aggregate, methodName);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        string name() {
            return "name";
        }
    }

    class C {
        long id;
        string name() {
            return "name";
        }
    }

    S s;
    auto c = new C;

    hasMethod!(S, "id").should.equal(false);
    hasMethod!(s, "id").should.equal(false);
    hasMethod!(S, "name").should.equal(true);
    hasMethod!(s, "name").should.equal(true);
    hasMethod!(S, "doesNotExist").should.equal(false);
    hasMethod!(s, "doesNotExist").should.equal(false);

    hasMethod!(C, "id").should.equal(false);
    hasMethod!(c, "id").should.equal(false);
    hasMethod!(C, "name").should.equal(true);
    hasMethod!(c, "name").should.equal(true);
    hasMethod!(C, "doesNotExist").should.equal(false);
    hasMethod!(c, "doesNotExist").should.equal(false);
}

private {
    @safe
    struct AggregateField(T, string fieldName) {
        alias type = T;
        alias name = fieldName;
    }
}