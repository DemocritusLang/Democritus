function int foo(int a, bool b, int c) { }

function void bar(int a, void b, int c) {} /* Error: illegal void formal b */

function int main()
{
  return 0;
}