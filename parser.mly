/* Democritus, adapted from MicroC by Stephen Edwards Columbia University */
/* Ocamlyacc parser */

%{
open Ast;;

let first (a,_,_) = a;;
let second (_,b,_) = b;;
let third (_,_,c) = c;;
%}

%token COLON SEMI LPAREN RPAREN LBRACE RBRACE COMMA
%token PLUS MINUS STAR DIVIDE MOD ASSIGN NOT DOT DEREF REF
%token EQ NEQ LT LEQ GT GEQ TRUE FALSE AND OR
%token LET RETURN IF ELSE FOR INT FLOAT BOOL VOID STRTYPE FUNCTION STRUCT VOIDSTAR CAST TO SET
%token <string> STRING
%token <float> FLOATLITERAL
%token <int> LITERAL
%token <string> ID
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%nonassoc POINTER
%right ASSIGN
%left OR
%left AND
%left EQ NEQ
%left LT GT LEQ GEQ
%left PLUS MINUS 
%left STAR DIVIDE MOD
%right NOT NEG DEREF REF
%left DOT

%start program
%type <Ast.program> program

%%

program:
  decls EOF { $1 }

decls:
   /* nothing */ { [], [], [] }
 | decls vdecl { ($2 :: first $1), second $1, third $1 }
 | decls fdecl { first $1, ($2 :: second $1), third $1 }
 | decls sdecl { first $1, second $1, ($2 :: third $1) }

fdecl:
   FUNCTION ID LPAREN formals_opt RPAREN typ LBRACE vdecl_list stmt_list RBRACE
     { { typ = $6;
	 fname = $2;
	 formals = $4;
	 locals = List.rev $8;
	 body = List.rev $9 } }

formals_opt:
    /* nothing */ { [] }
  | formal_list   { List.rev $1 }

formal_list:
    ID typ                   { [($2,$1)] }
  | formal_list COMMA ID typ { ($4,$3) :: $1 }

typ:
    INT { Int }
  | FLOAT { Float }
  | BOOL { Bool }
  | VOID { Void }
  | STRTYPE { MyString }
  | STRUCT ID { StructType ($2) }
  | VOIDSTAR { Voidstar }
  | STAR %prec POINTER typ { PointerType ($2) }

vdecl_list:
    /* nothing */    { [] }
  | vdecl_list vdecl { $2 :: $1 }

vdecl:
   LET ID typ SEMI { ($3, $2) }

sdecl:
    STRUCT ID LBRACE vdecl_list RBRACE
      { { sname = $2;
      sformals = $4;
      } }

stmt_list:
    /* nothing */  { [] }
  | stmt_list stmt { $2 :: $1 }

stmt:
    expr SEMI { Expr $1 }
  | RETURN SEMI { Return Noexpr }
  | RETURN expr SEMI { Return $2 }
  | LBRACE stmt_list RBRACE { Block(List.rev $2) }
  | IF LPAREN expr RPAREN stmt %prec NOELSE { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    { If($3, $5, $7) }
  | FOR LPAREN expr_opt SEMI expr SEMI expr_opt RPAREN stmt
     { For($3, $5, $7, $9) }
  | FOR LPAREN expr RPAREN stmt { While($3, $5) }

expr_opt:
    /* nothing */ { Noexpr }
  | expr          { $1 }

expr:
    LITERAL          { Literal($1) }
  | FLOATLITERAL     { FloatLiteral($1) }
  | TRUE             { BoolLit(true) }
  | FALSE            { BoolLit(false) }
  | ID               { Id($1) }
  |STRING	     { MyStringLit($1) } 
  | expr PLUS   expr { Binop($1, Add,   $3) }
  | expr MINUS  expr { Binop($1, Sub,   $3) }
  | expr STAR  expr { Binop($1, Mult,  $3) }
  | expr DIVIDE expr { Binop($1, Div,   $3) }
  | expr MOD expr { Binop($1, Mod,   $3) }
  | expr EQ     expr { Binop($1, Equal, $3) }
  | expr NEQ    expr { Binop($1, Neq,   $3) }
  | expr LT     expr { Binop($1, Less,  $3) }
  | expr LEQ    expr { Binop($1, Leq,   $3) }
  | expr GT     expr { Binop($1, Greater, $3) }
  | expr GEQ    expr { Binop($1, Geq,   $3) }
  | expr AND    expr { Binop($1, And,   $3) }
  | expr OR     expr { Binop($1, Or,    $3) }
  | expr DOT    ID   { Dotop($1, $3) }
/*  | expr DOT    ID ASSIGN expr { SAssign($1, $3, $5) } */
  | CAST expr TO typ { Castop($4, $2) }
  | MINUS expr %prec NEG { Unop(Neg, $2) }
  | STAR expr %prec DEREF { Unop(Deref, $2) }
  | REF expr { Unop(Ref, $2) }
  | NOT expr         { Unop(Not, $2) }
  | expr ASSIGN expr   { Assign($1, $3) }
  | ID LPAREN actuals_opt RPAREN { Call($1, $3) }
  | LPAREN expr RPAREN { $2 }

actuals_opt:
    /* nothing */ { [] }
  | actuals_list  { List.rev $1 }

actuals_list:
    expr                    { [$1] }
  | actuals_list COMMA expr { $3 :: $1 }
