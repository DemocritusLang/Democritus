int a;
bool b;

function void foo(int c, bool d)
{
  int d;
  bool e;
  b + a; /* Error: bool + int */
}

function int main()
{
  return 0;
}
