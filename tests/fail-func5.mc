function foo() int {}

function bar() int {
  let a int;
  let b void; /* Error: illegal local void b */
  let c bool;

  return 0;
}

function main() int
{
  return 0;
}
