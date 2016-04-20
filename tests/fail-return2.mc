function foo() void
{
  if (true) return 42; /* Should return void */
  else return;
}

function main() int
{
  return 42;
}
