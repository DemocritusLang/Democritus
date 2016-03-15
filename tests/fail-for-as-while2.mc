function main() int
{
  i int;

  for (true) {
    i = i + 1;
  }

  for (true) {
    foo(); /* foo undefined */
  }

}
