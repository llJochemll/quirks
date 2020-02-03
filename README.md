# quirks
[![DUB](https://img.shields.io/dub/v/quirks)](http://quirks.dub.pm)
![DUB](https://img.shields.io/dub/l/quirks)

[![Build Status](https://dev.azure.com/jochemdejaeghere/github-pipes/_apis/build/status/quirks/CI?branchName=master)](https://dev.azure.com/jochemdejaeghere/github-pipes/_build/latest?definitionId=3&branchName=master)
[![Github Actions](https://github.com/lljochemll/quirks/workflows/ci/badge.svg)](https://github.com/lljochemll/quirks/actions)
[![codecov](https://codecov.io/gh/llJochemll/quirks/branch/master/graph/badge.svg)](https://codecov.io/gh/llJochemll/quirks)


quirks is a small library to simplify programming with traits and mixins.

See https://lljochemll.github.io/quirks/ for documentation and examples

For a list of "weird" things, look at the bottom

## Features
### Quirks template
Swiss army knife for getting information about things
```D
import quirks;
import std.stdio;

class User {
    uint age;
    string name;

    void talk(string message) {
        import std.stdio : writeln;

        writeln(message);
    }

    bool isSitting() {
        return false;
    }
}

auto userInstance = new User;

// can use both type and variable
alias info = Quirks!userInstance; // also works with Quirks!User

// Works at compile and runtime
pragma(msg, info.methods.length); // 2
pragma(msg, info.fields.length); // 2
pragma(msg, info.members.length); // 4
pragma(msg, info.isAggregate); // true
pragma(msg, info.methods[0].name); // talk
pragma(msg, info.methods[0].parameters[0].name); // message
pragma(msg, info.methods.filter!(m => is(m.returnType == bool)).filter!(m => true)[0].name); // isSitting
pragma(msg, info.methods.filter!(m => m.parameters.filter!(p => p.name == "message").length > 0)[0].name); // talk 
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
## Weird things
### AliasTuple
```AliasTuple``` has some weird things going on

TL;DR: use .tuple if you want to be sure it will always work

While it is possible to do this:
```D
alias things = AliasTuple!(bool, string, "hi");

pragma(msg, things[0]); // displays bool
pragma(msg, things[2].length); // displays 2
```
This will not work:
```D
alias things = AliasTuple!(bool, string, "hi");

pragma(msg, is(things[0] == bool); // displays false
```
But this will:
```D
alias things = AliasTuple!(bool, string, "hi");

pragma(msg, is(things.tuple[0] == bool); // displays true
pragma(msg, things[2].length == 2); // displays true
pragma(msg, things.tuple[2].length == 2); // displays true
```

### Modules
While using this library on a module will work, it is far from perfect. For now only use ```MemberNames``` if you want to know what is inside a module. other methods like ```Members``` or ```Fields``` might compile but probably won't result in what you'd think.