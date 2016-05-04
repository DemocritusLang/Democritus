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
  let red bool;
}

function main() int
{
  let b bool;
  let x struct Circle;
  x.cool=true;
  b = x.cool; 
  
  x.color.red = true;
/*  x.color.red = true;
*/
  print("hello world\n");
  return 0;
}
