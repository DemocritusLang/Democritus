function foo() int {}

function bar() int {}

function baz() int {}

function bar() void {} /* Error: duplicate function bar */

function main() int
{
  return 0;
}
