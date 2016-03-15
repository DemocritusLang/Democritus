function int foo(int a, bool b, int c) { }

function void bar(int a, bool b, int a) {} /* Error: duplicate formal a in bar */

function int main()
{
  return 0;
}
