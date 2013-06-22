Scannerless Generalized LL for Lua
==================================

This is not a final product, just a very small research project. The
project aims at seeing how a generalized LL parser would perform when
generated for LuaJIT. There are some "pragmatic" optimizations
compared to the original paper from Scott and Johnstone, which
constists on making pure LL grammars to perform like locally pure LL
adding the "generalized" only in places required. Also there are some
optimization related to scannerless filtering that are required.

If you do not understand, this is not for you.

Known problems:

* When there are possible ambiguities we cannot have tail calls. For
  that reason the stack might explode easily on very ambiguous
  grammars. It does not happen when the grammar is pure LL.
* There is a table used as a set where we need to use "pairs" to list
  everything in the set which is not compiled by the JIT compiler.
* Scannerless is making the grammars very "generlized" which is very
  slow.

Possible future improvements:

* I need to include lexical restriction filtering the proper way like
  SDF has. We have a lot of ambiguities that avoid tail calls due to
  local ambiguities. Since we do for the moment filtering after
  parsing, we cannot know at compile time whether the result could be
  never ambiguous.  Lexical restrictions should allow to write code a
  parser without ambiguities.
* It would be nice to have variable look-ahead size depending on what
  is required. This should be useful for example when a long literal
  is in set FIRST. The size of the look-ahead should be the size of
  the longest literal in FIRST plus one. That way we could already
  filter ambiguities due to scannerless parsing ahead.
* We could have a better tree that is tolerant to ambiguities. That
  said, with a properly non-ambiguous grammar, this should not be
  important. Parsing natural languages is not a goal here.
* Making a profiler to nicely show what should be optimized in a grammar.
* It is probable that we can do transformation of grammar
  automatically that makes it more pure LL, and generate in the same
  time a transformation that is able to convert it back to a parse
  tree that looks like it was done using the original grammar.

To use it
---------

There are some examples in the root. The code itself is in directory
"gll". Just run one of the of the script in the root.
