/* Bug noticed by Pin-Chin Huang */

function fun(x int, y int) int
{
  return 0;
}

function main() int
{
  let i int;
  i = 1;

  fun(i = 2, i = i+1);

  print_int(i);
  return 0;
}

