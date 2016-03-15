function int foo() {}

function int bar() {
  int a;
  void b; /* Error: illegal void local b */
  bool c;

  return 0;
}

function int main()
{
  return 0;
}
