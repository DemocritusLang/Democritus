a int;
b bool;

function foo(c int, d bool) void
{
  d int;
  e bool;
  b + a; /* Error: bool + int */
}

function main() int
{
  return 0;
}
