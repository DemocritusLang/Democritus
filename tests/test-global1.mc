a int;
b int;

function print_inta() void
{
  print_int(a);
}

function print_intb() void
{
  print_int(b);
}

function incab() void
{
  a = a + 1;
  b = b + 1;
}

function main() int
{
  a = 42;
  b = 21;
  print_inta();
  print_intb();
  incab();
  print_inta();
  print_intb();
  return 0;
}
