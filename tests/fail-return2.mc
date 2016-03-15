function void foo()
{
  if (true) return 42; /* Should return void */
  else return;
}

function int main()
{
  return 42;
}
