module quirks.functional;

import quirks.utility : interpolateMixin;
import std.algorithm;
import std.array;
import std.conv;
import std.functional : unaryFun;
import std.meta;
import std.string;
import std.traits;

/// Alias for ParameterDefaults
alias ParameterDefaultValues = ParameterDefaults;
/// Alias for ParameterIdentifierTuple
alias ParameterNames = ParameterIdentifierTuple;
/// Alias for Parameters
alias ParameterTypes = std.traits.Parameters;

@safe
template FunctionAttributes(alias func) if (isCallable!func) {
    private auto attributesMixinList() {
        return [std.traits.EnumMembers!(std.traits.FunctionAttribute)]
            .filter!(attribute => std.traits.functionAttributes!func & attribute)
            .map!(attribute => attribute.to!string)
            .map!(attribute => attribute.endsWith("_") ? attribute[0 .. $ - 1] : "@" ~ attribute)
            .array;
    }
    
    enum attributes = attributesMixinList();

    alias FunctionAttributes = attributes;
}

/++
+ Get, as a tuple, a list of all parameters with their type, name and default value
+/
@safe
template Parameters(alias func) if (isCallable!func) {
    alias defaultValues = ParameterDefaultValues!func;
    alias names = ParameterNames!func;
    alias types = ParameterTypes!func;
    
    private auto parametersMixinList() {
        string[] parameters;

        static foreach (i, name; names) {
            static if (is(defaultValues[i] == void)) {
                mixin(interpolateMixin(q{
                    parameters ~= "Parameter!(types[${i}])(names[${i}])";
                }));
            } else {
                mixin(interpolateMixin(q{
                    parameters ~= "Parameter!(types[${i}], { return defaultValues[${i}]; })(names[${i}], true)";
                }));
            }
        }

        return parameters;
    }

    mixin(interpolateMixin(q{
        alias Parameters = AliasSeq!(${parametersMixinList.join(",")});
    }));
} unittest {
    import fluent.asserts;

    void temp(int age, string name = "john");

    auto parameters = Parameters!temp;

    int foo(int num, string name = "hello", int[] = [1,2,3], lazy int x = 0);
    static assert(is(ParameterDefaults!foo[0] == void));

    (is(typeof(parameters[0].defaultValue()) == void)).should.equal(true);
    parameters[1].defaultValue().should.equal("john");

    parameters[0].name.should.equal("age");
    parameters[1].name.should.equal("name");

    (is(parameters[0].type == int)).should.equal(true);
    (is(parameters[1].type == string)).should.equal(true);
}

private {
    @safe
    struct Parameter(T, alias defaultValueFunction = { return; }) {
        alias type = T;

        string name;
        bool hasDefaultValue = false;
        
        auto defaultValue() {
            return defaultValueFunction();
        }
    }
}