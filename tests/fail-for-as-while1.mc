function main() int
{
  i int;

  for (true) {
    i = i + 1;
  }

  for (42) { /* Should be boolean */
    i = i + 1;
  }

}
