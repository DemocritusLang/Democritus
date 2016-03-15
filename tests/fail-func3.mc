function foo(a int, b bool, c int) int { }

function bar(a int, b void, c int) void {} /* Error: illegal formal void b */

function main() int
{
  return 0;
}
