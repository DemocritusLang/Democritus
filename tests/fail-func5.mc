function foo() int {}

function bar() int {
  a int;
  b void; /* Error: illegal local void b */
  c bool;

  return 0;
}

function main() int
{
  return 0;
}
