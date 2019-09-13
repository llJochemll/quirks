module quirks.aggregate;

import quirks.core : Quirks;
import quirks.functional: Parameters;
import quirks.tuple : FilterTuple;
import quirks.type : TypeOf, isAggregate, isModule;
import quirks.utility;
import std.algorithm;
import std.array;
import std.conv;
import std.functional : unaryFun;
import std.meta;
import std.traits;
import std.typecons;

/++
+ Returns a tuple of each field in the form of the `Quirks` template 
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
+ alias fields = Fields!S;
+ 
+ static foreach (field; fields) {
+     pragma(msg, field.type);
+     pragma(msg, field.name);
+ }
+ ---
+/
@safe
template Fields(alias aggregate) if (isAggregate!aggregate) {
    private auto fieldsMixinList() {
        string[] members;

        static foreach (memberName; MemberNames!aggregate) {
            static if (!isCallable!(TypeOf!(__traits(getMember, aggregate, memberName))) && !is(TypeOf!(__traits(getMember, aggregate, memberName)) == void)) {
                members ~= `Quirks!(__traits(getMember, aggregate, "` ~ memberName ~ `"))()`;
            }
        }

        return members;
    }

    /*pragma(msg, FilterTuple!(method => isCallable!(TypeOf!(__traits(getMember, aggregate, method.name)))));

    enum memberNames = MemberNames!aggregate;

    alias Fields = FilterTuple!(memberName => {
            return !isCallable!(TypeOf!(__traits(getMember, aggregate, memberName))) 
                && !is(TypeOf!(__traits(getMember, aggregate, memberName)) == void);
        }, memberNames);*/

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
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
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
+ Returns a tuple of each field in the form of the `Quirks` template, filtered with the given predicate
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
+     pragma(msg, field.type);
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
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
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
+ MemberNames!(S, name => false); // is equal to ()
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
+ Returns an AliasSeq combining Fields!aggregate and Methods!aggregate
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
+ Members!S.length; // is 3
+ ---
+/
@safe
template Members(alias aggregate) if (isAggregate!aggregate) {
    alias Members = AliasSeq!(Fields!aggregate, Methods!aggregate);
}

/++
+ Returns an AliasSeq combining Fields!aggregate and Methods!aggregate, filtered with the given alias
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
+ Members!(S, member => member.name.canFind("a")).length; // is 2
+ ---
+/
@safe
template Members(alias aggregate, alias predicate) if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    alias Members = FilterTuple!(predicate, Members!aggregate);
}

/++
+ Returns a tuple of each method in the form of the `Quirks` template
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
+ alias fields = Methods!S;
+ 
+ static foreach (method; fields) {
+     pragma(msg, method.returnType);
+     pragma(msg, method.name);
+ }
+ ---
+/
@safe
template Methods(alias aggregate) if (isAggregate!aggregate) {
    auto generateNames() {
        string[] names;

        static foreach (memberName; MemberNames!aggregate) {
            static if (!hasField!(aggregate, memberName)) {
                static foreach (i, overload; __traits(getOverloads, TypeOf!aggregate, memberName)) {
                    mixin(interpolateMixin(q{
                        names ~= "method_${memberName}_${i}";
                    }));
                } 
            }
        }

        return names;
    }

    static foreach (memberName; MemberNames!aggregate) {
        static if (!hasField!(aggregate, memberName)) {
            static foreach (i, overload; __traits(getOverloads, TypeOf!aggregate, memberName)) {
                mixin(interpolateMixin(q{
                    alias method_${memberName}_${i} = overload;
                }));
            } 
        }
    }

    mixin(interpolateMixin(q{
        alias Methods = AliasSeq!(Quirks!(${generateNames.join(")(),Quirks!(")})());
    }));
}

/++
+ Returns a tuple of each method in the form of the `Quirks` template, filtered with the given predicate
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
+ alias fields = Methods!S;
+ 
+ static foreach (method; fields) {
+     pragma(msg, method.returnType);
+     pragma(msg, method.name);
+ }
+ ---
+/
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
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    Methods!(S, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(s, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(S, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(s, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(S, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(s, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(S, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(s, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(S, method => method.name == "id").length.should.equal(0);
    Methods!(s, method => method.name == "id").length.should.equal(0);
    Methods!(S, method => method.name == "name").length.should.equal(1);
    Methods!(s, method => method.name == "name").length.should.equal(1);
    Methods!(S, method => method.name == "update").length.should.equal(2);
    Methods!(s, method => method.name == "update").length.should.equal(2);
    Methods!(S, method => method.name == "doesNotExist").length.should.equal(0);
    Methods!(s, method => method.name == "doesNotExist").length.should.equal(0);

    Methods!(C, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(c, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(C, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(c, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(C, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(c, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(C, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(c, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(C, method => method.name == "id").length.should.equal(0);
    Methods!(c, method => method.name == "id").length.should.equal(0);
    Methods!(C, method => method.name == "name").length.should.equal(1);
    Methods!(c, method => method.name == "name").length.should.equal(1);
    Methods!(C, method => method.name == "update").length.should.equal(2);
    Methods!(c, method => method.name == "update").length.should.equal(2);
    Methods!(C, method => method.name == "doesNotExist").length.should.equal(0);
    Methods!(c, method => method.name == "doesNotExist").length.should.equal(0);
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
pure nothrow auto hasMember(alias aggregate, string memberName)() if (isAggregate!aggregate) {
    return [MemberNames!aggregate].canFind(memberName);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
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
+ hasField!(S, "id"); // returns true
+ hasField!(S, "name"); // returns false
+ ---
+/
@safe
pure nothrow auto hasField(alias aggregate, string fieldName)() if (isAggregate!aggregate) {
    return hasField!(aggregate, field => field.name == fieldName);
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
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
pure nothrow auto hasField(alias aggregate, alias predicate)() if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    return FilterTuple!(predicate, Fields!aggregate).length > 0;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
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

    hasField!(C, field => is(field.type == long)).should.equal(true);
    hasField!(c, field => is(field.type == long)).should.equal(true);
    hasField!(C, field => is(field.type == string)).should.equal(false);
    hasField!(c, field => is(field.type == string)).should.equal(false);
    hasField!(C, field => isNumeric!(field.type)).should.equal(true);
    hasField!(c, field => isNumeric!(field.type)).should.equal(true);
    hasField!(C, field => isArray!(field.type)).should.equal(false);
    hasField!(c, field => isArray!(field.type)).should.equal(false);
    hasField!(C, field => field.name == "id").should.equal(true);
    hasField!(c, field => field.name == "id").should.equal(true);
    hasField!(C, field => field.name == "name").should.equal(false);
    hasField!(c, field => field.name == "name").should.equal(false);
    hasField!(C, field => field.name == "doesNotExist").should.equal(false);
    hasField!(c, field => field.name == "doesNotExist").should.equal(false);
}

/++
+ Returns true if a method can be found on aggregate with the given methodName, false otherwise.
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
+ hasField!(S, "name"); // returns true
+ hasField!(S, "age"); // returns false
+ ---
+/
@safe
pure nothrow auto hasMethod(alias aggregate, string methodName)() if (isAggregate!aggregate) {
    return Methods!(aggregate, method => method.name == methodName).length > 0;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
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

/++
+ Returns true if a method can be found on aggregate filtered with the given predicate, false otherwise.
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
+ hasField!(S, method => method.name == "name"); // returns true
+ hasField!(S, method => is(method.returnType == int)); // returns false
+ ---
+/
@safe
pure nothrow auto hasMethod(alias aggregate, alias predicate)() if (isAggregate!aggregate) {
    return Methods!(aggregate, predicate).length > 0;
} unittest {
    import fluent.asserts;

    struct S {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update() { }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    hasMethod!(S, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(s, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(S, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(s, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(S, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(s, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(S, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(s, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(S, method => method.name == "id").should.equal(false);
    hasMethod!(s, method => method.name == "id").should.equal(false);
    hasMethod!(S, method => method.name == "name").should.equal(true);
    hasMethod!(s, method => method.name == "name").should.equal(true);
    hasMethod!(S, method => method.name == "doesNotExist").should.equal(false);
    hasMethod!(s, method => method.name == "doesNotExist").should.equal(false);

    hasMethod!(C, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(c, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(C, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(c, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(C, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(c, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(C, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(c, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(C, method => method.name == "id").should.equal(false);
    hasMethod!(c, method => method.name == "id").should.equal(false);
    hasMethod!(C, method => method.name == "name").should.equal(true);
    hasMethod!(c, method => method.name == "name").should.equal(true);
    hasMethod!(C, method => method.name == "doesNotExist").should.equal(false);
    hasMethod!(c, method => method.name == "doesNotExist").should.equal(false);
}