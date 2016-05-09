struct Rectangle
{
  let width int;
  let height int;
  let color struct Test_Struct;
}

struct Circle
{ 
  let radius int;
  let extra_struct struct Test_Struct;
}

struct Test_Struct
{
  let color struct Color; 
  let poop bool;
  let number int;
}

struct Color
{
  let red int;
}

function main() int
{
  
  let a int;
  let b int;
  let c int;
  let d int; 
  let e int;
 
  let circle struct Circle;
  let test struct Test_Struct;
  let test_color struct Color;
 
 
  test_color.red = 696969;
 
  test.number = 10000000;
  test.color = test_color; 

  circle.extra_struct = test;

  circle.extra_struct.number = 42;
  circle.extra_struct.color.red = 69;

  a = test.color.red;
  b = circle.extra_struct.color.red;
  c = test.number;
  d = circle.extra_struct.number;
  circle.extra_struct.color.red = circle.extra_struct.color.red + 1;
  e = circle.extra_struct.color.red;

  print_int(a);  
  print_int(b);
  print_int(c);
  print_int(d);
  print_int(e);  
 
  return 0;
}
