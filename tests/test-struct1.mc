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
 
  let circle struct Circle;
  let test struct Test_Struct;
  let test_color struct Color;
 
  a = 10;

/*  test_color.red = 69; */
 
/*  test.number = 10000000;
  test.color = test_color; 
*/
  circle.extra_struct = test;
  circle.extra_struct.number = 42;

    a = circle.extra_struct.color.red;
    b = circle.extra_struct.number;
    c = test.number;

  print_int(a);  
  print_int(b);
  print_int(c);
   
  return 0;
}
