module quirks.core;

static import std.traits;
import quirks.aggregate : Fields, Methods;
import quirks.functional : Delegate, Function, Parameters;
import quirks.type : TypeOf, isAggregate;
import quirks.utility : interpolateMixin;
import std.meta;

/++
+ 
+/
template Quirks(alias thing) {
    alias quirks = AliasSeq!(
        "fields", q{Fields!thing},
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
} unittest {
    import fluent.asserts;

    import quirks.aggregate;

    class C {
        long id;
        int age;
        string name() {
            return "name";
        }
        void update(bool force) { }

        C child;
    }

    void func(int age);

    alias info = Quirks!(C);
    pragma(msg, info.methods[0].name);
}