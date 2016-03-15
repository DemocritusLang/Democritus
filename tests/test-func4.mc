function add(a int, b int) int
{
  c int;
  c = a + b;
  return c;
}

function main() int
{
  d int;
  d = add(52, 10);
  print_int(d);
  return 0;
}
