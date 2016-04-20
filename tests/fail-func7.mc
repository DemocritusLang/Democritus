function foo(a int, b bool) void
{
}

function main() int
{
  foo(42, true);
  foo(42, true, false); /* Wrong number of arguments */
}
