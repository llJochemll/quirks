module quirks.tuple;

static import std.traits;
import quirks.core : Quirks;
import quirks.utility : interpolateMixin;
import std.conv;
import std.functional : unaryFun;
import std.meta;

/++
+ Wrapper around AliasSeq
+ 
+ Example:
+ ---
+ alias seq = AliasTuple!(1, "hello", 0.5, [1, 2, 3]);
+
+ seq.tuple; // gives the original tuple
+ seq.length; // 4
+ seq.filter!(a => isNumeric!a); // gives AliasTuple!(1, 0.5)
+ ---
+/
@safe
struct AliasTuple(T...) {
    private template Join(T...) {
        static if (T.length == 1 && is(typeof(T[0].tuple))) {
            alias Join = AliasTuple!(tuple, T[0].tuple);
        } else {
            alias Join = AliasTuple!(tuple, T);
        }
    }
    
    alias tuple = T;
    alias tuple this;

    enum length = T.length; 

    alias filter(alias predicate) = FilterTuple!(predicate, tuple);
    alias join(T...) = Join!T;
    alias map(alias predicate) = MapTuple!(predicate, tuple);
} unittest {
    import fluent.asserts;

    alias seq = AliasSeq!(bool, false, int, 0, string, "hi");
    alias tuple = AliasTuple!seq;

    tuple.length.should.equal(seq.length);
    tuple.join!(seq).length.should.equal(seq.length * 2);
}

/++
+ Takes a tuple and filters it with the given predicate or template.
+ 
+ Example:
+ ---
+ alias tuple = AliasSeq!(1, "hello", 0.5, [1, 2, 3]);
+
+ FilterTuple!(a => is(typeof(a) == double), tuple); // gives AliasTuple!(0.5)
+ FilterTuple!(a => isNumeric!a, tuple); // gives AliasTuple!(1, 0.5)
+ FilterTuple!(isNumeric, tuple); // gives AliasTuple!(1, 0.5)
+ ---
+/
@safe
template FilterTuple(alias pred, T...) {
    private auto getElementsMixinList() {
        string[] elements;

        static foreach (i, element; T) {
            static if (__traits(compiles, pred(element))) {
                static if (pred(element)) {
                    elements ~= "T[" ~ i.to!string ~ "]";
                }
            } else {
                static if (pred!element) {
                    elements ~= "T[" ~ i.to!string ~ "]";
                }
            }
        }

        return elements;
    }

    mixin(interpolateMixin(q{
        alias FilterTuple = AliasTuple!(${getElementsMixinList.join(",")});
    }));
} unittest {
    import fluent.asserts;
    import quirks.core : Quirks;
    import quirks.type : isNumeric;

    alias tuple = AliasSeq!(1, "hello", 0.5, [1, 2, 3]);

    alias result1 = FilterTuple!(a => is(typeof(a) == double), tuple);
    result1.length.should.equal(1);
    result1[0].should.equal(0.5);

    alias result2 = FilterTuple!(a => isNumeric!a, tuple);
    result2.length.should.equal(2);
    result2[0].should.equal(1);
    result2[1].should.equal(0.5);
}

/++
+ Takes a tuple and maps it with the given function or template.
+ 
+ Example:
+ ---
+ alias tuple = AliasSeq!(1, "hello", 1L, [1, 2, 3]);
+
+ MapTuple!(a => a.to!string, tuple); // gives AliasTuple!("1", "hello", "1", "[1, 2, 3]")
+ MapTuple!(Quirks, tuple); // gives AliasTuple!(Quirks!(1), Quirks!("hello"), Quirks!(1L), Quirks!([1, 2, 3]))
+ ---
+/
@safe
template MapTuple(alias mapper, T...) {
    private auto getElementsMixinList() {
        string[] elements;

        static foreach (i, element; T) {
            static if (__traits(compiles, mapper(element))) {
                elements ~= "mapper(T[" ~ i.to!string ~ "])";
            } else {
                elements ~= "mapper!(T[" ~ i.to!string ~ "])";
            }
        }

        return elements;
    }

    mixin(interpolateMixin(q{
        alias MapTuple = AliasTuple!(${getElementsMixinList.join(",")});
    }));
} unittest {
    import fluent.asserts;
    import quirks.core : Quirks;
    import quirks.type : isNumeric;

    alias tuple = AliasSeq!(1, "hello", 1L, [1, 2, 3]);

    alias result1 = MapTuple!(a => a.to!string, tuple);
    result1.length.should.equal(4);
    result1[0].should.equal("1");

    alias result2 = MapTuple!(Quirks, tuple);
    result2.length.should.equal(4);
    result2[0].isBasic.should.equal(true);
}