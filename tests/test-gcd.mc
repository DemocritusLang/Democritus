function gcd(a int, b int) int {
  for (a != b) {
    if (a > b) a = a - b;
    else b = b - a;
  }
  return a;
}

function main() int
{
  print_int(gcd(2,14));
  print_int(gcd(3,15));
  print_int(gcd(99,121));
  return 0;
}
