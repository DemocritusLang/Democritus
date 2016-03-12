(* MicroC by Stephen Edwards Columbia University *)
(* Ocamllex scanner for MicroC *)

{ open Parser }

let Exp = ('e'|'E') ('+'|'-')? ['0'-'9']+
let Digit = ['0'-'9']
rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "//"          { comment lexbuf }               (* Comments *)
| "/*"          { multicomment lexbuf }           (* Multi-line comments *)
| '('           { LPAREN }
| ')'           { RPAREN }
| '{'           { LBRACE }
| '}'           { RBRACE }
| '['           { LBRACKET }
| ']'           { RBRACKET }
| ';'           { SEMI }
| ','           { COMMA }
| '+'           { PLUS }
| '-'           { MINUS }
| '*'           { STAR }
| '/'           { DIVIDE }
| '%'           { MODULO }
| ">>"          { RSHIFT }
| "<<"          { LSHIFT }
| '&'           { AMPERSAND }
| '='           { ASSIGN }
| "=="          { EQ }
| "!="          { NEQ }
| '<'           { LT }
| "<="          { LEQ }
| ">"           { GT }
| ">="          { GEQ }
| "&&"          { AND }
| "||"          { OR }
| "!"           { NOT }
| "if"          { IF }
| "else"        { ELSE }
| "elif"        { ELIF }
| "for"         { FOR }
| "while"       { WHILE } 
| "break"       { BREAK }
| "continue"    { CONTINUE }
| "return"      { RETURN }
| "atomic"      { ATOMIC }
| "function"    { FUNCTION }
| "int"         { INT }
| "float"       { FLOAT }
| "char"        { CHAR }
| "boolean"     { BOOLEAN }
| "null"        { NULL }
| "void"        { VOID }
| "true"        { TRUE }
| "false"       { FALSE }
| "string"      { STRING }
| "struct"      { STRUCT }
| Digit+ as lxm { INTLITERAL(int_of_string lxm) }
| ('.' Digit+ Exp? | Digit+ ('.' Digit* Exp? | Exp)) as lxm { FLOATLITERAL(float_of_string lxm)}
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "\n" { token lexbuf }
| _    { comment lexbuf }

and multicomment = parse
  "*/" { token lexbuf }
| _    { multicomment lexbuf }
