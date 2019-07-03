# quirks
[![Build Status](https://dev.azure.com/jochemdejaeghere/github-pipes/_apis/build/status/quirks/CI?branchName=master)](https://dev.azure.com/jochemdejaeghere/github-pipes/_build/latest?definitionId=3&branchName=master)

Quirks is a small library to facilitate programming with traits and mixins.

Some features:

### interpolateMixin
Adds string interpolation to mixins
```D
import quirks;
import std.stdio;

class Foo {
    int id = 1;
    uint age = 23;
    string name = "foo";
}

auto foo = new Foo;

// version with interpolateMixin
static foreach(member; FieldNameTuple!(Foo)) {
    mixin(interpolateMixin(q{
        writeln("Field ${member} has a value of: ", foo.${member});
    }));
}

// version without
static foreach(member; FieldNameTuple!(Foo)) {
    mixin(`
        writeln("Field ` ~ member ~ ` has a value of: ", foo.` ~ member ~ `);
    `);
}
```

### hasMember, hasMethod, hasField
```D
import quirks;

struct Foo {
    long id;
    string name() {
        return "name";
    }
}

static assert(hasMember!(S, "id"));
static assert(hasMember!(S, "name"));
static assert(!hasMember!(S, "doesNotExist"));

static assert(!hasMethod!(S, "id"));
static assert(hasMethod!(S, "name"));
static assert(!hasMethod!(S, "doesNotExist"));

static assert(hasField!(S, "id"));
static assert(!hasField!(S, "name"));
static assert(!hasField!(S, "doesNotExist"));
```

### getParameters, getParameterDefaultValues, getParameterNames, getParameterTypes, getReturnType
```D
import quirks;
import std.stdio;

uint calculateAge(long birthYear, string planet = "earth");

alias parameters = getParameters!calculateAge;

static foreach (parameter; parameters) {
    write("Parameter " , parameter.name, " has a type of ", parameter.type.stringof);

    static if (parameter.hasDefaultValue) {
        writeln(" and a default value of ", parameter.defaultValue);
    } else {
        writeln(" and no default value");
    }
}
```