function main() int
{
  i int;
  b bool;

  i = 42;
  i = 10;
  b = true;
  b = false;
  i = false; /* Fail: assigning a to bool an integer */
}
