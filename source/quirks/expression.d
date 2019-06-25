module quirks.expression;

/**
* Returns the same as __traits(compiles, expression)
*/
@safe
pure bool compiles(alias expression)() {
    return __traits(compiles, expression);
}