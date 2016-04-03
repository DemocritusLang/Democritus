function int gcd(int a, int b) {
  for (a != b) {
    if (a > b) a = a - b;
    else b = b - a;
  }
  return a;
}

function int main()
{
  print_int(gcd(2,14));
  print_int(gcd(3,15));
  print_int(gcd(99,121));
  return 0;
}
