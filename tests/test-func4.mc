function add(a int, b int) int
{
  let c int;
  c = a + b;
  return c;
}

function main() int
{
  let d int;
  d = add(52, 10);
  print_int(d);
  return 0;
}
