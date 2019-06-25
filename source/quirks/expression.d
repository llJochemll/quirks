module quirks.expression;

/**
* Returns the same as __traits(compiles, expression)
*/
bool compiles(alias expression)() {
    return __traits(compiles, expression);
}