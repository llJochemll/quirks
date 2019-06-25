module quirks.functional;

import std.meta;
import std.traits;

/**
* Get, as a tuple, a list of all parameters with their type, name and default value
*/
alias getParameters = GetParameters;
/// Alias for ParameterDefaults
alias getParameterDefaultValues = ParameterDefaults;
/// Alias for ParameterIdentifierTuple
alias getParameterNames = ParameterIdentifierTuple;
/// Alias for Parameters
alias getParameterTypes = Parameters;
/// Alias for ReturnType
alias getReturnType = ReturnType;

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
    template GetParameters(alias func) if (isCallable!func) {
        alias GetParameters = NextParameter!(func, 0);
    } unittest {
        import fluent.asserts;

        void temp(int age, string name = "john");

        auto parameters = getParameters!temp;

        int foo(int num, string name = "hello", int[] = [1,2,3], lazy int x = 0);
        static assert(is(ParameterDefaults!foo[0] == void));

        (is(typeof(parameters[0].defaultValue()) == void)).should.equal(true);
        parameters[1].defaultValue().should.equal("john");

        parameters[0].name.should.equal("age");
        parameters[1].name.should.equal("name");

        (is(parameters[0].type == int)).should.equal(true);
        (is(parameters[1].type == string)).should.equal(true);
    }

    @safe
    template NextParameter(alias func, ulong i, DoneParameters...) {
        alias defaultValues = getParameterDefaultValues!func;
        alias names = getParameterNames!func;
        alias types = getParameterTypes!func;

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