int a;
int b;

function void print_inta()
{
  print_int(a);
}

function void print_intb()
{
  print_int(b);
}

function void incab()
{
  a = a + 1;
  b = b + 1;
}

function int main()
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
