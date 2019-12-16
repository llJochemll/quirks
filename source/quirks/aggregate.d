module quirks.aggregate;

import quirks.core : Quirks;
import quirks.functional: Parameters;
import quirks.tuple : AliasTuple, FilterTuple;
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
            static if (!isCallable!(TypeOf!(__traits(getMember, TypeOf!aggregate, memberName))) && !is(TypeOf!(__traits(getMember, TypeOf!aggregate, memberName)) == void)) {
                members ~= `Quirks!(__traits(getMember, TypeOf!aggregate, "` ~ memberName ~ `"))`;
            }
        }

        return members;
    }

    mixin(interpolateMixin(q{
        alias Fields = AliasTuple!(${fieldsMixinList.join(",")});
    }));
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    Fields!(TestStruct).length.should.equal(3);
    Fields!(s).length.should.equal(3);

    Fields!(TestClass).length.should.equal(3);
    Fields!(c).length.should.equal(3);
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
+ alias fields = Fields!(TestStruct, field => isNumeric!(field.type)); // is equal to a tuple of 2 structs containing the name and type of the field
+ 
+ static foreach (field; fields) {
+     pragma(msg, field.type);
+     pragma(msg, field.name);
+ }
+ ---
+/
@safe
template Fields(alias aggregate, alias predicate) if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    alias Fields = Fields!(TypeOf!aggregate).filter!predicate;
} unittest {
    import quirks.internal.test;
    TestStruct s;
    auto c = new TestClass;

    Fields!(TestStruct, field => is(field.type == long)).length.should.equal(2);
    Fields!(s, field => is(field.type == long)).length.should.equal(2);
    Fields!(TestStruct, field => is(field.type == string)).length.should.equal(0);
    Fields!(s, field => is(field.type == string)).length.should.equal(0);
    Fields!(TestStruct, field => isNumeric!(field.type)).length.should.equal(3);
    Fields!(s, field => isNumeric!(field.type)).length.should.equal(3);
    Fields!(TestStruct, field => isArray!(field.type)).length.should.equal(0);
    Fields!(s, field => isArray!(field.type)).length.should.equal(0);
    Fields!(TestStruct, field => field.name == "id").length.should.equal(1);
    Fields!(s, field => field.name == "id").length.should.equal(1);
    Fields!(TestStruct, field => field.name == "name").length.should.equal(0);
    Fields!(s, field => field.name == "name").length.should.equal(0);
    Fields!(TestStruct, field => field.name == "doesNotExist").length.should.equal(0);
    Fields!(s, field => field.name == "doesNotExist").length.should.equal(0);

    Fields!(TestClass, field => is(field.type == long)).length.should.equal(2);
    Fields!(c, field => is(field.type == long)).length.should.equal(2);
    Fields!(TestClass, field => is(field.type == string)).length.should.equal(0);
    Fields!(c, field => is(field.type == string)).length.should.equal(0);
    Fields!(TestClass, field => isNumeric!(field.type)).length.should.equal(3);
    Fields!(c, field => isNumeric!(field.type)).length.should.equal(3);
    Fields!(TestClass, field => isArray!(field.type)).length.should.equal(0);
    Fields!(c, field => isArray!(field.type)).length.should.equal(0);
    Fields!(TestClass, field => field.name == "id").length.should.equal(1);
    Fields!(c, field => field.name == "id").length.should.equal(1);
    Fields!(TestClass, field => field.name == "name").length.should.equal(0);
    Fields!(c, field => field.name == "name").length.should.equal(0);
    Fields!(TestClass, field => field.name == "doesNotExist").length.should.equal(0);
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
    alias MemberNames = AliasTuple!(__traits(allMembers, TypeOf!aggregate)).filter!(name => ![__traits(allMembers, Object)].canFind(name) && name != "this");
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    MemberNames!TestStruct.length.should.equal(6);
    MemberNames!s.length.should.equal(6);

    MemberNames!TestClass.length.should.equal(6);
    MemberNames!c.length.should.equal(6);
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
+ MemberNames!(TestStruct, name => name == "id"); // is equal to ("id")
+ MemberNames!(TestStruct, name => name.length < 4); // is equal to ("id", "age")
+ MemberNames!(TestStruct, name => false); // is equal to ()
+ ---
+/
@safe
template MemberNames(alias aggregate, alias predicate) if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    alias MemberNames = MemberNames!aggregate.filter!predicate;
} unittest {
    import quirks.internal.test;

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

    MemberNames!(TestStruct, name => name == "id").length.should.equal(1);
    MemberNames!(s, name => name == "id").length.should.equal(1);
    MemberNames!(TestStruct, name => name == "name").length.should.equal(1);
    MemberNames!(s, name => name == "name").length.should.equal(1);
    MemberNames!(TestStruct, name => name == "doesNotExist").length.should.equal(0);
    MemberNames!(s, name => name == "doesNotExist").length.should.equal(0);

    MemberNames!(TestClass, name => name == "id").length.should.equal(1);
    MemberNames!(c, name => name == "id").length.should.equal(1);
    MemberNames!(TestClass, name => name == "name").length.should.equal(1);
    MemberNames!(c, name => name == "name").length.should.equal(1);
    MemberNames!(TestClass, name => name == "doesNotExist").length.should.equal(0);
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
    alias Members = Fields!aggregate.join!(Methods!aggregate);
} unittest {
    import quirks.internal.test;

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

    Members!S.length.should.equal(2);
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
+ Members!(TestStruct, member => member.name.canFind("a")).length; // is 2
+ ---
+/
@safe
template Members(alias aggregate, alias predicate) if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    alias Members = Members!(TypeOf!aggregate).filter!predicate;
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
                    static if (is(typeof(overload))) {
                        mixin(interpolateMixin(q{
                            names ~= "method_${memberName}_${i}";
                        }));
                    }
                } 
            }
        }

        return names;
    }

    static foreach (memberName; MemberNames!aggregate) {
        static if (!hasField!(aggregate, memberName)) {
            static foreach (i, overload; __traits(getOverloads, TypeOf!aggregate, memberName)) {
                static if (is(typeof(overload))) {
                    mixin(interpolateMixin(q{
                        alias method_${memberName}_${i} = overload;
                    }));
                }
            }
        }
    }

    static if (generateNames.length > 0) {
        mixin(interpolateMixin(q{
            alias Methods = AliasTuple!(Quirks!(${generateNames.join("),Quirks!(")}));
        }));
    } else {
        alias Methods = AliasTuple!();
    }
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
    alias Methods = Methods!aggregate.filter!predicate;
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    Methods!(TestStruct, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(s, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(TestStruct, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(s, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(TestStruct, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(s, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(TestStruct, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(s, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(TestStruct, method => method.name == "id").length.should.equal(0);
    Methods!(s, method => method.name == "id").length.should.equal(0);
    Methods!(TestStruct, method => method.name == "name").length.should.equal(1);
    Methods!(s, method => method.name == "name").length.should.equal(1);
    Methods!(TestStruct, method => method.name == "update").length.should.equal(2);
    Methods!(s, method => method.name == "update").length.should.equal(2);
    Methods!(TestStruct, method => method.name == "doesNotExist").length.should.equal(0);
    Methods!(s, method => method.name == "doesNotExist").length.should.equal(0);

    Methods!(TestClass, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(c, method => is(method.returnType == string)).length.should.equal(1);
    Methods!(TestClass, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(c, method => is(method.returnType == long)).length.should.equal(0);
    Methods!(TestClass, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(c, method => isNumeric!(method.returnType)).length.should.equal(0);
    Methods!(TestClass, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(c, method => isSomeString!(method.returnType)).length.should.equal(1);
    Methods!(TestClass, method => method.name == "id").length.should.equal(0);
    Methods!(c, method => method.name == "id").length.should.equal(0);
    Methods!(TestClass, method => method.name == "name").length.should.equal(1);
    Methods!(c, method => method.name == "name").length.should.equal(1);
    Methods!(TestClass, method => method.name == "update").length.should.equal(2);
    Methods!(c, method => method.name == "update").length.should.equal(2);
    Methods!(TestClass, method => method.name == "doesNotExist").length.should.equal(0);
    Methods!(c, method => method.name == "doesNotExist").length.should.equal(0);
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
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    hasField!(TestStruct, "id").should.equal(true);
    hasField!(s, "id").should.equal(true);
    hasField!(TestStruct, "name").should.equal(false);
    hasField!(s, "name").should.equal(false);
    hasField!(TestStruct, "doesNotExist").should.equal(false);
    hasField!(s, "doesNotExist").should.equal(false);

    hasField!(TestClass, "id").should.equal(true);
    hasField!(c, "id").should.equal(true);
    hasField!(TestClass, "name").should.equal(false);
    hasField!(c, "name").should.equal(false);
    hasField!(TestClass, "doesNotExist").should.equal(false);
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
    return Fields!(aggregate, predicate).length > 0;
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    hasField!(TestStruct, field => is(field.type == long)).should.equal(true);
    hasField!(s, field => is(field.type == long)).should.equal(true);
    hasField!(TestStruct, field => is(field.type == string)).should.equal(false);
    hasField!(s, field => is(field.type == string)).should.equal(false);
    hasField!(TestStruct, field => isNumeric!(field.type)).should.equal(true);
    hasField!(s, field => isNumeric!(field.type)).should.equal(true);
    hasField!(TestStruct, field => isArray!(field.type)).should.equal(false);
    hasField!(s, field => isArray!(field.type)).should.equal(false);
    hasField!(TestStruct, field => field.name == "id").should.equal(true);
    hasField!(s, field => field.name == "id").should.equal(true);
    hasField!(TestStruct, field => field.name == "name").should.equal(false);
    hasField!(s, field => field.name == "name").should.equal(false);
    hasField!(TestStruct, field => field.name == "doesNotExist").should.equal(false);
    hasField!(s, field => field.name == "doesNotExist").should.equal(false);

    hasField!(TestClass, field => is(field.type == long)).should.equal(true);
    hasField!(c, field => is(field.type == long)).should.equal(true);
    hasField!(TestClass, field => is(field.type == string)).should.equal(false);
    hasField!(c, field => is(field.type == string)).should.equal(false);
    hasField!(TestClass, field => isNumeric!(field.type)).should.equal(true);
    hasField!(c, field => isNumeric!(field.type)).should.equal(true);
    hasField!(TestClass, field => isArray!(field.type)).should.equal(false);
    hasField!(c, field => isArray!(field.type)).should.equal(false);
    hasField!(TestClass, field => field.name == "id").should.equal(true);
    hasField!(c, field => field.name == "id").should.equal(true);
    hasField!(TestClass, field => field.name == "name").should.equal(false);
    hasField!(c, field => field.name == "name").should.equal(false);
    hasField!(TestClass, field => field.name == "doesNotExist").should.equal(false);
    hasField!(c, field => field.name == "doesNotExist").should.equal(false);
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
    return [MemberNames!aggregate.tuple].canFind(memberName);
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    hasMember!(TestStruct, "id").should.equal(true);
    hasMember!(s, "id").should.equal(true);
    hasMember!(TestStruct, "name").should.equal(true);
    hasMember!(s, "name").should.equal(true);
    hasMember!(TestStruct, "doesNotExist").should.equal(false);
    hasMember!(s, "doesNotExist").should.equal(false);

    hasMember!(TestClass, "id").should.equal(true);
    hasMember!(c, "id").should.equal(true);
    hasMember!(TestClass, "name").should.equal(true);
    hasMember!(c, "name").should.equal(true);
    hasMember!(TestClass, "doesNotExist").should.equal(false);
    hasMember!(c, "doesNotExist").should.equal(false);
}

/++
+ Returns true if a member can be found on aggregate filtered with the given predicate, false otherwise.
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
+ hasMember!(S, member => is(member.type == long)); // returns true
+ hasMember!(S, member => is(member.type == string)); // returns true
+ hasMember!(S, member => member.name == "doesNotExist"); // returns false
+ ---
+/
@safe
pure nothrow auto hasMember(alias aggregate, alias predicate)() if (isAggregate!aggregate && is(typeof(unaryFun!predicate))) {
    return Members!(aggregate, predicate).length > 0;
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    hasMember!(TestStruct, member => is(member.type == long)).should.equal(true);
    hasMember!(s, member => is(member.type == long)).should.equal(true);
    hasMember!(TestStruct, member => is(member.returnType == string)).should.equal(true);
    hasMember!(s, member => is(member.returnType == string)).should.equal(true);
    hasMember!(TestStruct, member => isNumeric!(member.type)).should.equal(true);
    hasMember!(s, member => isNumeric!(member.type)).should.equal(true);
    hasMember!(TestStruct, member => isArray!(member.type)).should.equal(false);
    hasMember!(s, member => isArray!(member.type)).should.equal(false);
    hasMember!(TestStruct, member => member.name == "id").should.equal(true);
    hasMember!(s, member => member.name == "id").should.equal(true);
    hasMember!(TestStruct, member => member.name == "name").should.equal(true);
    hasMember!(s, member => member.name == "name").should.equal(true);
    hasMember!(TestStruct, member => member.name == "doesNotExist").should.equal(false);
    hasMember!(s, member => member.name == "doesNotExist").should.equal(false);

    hasMember!(TestClass, member => is(member.type == long)).should.equal(true);
    hasMember!(c, member => is(member.type == long)).should.equal(true);
    hasMember!(TestClass, member => is(member.returnType == string)).should.equal(true);
    hasMember!(c, member => is(member.returnType == string)).should.equal(true);
    hasMember!(TestClass, member => isNumeric!(member.type)).should.equal(true);
    hasMember!(c, member => isNumeric!(member.type)).should.equal(true);
    hasMember!(TestClass, member => isArray!(member.type)).should.equal(false);
    hasMember!(c, member => isArray!(member.type)).should.equal(false);
    hasMember!(TestClass, member => member.name == "id").should.equal(true);
    hasMember!(c, member => member.name == "id").should.equal(true);
    hasMember!(TestClass, member => member.name == "name").should.equal(true);
    hasMember!(c, member => member.name == "name").should.equal(true);
    hasMember!(TestClass, member => member.name == "doesNotExist").should.equal(false);
    hasMember!(c, member => member.name == "doesNotExist").should.equal(false);
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
+ hasField!(TestStruct, "name"); // returns true
+ hasField!(TestStruct, "age"); // returns false
+ ---
+/
@safe
pure nothrow auto hasMethod(alias aggregate, string methodName)() if (isAggregate!aggregate) {
    return Methods!(aggregate, method => method.name == methodName).length > 0;
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    hasMethod!(TestStruct, "id").should.equal(false);
    hasMethod!(s, "id").should.equal(false);
    hasMethod!(TestStruct, "name").should.equal(true);
    hasMethod!(s, "name").should.equal(true);
    hasMethod!(TestStruct, "doesNotExist").should.equal(false);
    hasMethod!(s, "doesNotExist").should.equal(false);

    hasMethod!(TestClass, "id").should.equal(false);
    hasMethod!(c, "id").should.equal(false);
    hasMethod!(TestClass, "name").should.equal(true);
    hasMethod!(c, "name").should.equal(true);
    hasMethod!(TestClass, "doesNotExist").should.equal(false);
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
+ hasField!(TestStruct, method => method.name == "name"); // returns true
+ hasField!(TestStruct, method => is(method.returnType == int)); // returns false
+ ---
+/
@safe
pure nothrow auto hasMethod(alias aggregate, alias predicate)() if (isAggregate!aggregate) {
    return Methods!(aggregate, predicate).length > 0;
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    hasMethod!(TestStruct, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(s, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(TestStruct, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(s, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(TestStruct, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(s, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(TestStruct, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(s, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(TestStruct, method => method.name == "id").should.equal(false);
    hasMethod!(s, method => method.name == "id").should.equal(false);
    hasMethod!(TestStruct, method => method.name == "name").should.equal(true);
    hasMethod!(s, method => method.name == "name").should.equal(true);
    hasMethod!(TestStruct, method => method.name == "doesNotExist").should.equal(false);
    hasMethod!(s, method => method.name == "doesNotExist").should.equal(false);

    hasMethod!(TestClass, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(c, method => is(method.returnType == long)).should.equal(false);
    hasMethod!(TestClass, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(c, method => is(method.returnType == string)).should.equal(true);
    hasMethod!(TestClass, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(c, method => isSomeString!(method.returnType)).should.equal(true);
    hasMethod!(TestClass, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(c, method => isNumeric!(method.returnType)).should.equal(false);
    hasMethod!(TestClass, method => method.name == "id").should.equal(false);
    hasMethod!(c, method => method.name == "id").should.equal(false);
    hasMethod!(TestClass, method => method.name == "name").should.equal(true);
    hasMethod!(c, method => method.name == "name").should.equal(true);
    hasMethod!(TestClass, method => method.name == "doesNotExist").should.equal(false);
    hasMethod!(c, method => method.name == "doesNotExist").should.equal(false);
}