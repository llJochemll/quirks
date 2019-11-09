module quirks.expression;

import std.meta;
import std.traits;

/++
+ Returns is the given thing is either a static function or a static declaration declaration
+
+ Example:
+ ---
+ struct S {
+     static long id;
+     int age;
+     static string name() {
+         return "name";
+     }
+     void update(bool force) { }
+ }
+ 
+ isStatic!(S.id); // true
+ isStatic!(S.age); // false
+ isStatic!(S.name); // true
+ isStatic!(S.update); // false
+ ---
+/
@safe
template isStatic(alias thing) {
    static if (isSomeFunction!thing) {
        alias isStatic = Alias!(__traits(isStaticFunction, thing));
    } else {
        alias isStatic = Alias!(__traits(compiles, &thing));
    }
} unittest {
    import quirks.internal.test;

    TestStruct s;
    auto c = new TestClass;

    isStatic!(TestStruct.classifier).should.equal(true);
    isStatic!(s.classifier).should.equal(true);
    isStatic!(TestStruct.age).should.equal(false);
    isStatic!(s.age).should.equal(false);
    isStatic!(TestStruct.create).should.equal(true);
    isStatic!(s.create).should.equal(true);
    isStatic!(TestStruct.update).should.equal(false);
    isStatic!(s.update).should.equal(false);

    isStatic!(TestClass.classifier).should.equal(true);
    isStatic!(c.classifier).should.equal(true);
    isStatic!(TestClass.age).should.equal(false);
    isStatic!(c.age).should.equal(false);
    isStatic!(TestClass.create).should.equal(true);
    isStatic!(c.create).should.equal(true);
    isStatic!(TestClass.update).should.equal(false);
    isStatic!(c.update).should.equal(false);
}