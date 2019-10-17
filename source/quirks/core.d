module quirks.core;

static import quirks.aggregate;
static import quirks.expression;
static import quirks.type;
static import std.traits;
import quirks.aggregate : Fields, MemberNames, Members, Methods;
import quirks.expression : isStatic;
import quirks.functional : Parameters, FunctionAttributes;
import quirks.tuple : AliasTuple;
import quirks.type : SimpleTypeOf, TypeOf;
import quirks.utility : interpolateMixin;
import std.meta;

/++
+ Swiss army knife for getting information about things.
+ 
+ Takes thing and tries to apply a list of functions and templates to it. All that compile can be accessed using property syntax on the resulting alias.
+ 
+ The code for this is generated during compile-time using traits and mixins. Below is a list of properties that are possible to access (note not all will be available for every instantiation):
+ $(UL
+ $(LI attributes)
+ $(LI fields -> see `Fields`)
+ $(LI functionAttributes -> see `FunctionAttributes`)
+ $(LI isAggregate -> see `isAggregate`)
+ $(LI isArray -> see `isArray`)
+ $(LI isAssociativeArray -> see `isAssociativeArray`)
+ $(LI isBasic -> see `isBasic`)
+ $(LI isModule -> see `isModule`)
+ $(LI isNested)
+ $(LI isNumeric -> see `isNumeric`)
+ $(LI isSomeString -> see `isSomeString`)
+ $(LI isStatic -> see `isStatic`)
+ $(LI memberNames -> see `MemberNames`)
+ $(LI members -> see `Members`)
+ $(LI methods -> see `Methods`)
+ $(LI name)
+ $(LI parameters -> see `Parameters`)
+ $(LI qualifiedName)
+ $(LI returnType)
+ $(LI simpleType -> see `SimpleTypeOf`)
+ $(LI type)
+ )
+
+ In addition, the following properties that require a template parameter are also available: 
+ $(UL
+ $(LI fieldsFilter(alias predicate) -> returns the fields property filtered with the given predicate)
+ $(LI getUDAs(alias uda) -> returns the same as getUDAs from std.traits)
+ $(LI getUDA(alias uda) -> returns the first result returned by getUDAs)
+ $(LI hasField(alias predicate) -> see `hasField`)
+ $(LI hasMember(alias predicate) -> see `hasMember`)
+ $(LI hasMethod(alias predicate) -> see `hasMethod`)
+ $(LI hasUDA(alias uda) -> return the same as hasUDA from std.traits)
+ $(LI membersFilter(alias predicate) -> returns the members property filtered with the given predicate)
+ $(LI methodsFilter(alias predicate) -> returns the methods property filtered with the given predicate)
+ )
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
+ Quirks!S.type; // S
+ Quirks!S.fields.length; // 2
+ Quirks!S.methods[1].name; //update
+ Quirks!S.isArray; // false
+ Quirks!S.methods[1].parameters[0].type; // bool
+ ---
+/
template Quirks(alias thing) {
    alias quirksAliasTuple = AliasSeq!(
        "attributes", q{AliasTuple!(__traits(getAttributes, thing))},
        "fields", q{Fields!thing},
        "functionAttributes", q{FunctionAttributes!thing},
        "isAggregate", q{quirks.type.isAggregate!thing},
        "isArray", q{quirks.type.isArray!thing},
        "isAssociativeArray", q{quirks.type.isAssociativeArray!thing},
        "isBasic", q{quirks.type.isBasic!thing},
        "isModule", q{quirks.type.isModule!thing},
        "isNested", q{isNested!thing},
        "isNumeric", q{quirks.type.isNumeric!thing},
        "isSomeFunction", q{quirks.type.isSomeFunction!thing},
        "isSomeString", q{quirks.type.isSomeString!thing},
        "isStatic", q{quirks.expression.isStatic!thing},
        "memberNames", q{MemberNames!thing},
        "members", q{Members!thing},
        "methods", q{Methods!thing},
        "parameters", q{Parameters!thing},
        "qualifiedName", q{std.traits.fullyQualifiedName!thing},
        "returnType", q{std.traits.ReturnType!thing},
        "simpleType", q{SimpleTypeOf!thing},
        "type", q{TypeOf!thing},
        q{fieldsFilter(alias predicate)}, q{Fields!(thing, predicate)},
        q{getUDAs(alias uda)}, q{std.traits.getUDAs!(thing, uda)},
        q{getUDA(alias uda)}, q{getUDAs!uda[0]},
        q{hasField(alias predicate)}, q{quirks.aggregate.hasField!(thing, predicate)},
        q{hasMember(alias predicate)}, q{quirks.aggregate.hasMember!(thing, predicate)},
        q{hasMethod(alias predicate)}, q{quirks.aggregate.hasMethod!(thing, predicate)},
        q{hasUDA(alias uda)}, q{std.traits.hasUDA!(thing, uda)},
        q{membersFilter(alias predicate)}, q{Members!(thing, predicate)},
        q{methodsFilter(alias predicate)}, q{Methods!(thing, predicate)},
    );

    alias quirksEnumTuple = AliasSeq!(
        "name", q{__traits(identifier, thing)},
    );

    alias quirksTemplateTuple = AliasSeq!(
        
    );

    struct QuirksStruct {
        static foreach (i, expression; quirksAliasTuple) {
            static if (i % 2 == 1) {
                mixin(interpolateMixin(q{
                    static if (__traits(compiles, {alias ${quirksAliasTuple[i - 1]} = ${expression};})) {
                        public alias ${quirksAliasTuple[i - 1]} = ${expression};
                    }
                }));
            }
        }

        static foreach (i, expression; quirksEnumTuple) {
            static if (i % 2 == 1) {
                mixin(interpolateMixin(q{
                    static if (__traits(compiles, ${expression})) {
                        public enum ${quirksEnumTuple[i - 1]} = (${expression});
                    }
                }));
            }
        }
    }

    private enum QuirksStruct value = QuirksStruct();

    alias Quirks = value;
}