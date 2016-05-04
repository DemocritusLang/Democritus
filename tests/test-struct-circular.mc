struct A
{
  struct B b;
}

struct B
{
  struct C c;
}

struct C
{
 struct A a;
}

function int main()
{
  bool b;
  struct A x;
  print("hello world\n");
  return 0;
}
