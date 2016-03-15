/* Bug noticed by Pin-Chin Huang */

function int fun(int x, int y)
{
  return 0;
}

function int main()
{
  int i;
  i = 1;

  fun(i = 2, i = i+1);

  print(i);
  return 0;
}

