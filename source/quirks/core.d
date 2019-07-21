module quirks.core;

static import std.traits;
import quirks.aggregate : Fields, Methods;
import quirks.functional : Parameters, FunctionAttributes;
import quirks.type : TypeOf, isAggregate;
import quirks.utility : interpolateMixin;
import std.meta;

/++
+ 
+/
template Quirks(alias thing) {
    alias quirks = AliasSeq!(
        "attributes", q{__traits(getAttributes, thing)},
        "fields", q{Fields!thing},
        "functionAttributes", q{FunctionAttributes!thing},
        "isNested", q{std.traits.isNested!thing},
        "methods", q{Methods!thing},
        "parameters", q{Parameters!thing},
        "returnType", q{std.traits.ReturnType!thing},
        "type", q{TypeOf!thing},
    );

    struct QuirksStruct(alias thing, string nameParam) {
        static foreach (i, expression; quirks) {
            static if (i % 2 == 1) {
                mixin(interpolateMixin(q{
                    static if (__traits(compiles, ${expression})) {
                        alias ${quirks[i - 1]} = ${expression};
                    }
                }));
            }
        }

        alias name = nameParam;
    }

    alias Quirks = QuirksStruct!(thing, __traits(identifier, thing));
}