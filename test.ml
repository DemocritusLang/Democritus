open Ast

let rec eval = function
_ -> "yay"

let _ =
let lexbuf = Lexing.from_channel stdin in
let output = Parser.program Scanner.token lexbuf in
let result = eval output in
print_endline (result)