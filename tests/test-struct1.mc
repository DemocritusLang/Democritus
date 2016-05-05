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
  let number int;
}

function main() int
{
  
  let a int;
  let b int;
  let circle struct Circle;
  let test_struct struct Test_Struct;
  
  test_struct.number = 100;
  
  circle.radius = 666;
  circle.extra_struct = test_struct; 
  circle.extra_struct.number = 42;

  a = test_struct.number;
  b = circle.radius;

  print_int(a);
  
  return 0;
}
