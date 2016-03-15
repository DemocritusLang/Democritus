function gcd(a int, b int) int {
  for (a != b)
    if (a > b) a = a - b;
    else b = b - a;
  return a;
}

function main() int
{
  print_int(gcd(14,21));
  print_int(gcd(8,36));
  print_int(gcd(99,121));
  return 0;
}
