function void foo(int a, bool b)
{
}

function void bar()
{
}

function int main()
{
  foo(42, true);
  foo(42, bar()); /* int and void, not int and bool */
}
