let a int;
let b bool;

function foo(c int, d bool) void
{
  let dd int;
  let e bool;
  a + c;
  c - a;
  a * 3;
  c / 2;
  d + a; /* Error: bool + int */
}

function main() int
{
  return 0;
}
