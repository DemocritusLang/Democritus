function int foo() {}

function int bar() {}

function int baz() {}

function void bar() {} /* Error: duplicate function bar */

function int main()
{
  return 0;
}
