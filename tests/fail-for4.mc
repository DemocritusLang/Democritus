function main() int
{
  i int;

  for (i = 0; i < 10 ; i = j + 1) {} /* j undefined */

  return 0;
}
