module quirks.tuple;

static import std.traits;
import quirks.core : Quirks;
import quirks.utility : interpolateMixin;
import std.conv;
import std.functional : unaryFun;
import std.meta;

@safe
template AliasTuple(T...) {
    private template Join(T...) {
        static if (T.length == 1 && is(typeof(T[0].tuple))) {
            alias Join = AliasTuple!(tuple, T[0].tuple);
        } else {
            alias Join = AliasTuple!(tuple, T);
        }
    }
    
    alias tuple = T;

    enum length = T.length; 

    alias filter(alias predicate) = FilterTuple!(predicate, tuple);
    alias join(T...) = Join!T;
}

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
template FilterTuple(T...) if (T.length > 0 && is(typeof(unaryFun!(T[0])))) {
    private auto getElementsMixinList() {
        string[] elements;

        static foreach (i, element; T) {
            static if (i > 0) {
                static if (__traits(compiles, T[0](element))) {
                    static if (i > 0 && T[0](element)) {
                        elements ~= "T[" ~ i.to!long.to!string ~ "]";
                    }
                } else {
                    static assert(false, "One of the elements provided is not a value. " ~
                        "This can be the case if the element is a type (i.e. int) or a template. "
                    );
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
    result1.tuple[0].should.equal(0.5);

    alias result2 = FilterTuple!(a => isNumeric!a, tuple);
    result2.length.should.equal(2);
    result2.tuple[0].should.equal(1);
    result2.tuple[1].should.equal(0.5);
}