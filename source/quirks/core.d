module quirks.core;

static import quirks.expression;
static import quirks.type;
static import std.traits;
import quirks.aggregate : Fields, Methods;
import quirks.expression : isStatic;
import quirks.functional : Parameters, FunctionAttributes;
import quirks.type : TypeOf;
import quirks.utility : interpolateMixin;
import std.meta;

/++
+ Swiss army knife for getting information about things.
+ 
+ Takes thing and tries to apply a list of functions and templates to it. All that compile can be accessed using property syntax on the resulting alias.
+ 
+ The code for this is generated during compile-time using traits and mixins. Below is a list of properties that are possible to access (note not all will be available for every instantiation):
+ $(UL
+ $(LI attributes)
+ $(LI fields)
+ $(LI functionAttributes)
+ $(LI isAggregate)
+ $(LI isArray)
+ $(LI isAssociativeArray)
+ $(LI isBasic)
+ $(LI isNested)
+ $(LI isNumeric)
+ $(LI isSomeString)
+ $(LI isStatic)
+ $(LI methods)
+ $(LI parameters)
+ $(LI returnType)
+ $(LI type)
+ )
+
+ In addition, the following functions and templates are also available: 
+ $(UL
+ $(LI getUDAs(alias uda) -> returns the same as getUDAs from std.traits)
+ $(LI getUDA(alias uda) -> returns the first result returned by getUDAs)
+ $(LI hasUDA(alias uda) -> return the same as hasUDA from std.traits)
+ )
+
+ Example:
+ ---
+ struct S {
+     static long id;
+     int age;
+     static string name() {
+         return "name";
+     }
+     void update(bool force) { }
+ }
+ 
+ Quirks!S.type; // S
+ Quirks!S.fields.length; // 2
+ Quirks!S.methods[1].name; //update
+ Quirks!S.isArray; // false
+ Quirks!S.methods[1].parameters[0].type; // bool
+ ---
+/
template Quirks(alias thing, alias specializedQuirks) if (is(TypeOf!specializedQuirks == struct) || is(TypeOf!specializedQuirks == void)) {
    alias quirksTuple = AliasSeq!(
        "attributes", q{__traits(getAttributes, thing)},
        "fields", q{Fields!thing},
        "functionAttributes", q{FunctionAttributes!thing},
        "isAggregate", q{quirks.type.isAggregate!thing},
        "isArray", q{quirks.type.isArray!thing},
        "isAssociativeArray", q{quirks.type.isAssociativeArray!thing},
        "isBasic", q{std.traits.isBasicType!thing},
        "isNested", q{isNested!thing},
        "isNumeric", q{quirks.type.isNumeric!thing},
        "isSomeString", q{std.traits.isSomeString!thing},
        "isStatic", q{quirks.expression.isStatic!thing},
        "methods", q{Methods!thing},
        "parameters", q{Parameters!thing},
        "returnType", q{std.traits.ReturnType!thing},
        "type", q{TypeOf!thing},
    );

    struct QuirksStruct(alias thing, string nameParam, T) {
        static foreach (i, expression; quirksTuple) {
            static if (i % 2 == 1) {
                mixin(interpolateMixin(q{
                    static if (__traits(compiles, ${expression})) {
                        alias ${quirksTuple[i - 1]} = ${expression};
                    }
                }));
            }
        }

        alias name = nameParam;

        @safe
        template getUDAs(alias uda) {
            alias getUDAs = std.traits.getUDAs!(thing, uda);
        }

        @safe
        pure nothrow static auto getUDA(alias uda)() if (getUDAs!uda.length > 0) {
            return getUDAs!uda[0];
        }

        @safe
        pure nothrow static auto hasUDA(alias uda)() {
            return std.traits.hasUDA!(thing, uda);
        }

        static if (is(T == struct)) {
            private T m_specializedQuirks;
            alias m_specializedQuirks this;
        }
    }

    alias Quirks = QuirksStruct!(thing, __traits(identifier, thing), TypeOf!specializedQuirks);
}

/// Shorthand when no specialized struct is needed
template Quirks(alias thing) {
    alias Quirks = Quirks!(thing, void);
}