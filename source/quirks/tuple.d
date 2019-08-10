module quirks.tuple;

import quirks.utility : interpolateMixin;
import std.conv;
import std.meta;

/++
+ Takes a tuple and filters it with the given aggregate.
+ 
+ Example:
+ ---
+ alias tuple = AliasSeq!(1, "hello", 0.5, [1, 2, 3]);
+
+ FilterTuple!(a => is(typeof(a) == double), tuple); // gives (0.5)
+ FilterTuple!(a => isNumeric!a, tuple); // gives (1, 0.5)
+ ---
+/
@safe
template FilterTuple(T...) if (T.length > 0) {
    auto getElementsMixinList() {
        string[] elements;

        static foreach (i, element; T) {
            static if (i > 0 && T[0](element)) {
                elements ~= "T[" ~ i.to!long.to!string ~ "]";
            }
        }

        return elements;
    }

    mixin(interpolateMixin(q{
        alias FilterTuple = AliasSeq!(${getElementsMixinList.join(",")});
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