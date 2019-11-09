module quirks.internal.test;

public import fluent.asserts;

struct TestStruct {
    static long classifier;

    long id;
    int age;

    static TestStruct create() {
        return TestStruct();
    }

    string name() {
        return "name";
    }
    void update() { }
    void update(bool force) { }
} unittest {
    TestStruct s;

    s.create.should.not.throwAnyException;
    s.name.should.equal("name");
    s.update.should.not.throwAnyException;
    s.update(false).should.not.throwAnyException;
}

class TestClass {
    static long classifier;

    long id;
    int age;

    static TestClass create() {
        return new TestClass();
    }

    string name() {
        return "name";
    }
    void update() { }
    void update(bool force) { }
} unittest {
    auto c = new TestClass;

    c.create.should.not.throwAnyException;
    c.name.should.equal("name");
    c.update.should.not.throwAnyException;
    c.update(false).should.not.throwAnyException;
}