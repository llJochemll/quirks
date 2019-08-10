# quirks
[![Build Status](https://dev.azure.com/jochemdejaeghere/github-pipes/_apis/build/status/quirks/CI?branchName=master)](https://dev.azure.com/jochemdejaeghere/github-pipes/_build/latest?definitionId=3&branchName=master)
[![codecov](https://codecov.io/gh/llJochemll/quirks/branch/master/graph/badge.svg)](https://codecov.io/gh/llJochemll/quirks)

quirks is a small library to facilitate programming with traits and mixins.<br/>
See https://lljochemll.github.io/quirks/ for documentation and examples

Note: the API is very unstable right now as I'm experimenting with what I think is useful

Some features:

### Quirks template
Swiss army knife for getting information about things
```D
import quirks;
import std.stdio;

struct User {
    uint age;
    string name;

    void talk(string message) {
        import std.stdio : writeln;

        writeln(message);
    }
}

alias quirks = Quirks!User;

writeln(quirks.methods.length); // 1
writeln(quirks.fields.length); // 2
writeln(quirks.methods[0].name); // talk
```

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
static foreach (member; FieldNameTuple!(Foo)) {
    mixin(interpolateMixin(q{
        writeln("Field ${member} has a value of: ", foo.${member});
    }));
}

// version without
static foreach (member; FieldNameTuple!(Foo)) {
    mixin(`
        writeln("Field ` ~ member ~ ` has a value of: ", foo.` ~ member ~ `);
    `);
}
```

### hasMember, hasField, hasMethod
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

static assert(hasField!(S, "id"));
static assert(!hasField!(S, "name"));
static assert(!hasField!(S, "doesNotExist"));

static assert(!hasMethod!(S, "id"));
static assert(hasMethod!(S, "name"));
static assert(!hasMethod!(S, "doesNotExist"));
static assert(hasMethod!(S, method => is(method.returnType == string)));
```

### Parameters
```D
import quirks;
import std.stdio;

uint calculateAge(long birthYear, string planet = "earth");

alias parameters = Parameters!calculateAge;

static foreach (parameter; parameters) {
    write("Parameter " , parameter.name, " has a type of ", parameter.type.stringof);

    static if (parameter.hasDefaultValue) {
        writeln(" and a default value of ", parameter.defaultValue);
    } else {
        writeln(" and no default value");
    }
}
```
