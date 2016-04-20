function foo(a int, b bool) void
{
}

function main() int
{
  foo(42, true);
  foo(42, 42); /* Fail: int, not bool */
}
