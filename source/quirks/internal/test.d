module quirks.internal.test;

version (unittest) {
    public import fluent.asserts;

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

        struct NestedStruct {
            
        }

        class NestedClass {

        }
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

        struct NestedStruct {
            
        }

        class NestedClass {

        }
    } unittest {
        auto c = new TestClass;

        c.create.should.not.throwAnyException;
        c.name.should.equal("name");
        c.update.should.not.throwAnyException;
        c.update(false).should.not.throwAnyException;
    }

    unittest {
        create.should.not.throwAnyException;
        name.should.equal("name");
        update.should.not.throwAnyException;
        update(false).should.not.throwAnyException;
    }
}