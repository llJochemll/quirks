module quirks.aggregate;

import quirks.functional: Parameters;
import quirks.tuple : FilterTuple;
import quirks.type : TypeOf, isAggregate, isExpression;
import quirks.utility;
import std.algorithm;
import std.array;
import std.functional : unaryFun;
import std.meta;
import std.traits;
import std.typecons;

@safe
private template Class(alias aggregate) if (is(TypeOf!aggregate == class)) {
    alias Class = ClassMeta!aggregate();
}

@safe
private template Interface(alias aggregate) if (is(TypeOf!aggregate == interface)) {
}

@safe
private template Struct(alias aggregate) if (is(TypeOf!aggregate == struct)) {
    alias Class = StructMeta!aggregate();
}

/++
+ Returns a tuple of structs containing the name and type of the fields of the given aggregate
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
+ 
+ alias fields = Fields!S; // is equal to a tuple of 3 structs containing the name and type of the field
+ 
+ static foreach (field; fields) {
+     pragma(msg, field.type.stringof);
+     pragma(msg, field.name);
+ }
+ ---
+/
@safe
template Fields(alias aggregate) if (isAggregate!aggregate) {
    private auto fieldsMixinList() {
        string[] members;

        static foreach (memberName; MemberNames!aggregate) {
            static if (!isCallable!(TypeOf!(__traits(getMember, aggregate, memberName)))) {
                members ~= `getField!(aggregate, "` ~ memberName ~ `")`;
            }
        }

        return members;
    }

    mixin(interpolateMixin(q{
        alias Fields = AliasSeq!(${fieldsMixinList.join(",")});
    }));
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    Fields!(S).length.should.equal(2);
    Fields!(s).length.should.equal(2);

    Fields!(C).length.should.equal(2);
    Fields!(c).length.should.equal(2);
}

/++
+ Returns a tuple of structs containing the name and type of the fields of the given aggregate, filtered with the given predicate
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
+ 
+ alias fields = Fields!(S, field => isNumeric!(field.type)); // is equal to a tuple of 2 structs containing the name and type of the field
+ 
+ static foreach (field; fields) {
+     pragma(msg, field.type.stringof);
+     pragma(msg, field.name);
+ }
+ ---
+/
@safe
template Fields(alias aggregate, alias predicate) if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    alias Fields = FilterTuple!(predicate, Fields!aggregate);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    Fields!(S, field => is(field.type == long)).length.should.equal(1);
    Fields!(s, field => is(field.type == long)).length.should.equal(1);
    Fields!(S, field => is(field.type == string)).length.should.equal(0);
    Fields!(s, field => is(field.type == string)).length.should.equal(0);
    Fields!(S, field => isNumeric!(field.type)).length.should.equal(2);
    Fields!(s, field => isNumeric!(field.type)).length.should.equal(2);
    Fields!(S, field => isArray!(field.type)).length.should.equal(0);
    Fields!(s, field => isArray!(field.type)).length.should.equal(0);
    Fields!(S, field => field.name == "id").length.should.equal(1);
    Fields!(s, field => field.name == "id").length.should.equal(1);
    Fields!(S, field => field.name == "name").length.should.equal(0);
    Fields!(s, field => field.name == "name").length.should.equal(0);
    Fields!(S, field => field.name == "doesNotExist").length.should.equal(0);
    Fields!(s, field => field.name == "doesNotExist").length.should.equal(0);

    Fields!(C, field => is(field.type == long)).length.should.equal(1);
    Fields!(c, field => is(field.type == long)).length.should.equal(1);
    Fields!(C, field => is(field.type == string)).length.should.equal(0);
    Fields!(c, field => is(field.type == string)).length.should.equal(0);
    Fields!(C, field => isNumeric!(field.type)).length.should.equal(2);
    Fields!(c, field => isNumeric!(field.type)).length.should.equal(2);
    Fields!(C, field => isArray!(field.type)).length.should.equal(0);
    Fields!(c, field => isArray!(field.type)).length.should.equal(0);
    Fields!(C, field => field.name == "id").length.should.equal(1);
    Fields!(c, field => field.name == "id").length.should.equal(1);
    Fields!(C, field => field.name == "name").length.should.equal(0);
    Fields!(c, field => field.name == "name").length.should.equal(0);
    Fields!(C, field => field.name == "doesNotExist").length.should.equal(0);
    Fields!(c, field => field.name == "doesNotExist").length.should.equal(0);
}

@safe
template Methods(alias aggregate) if (isAggregate!aggregate) {
    auto getMethodsMixinList() {
        string[] methods;

        static foreach (memberName; MemberNames!aggregate) {
            static if (!hasField!(aggregate, memberName)) {
                methods ~= `AggregateMethod!(aggregate, "` ~ memberName ~ `")()`;
            }
        }

        return methods;
    }

    pragma(msg, getMethodsMixinList.join(","));

    mixin(interpolateMixin(q{
        alias Methods = AliasSeq!(${getMethodsMixinList.join(",")});
    }));
}

@safe
template Methods(alias aggregate, alias predicate) if (isAggregate!aggregate  && is(typeof(unaryFun!predicate))) {
    alias Methods = FilterTuple!(predicate, Methods!aggregate);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    Methods!(S, method => is(method.type == string)).length.should.equal(1);
    Methods!(s, method => is(method.type == string)).length.should.equal(1);
    Methods!(S, method => is(method.type == long)).length.should.equal(0);
    Methods!(s, method => is(method.type == long)).length.should.equal(0);
    Methods!(S, method => isNumeric!(method.type)).length.should.equal(0);
    Methods!(s, method => isNumeric!(method.type)).length.should.equal(0);
    Methods!(S, method => isSomeString!(method.type)).length.should.equal(1);
    Methods!(s, method => isSomeString!(method.type)).length.should.equal(1);
    Methods!(S, method => method.name == "id").length.should.equal(0);
    Methods!(s, method => method.name == "id").length.should.equal(0);
    Methods!(S, method => method.name == "name").length.should.equal(1);
    Methods!(s, method => method.name == "name").length.should.equal(1);
    Methods!(S, method => method.name == "doesNotExist").length.should.equal(0);
    Methods!(s, method => method.name == "doesNotExist").length.should.equal(0);

    Methods!(C, method => is(method.type == string)).length.should.equal(1);
    Methods!(c, method => is(method.type == string)).length.should.equal(1);
    Methods!(C, method => is(method.type == long)).length.should.equal(0);
    Methods!(c, method => is(method.type == long)).length.should.equal(0);
    Methods!(C, method => isNumeric!(method.type)).length.should.equal(0);
    Methods!(c, method => isNumeric!(method.type)).length.should.equal(0);
    Methods!(C, method => isSomeString!(method.type)).length.should.equal(1);
    Methods!(c, method => isSomeString!(method.type)).length.should.equal(1);
    Methods!(C, method => method.name == "id").length.should.equal(0);
    Methods!(c, method => method.name == "id").length.should.equal(0);
    Methods!(C, method => method.name == "name").length.should.equal(1);
    Methods!(c, method => method.name == "name").length.should.equal(1);
    Methods!(C, method => method.name == "doesNotExist").length.should.equal(0);
    Methods!(c, method => method.name == "doesNotExist").length.should.equal(0);
}

/++
+ Returns the same as __traits(allMembers, aggregate), excluding this and all default fields inherited from Object
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
+ 
+ MemberNames!(S); // is equal to ("id", "age", "name")
+ ---
+/
@safe
template MemberNames(alias aggregate) if (isAggregate!aggregate) {
    alias MemberNames = FilterTuple!(name => ![__traits(allMembers, Object)].canFind(name) && name != "this", __traits(allMembers, TypeOf!aggregate));
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

    MemberNames!S.length.should.equal(2);
    MemberNames!s.length.should.equal(2);

    MemberNames!C.length.should.equal(2);
    MemberNames!c.length.should.equal(2);
}

/++
+ Returns the same as __traits(allMembers, aggregate), excluding this and all default fields inherited from Object, filtered with the provided predicate
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
+ 
+ MemberNames!(S, name => name == "id"); // is equal to ("id")
+ MemberNames!(S, name => name.length < 4); // is equal to ("id", "age")
+ MemberNames!(S, name => false); // ris equal to ()
+ ---
+/
@safe
template MemberNames(alias aggregate, alias predicate) if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    alias MemberNames = FilterTuple!(predicate, MemberNames!aggregate);
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

    MemberNames!(S, name => name == "id").length.should.equal(1);
    MemberNames!(s, name => name == "id").length.should.equal(1);
    MemberNames!(S, name => name == "name").length.should.equal(1);
    MemberNames!(s, name => name == "name").length.should.equal(1);
    MemberNames!(S, name => name == "doesNotExist").length.should.equal(0);
    MemberNames!(s, name => name == "doesNotExist").length.should.equal(0);

    MemberNames!(C, name => name == "id").length.should.equal(1);
    MemberNames!(c, name => name == "id").length.should.equal(1);
    MemberNames!(C, name => name == "name").length.should.equal(1);
    MemberNames!(c, name => name == "name").length.should.equal(1);
    MemberNames!(C, name => name == "doesNotExist").length.should.equal(0);
    MemberNames!(c, name => name == "doesNotExist").length.should.equal(0);
}

/++
+ Returns an struct containing the name and type of the field
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
+ 
+ auto field = getField!(S, "id"); // is equal to a tuple of 3 structs containing the name and type of the field
+ 
+ writeln("Field ", field.name, " has a type of: ", field.type.stringof);
+ ---
+/
@safe
pure auto getField(alias aggregate, string fieldName)() if (isAggregate!aggregate) {
    static assert(hasField!(aggregate, fieldName));

    return AggregateField!(__traits(getMember, TypeOf!aggregate, fieldName))();
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    getField!(S, "id").name.should.equal("id");
    is(getField!(S, "id").type == long).should.equal(true);
    getField!(s, "id").name.should.equal("id");
    is(getField!(s, "id").type == long).should.equal(true);
    getField!(S, "age").name.should.equal("age");
    is(getField!(S, "age").type == int).should.equal(true);
    getField!(s, "age").name.should.equal("age");
    is(getField!(s, "age").type == int).should.equal(true);

    getField!(C, "id").name.should.equal("id");
    is(getField!(C, "id").type == long).should.equal(true);
    getField!(c, "id").name.should.equal("id");
    is(getField!(c, "id").type == long).should.equal(true);
    getField!(C, "age").name.should.equal("age");
    is(getField!(C, "age").type == int).should.equal(true);
    getField!(c, "age").name.should.equal("age");
    is(getField!(c, "age").type == int).should.equal(true);
}

/++
+ Returns true if a member can be found on aggregate with the given memberName, false otherwise.
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
+ 
+ hasMember!(S, "id"); // returns true
+ hasMember!(S, "name"); // returns true
+ hasMember!(S, "doesNotExist"); // returns false
+ ---
+/
@safe 
pure auto hasMember(alias aggregate, string memberName)() if (isAggregate!aggregate) {
    return [MemberNames!aggregate].canFind(memberName);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
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

/++
+ Returns true if a field can be found on aggregate with the given fieldName, false otherwise.
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
+ 
+ hasField!(S, field => "id"); // returns true
+ hasField!(S, field => "name"); // returns false
+ ---
+/
@safe
pure auto hasField(alias aggregate, string fieldName)() if (isAggregate!aggregate) {
    return [MemberNames!aggregate].canFind(fieldName) && __traits(compiles, __traits(getMember, aggregate, fieldName).stringof);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
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

/++
+ Returns true if a field can be found on aggregate filtered with the given predicate, false otherwise.
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
+ 
+ hasField!(S, field => isNumeric!(field.type)); // returns true
+ hasField!(S, field => is(field.type == string)); // returns false
+ ---
+/
@safe
pure auto hasField(alias aggregate, alias predicate)() if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    return FilterTuple!(predicate, Fields!aggregate).length > 0;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }
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

@safe
pure auto hasMethod(alias aggregate, string fieldName)() if (isAggregate!aggregate) {
}

@safe
pure auto hasMethod(alias aggregate, alias predicate)() if (isAggregate!aggregate) {
}

private {  
    @safe
    struct AggregateField(alias field) {
        alias attributes = __traits(getAttributes, field);
        alias type = TypeOf!field;

        string name = field.stringof;
    }

    @safe
    struct AggregateMethod(alias aggregate, string methodName) {
        string name = methodName;

        static if (is(aggregate == struct)) {
            alias parameters = Parameters!(__traits(getMember, TypeOf!aggregate(), methodName));
            alias type = ReturnType!(__traits(getMember, TypeOf!aggregate(), methodName));
        } else {

        }
    }

    @safe
    struct AggregateMeta(alias thing) if (is(TypeOf!thing == struct) || is(TypeOf!thing == class) || is(TypeOf!thing == interface)) {
        alias attributes = __traits(getAttributes, thing);
        alias name = thing.stringof;
        alias type = TypeOf!thing;
    }

    @safe
    struct ClassMeta(alias thing) if (is(TypeOf!thing == class)) {
        alias fields = Fields!thing;
        alias isAbstract = isAbstractClass!(TypeOf!thing);
        alias isFinal = isFinalClass!(TypeOf!thing);
        alias aggregateMeta this;

        AggregateMeta!thing aggregateMeta;
    }

    @safe
    struct StructMeta(alias thing) if (is(TypeOf!thing == struct)) {
        alias fields = Fields!thing;
        alias aggregateMeta this;

        AggregateMeta!thing aggregateMeta;
    }
}