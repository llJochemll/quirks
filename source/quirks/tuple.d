module quirks.tuple;

import quirks.utility : interpolateMixin;
import std.conv;
import std.meta;

@safe
template filterTuple(T...) if (T.length > 1) {
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
        alias filterTuple = AliasSeq!(${getElementsMixinList.join(",")});
    }));
}