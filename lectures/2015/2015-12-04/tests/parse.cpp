#include "interp/parse.hpp"
#include <UnitTest++/UnitTest++.h>

#include <string>

namespace parse
{
   
  TEST(True)
  {
    CHECK(true);
  }

  TEST(TokenizeOne)
  {
    CHECK(tokenize("foo") == list<string>{"foo"});
    CHECK(tokenize("(") == list<string>{"("});
    CHECK(tokenize(")") == list<string>{")"});

    
    CHECK(tokenize("  foo ") == list<string>{"foo"});
    CHECK(tokenize(" (   ") == list<string>{"("});
    CHECK(tokenize("  )  ") == list<string>{")"});
  }

  TEST(TokenizeMore)
  {
    list<string> one {"(", ")"};
    CHECK(tokenize("()") == one);
    list<string> two {"(", "one", "two", "three", ")"};
    CHECK(tokenize(" (one two three) ") == two);
    list<string> three {"(", "a", "(", "(", "b" , "(", ")", "c", "d", ")"};
    CHECK(tokenize("(a((b()c  d )") == three);
  }

}  // namespace parse

int
main(int, const char* [])
{
    return UnitTest::RunAllTests();
}
 
