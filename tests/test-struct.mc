struct Rectangle
{
  int width;
  int height;
}

struct Circle
{
  int radius;
}

function int main()
{
  bool b;
  int y;
  struct Circle x;
  x.radius=4;
  y = x.radius + 6; 
  print_int(y);
  print("hello world\n");
  return 0;
}
