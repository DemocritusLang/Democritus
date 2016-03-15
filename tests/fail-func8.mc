function foo(a int, b bool) void
{
}

function bar() void
{
}

function main() int
{
  foo(42, true);
  foo(42, bar()); /* and int void, not and int bool */
}
