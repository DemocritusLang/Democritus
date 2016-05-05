struct Rectangle
{
  let width int;
  let height int;
  let color struct Color;
}

struct Circle
{
  let radius int;
  let cool bool;
  let color struct Color;
}

struct Color
{
  let red int;
  let color2 struct Test;
}

struct Test
{
  let number int;
}

function main() int
{
  let a int;
  let b bool;
  let x struct Circle;
  let inside struct Color;
  
  x.color = inside;
  
  x.color.red = 1;
(*  x.color.color2.number = 2; *)
  
  print("hello world\n");
  return 0;
}
