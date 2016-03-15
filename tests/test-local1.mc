function foo(i bool) void
{
  i int; /* Should hide the formal i */

  i = 42;
  print_int(i + i);
}

function main() int
{
  foo(true);
  return 0;
}
