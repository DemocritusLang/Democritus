function int main()
{
  int i;

  for (true) {
    i = i + 1;
  }

  for (42) { /* Should be boolean */
    i = i + 1;
  }

}
