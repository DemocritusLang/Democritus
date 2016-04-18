function main() int
{
  let i int;
  i = 0;
  for ( ; i < 5; ) {
    print_int(i);
    i = i + 1;
  }
  print_int(42);
  return 0;
}
