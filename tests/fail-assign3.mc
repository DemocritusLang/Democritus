function myvoid() void
{
  return;
}

function main() int
{
  i int;

  i = myvoid(); /* Fail: assigning a to void an integer */
}
