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

template Quirks(alias thing) {
    alias Quirks = Quirks!(thing, void);
}