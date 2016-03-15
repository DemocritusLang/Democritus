int main()
{
  int i;

  for (true) {
    i = i + 1;
  }

  for (true) {
    foo(); /* foo undefined */
  }

}
