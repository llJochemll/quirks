module quirks.utility;

import std.algorithm;
import std.string;

/++
+ Takes code in the form of a string and interpolates variables defined in the form of ${variableName}.
+ Usefull in combination with the q{} string literal, to keep syntax highlighting for mixed in code and avoid string concatenations, which keeps the code readable
+
+ Params: 
+   code = code to be mixed in
+
+ Example:
+ ---
+ class Foo {
+     int id = 1;
+     uint age = 23;
+     string name = "foo";
+ }
+
+ auto foo = new Foo;
+
+ static foreach (member; FieldNameTuple!(Foo)) {
+     mixin(interpolateMixin(q{
+         writeln("Field ${member} has a value of: ", foo.${member});
+     }));
+ }
+ ---
+/
@safe
pure nothrow static string interpolateMixin(string code) {
	string interpolatedCode = "";

	auto insideInterpolation = false;
	string interpolatedFragment = "";
	string[] interpolatedFragments = [];
	auto leftBlockCount = 0;
	auto rightBlockCount = 0;
	auto paramCount = 0;

	foreach (i, c; code) {
		if (insideInterpolation) {
			if (c == '{') {
				leftBlockCount++;

				if (leftBlockCount == 1) {
					continue;
				}
			} else if (c == '}') {
				rightBlockCount++;

				if (leftBlockCount == rightBlockCount) {
					interpolatedFragments ~= interpolatedFragment;

					interpolatedFragment = "";
					insideInterpolation = false;
					leftBlockCount = 0;
					rightBlockCount = 0;

					continue;
				}
			}

			interpolatedFragment ~= c;
		} else if (c == '$' && code[i + 1] == '{') {
			insideInterpolation = true;
			paramCount++;

			interpolatedCode ~= "%s";
		} else {
			if (c == '"') {
				interpolatedCode ~= `\`;
			}

			interpolatedCode ~= c;
		}
	}

	return `import std.string : join; static import std.string;mixin(std.string.format("` ~ interpolatedCode ~ `", ` ~ interpolatedFragments.join(",") ~ `));`;
} unittest {
	import fluent.asserts;

	enum firstname = "first";
	enum lastname = "last";

	mixin(interpolateMixin(q{
		string name = "${firstname}" ~ "${lastname}";
	}));

	name.should.equal("firstlast");
}