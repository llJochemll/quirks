module quirks.expression;

import std.traits;

@safe
template isStatic(alias thing) {
    static if (isSomeFunction!thing) {
        enum stat = __traits(isStaticFunction, thing);
    } else {
        enum stat = __traits(compiles, &thing);
    }

    alias isStatic = stat;
} unittest {
    import fluent.asserts;

    struct S {
        static long id;
        int age;
        static string name() {
            return "name";
        }
        void update(bool force) { }
    }

    class C {
        static long id;
        int age;
        static string name() {
            return "name";
        }
        void update(bool force) { }
    }

    S s;
    auto c = new C;

    isStatic!(S.id).should.equal(true);
    isStatic!(s.id).should.equal(true);
    isStatic!(S.age).should.equal(false);
    isStatic!(s.age).should.equal(false);
    isStatic!(S.name).should.equal(true);
    isStatic!(s.name).should.equal(true);
    isStatic!(S.update).should.equal(false);
    isStatic!(s.update).should.equal(false);

    isStatic!(C.id).should.equal(true);
    isStatic!(c.id).should.equal(true);
    isStatic!(C.age).should.equal(false);
    isStatic!(c.age).should.equal(false);
    isStatic!(C.name).should.equal(true);
    isStatic!(c.name).should.equal(true);
    isStatic!(C.update).should.equal(false);
    isStatic!(c.update).should.equal(false);
}