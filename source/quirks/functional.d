module quirks.functional;

import std.functional : unaryFun;
import std.meta;
import std.traits;

/// Alias for ParameterDefaults
alias ParameterDefaultValues = ParameterDefaults;
/// Alias for ParameterIdentifierTuple
alias ParameterNames = ParameterIdentifierTuple;
/// Alias for Parameters
alias ParameterTypes = std.traits.Parameters;

/++
+ Get, as a tuple, a list of all parameters with their type, name and default value
+/
@safe
template Parameters(alias func) if (isCallable!func) {
    alias Parameters = NextParameter!(func, 0);
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

package {
    @safe
    struct Callable(alias thing) if (isCallable!thing) {
        alias parameters = Parameters!thing;
    }

    @safe 
    struct Delegate(alias thing) {
        alias callable this;

        Callable!thing callable;
    }
    
    @safe 
    struct Function(alias thing) {
        alias callable this;

        Callable!thing callable;
        string name = thing.stringof;
    }

    @safe 
    struct FunctionPointer(alias thing) {
        alias callable this;

        Callable!thing callable;
        string name = thing.stringof;
    }
}

private {
    @safe
    struct Parameter(T, alias defaultValueFunction = { return; }) {
        alias type = T;

        string name;
        bool hasDefaultValue = false;
        
        auto defaultValue() {
            return m_defaultValue();
        }

        private {
            alias m_defaultValue = defaultValueFunction;
        }
    }

    @safe
    template NextParameter(alias func, ulong i, DoneParameters...) {
        alias defaultValues = ParameterDefaultValues!func;
        alias names = ParameterNames!func;
        alias types = ParameterTypes!func;

        static if (i >= names.length) {
            alias NextParameter = DoneParameters;
        } else {
            static if (is(defaultValues[i] == void)) {
                alias NextParameter = NextParameter!(func, i + 1, AliasSeq!(DoneParameters, Parameter!(types[i])(names[i])));
            } else {
                alias NextParameter = NextParameter!(func, i + 1, AliasSeq!(DoneParameters, Parameter!(types[i], { return defaultValues[i]; })(names[i], true)));
            }
        }
    }
}