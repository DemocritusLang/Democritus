int a;
int b;

function void printa()
{
  print(a);
}

function void printb()
{
  print(b);
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
  printa();
  printb();
  incab();
  printa();
  printb();
  return 0;
}
