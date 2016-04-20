function foo(a int, b bool, c int) int { }

function bar(a int, b bool, a int) void {} /* Error: duplicate formal a in bar */

function main() int
{
  return 0;
}
