struct Rectangle
{
  let width int;
  let height int;
  let color struct Color;
}

struct Circle
{
  let radius int;
  let r struct Rectangle;
  let color struct Color;
}

struct Color
{
  let red bool;
}

function main() int
{
  let b bool;
  let x struct Circle;
  let c struct Color;
  x.color = c;
  x.color.red = true; 
  print("hello world\n");
  return 0;
}
