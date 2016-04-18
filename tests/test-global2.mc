let i bool;

function main() int
{
  let i int; /* Should hide the global i */

  i = 42;
  print_int(i + i);
  return 0;
}
