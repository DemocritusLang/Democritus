(* MicroC by Stephen Edwards Columbia University *)
(* Abstract Syntax Tree and functions for printing it *)

type op = Add | Sub | Mult | Div | Equal | Neq | Less | Leq | Greater | Geq |
          And | Or | Mod | LShift | RShift

type uop = Neg | Not | Deref | Ref

type pretyp_modifier = Atomic
type posttyp_modifier = Pointer
type primitive_typ = Null | Int | Float | Char | Boolean | Void | StructType

type typ = 
    PrePostModType of pretyp_modifier * primitive_typ * posttyp_modifier
  | PostModType of primitive_typ * posttyp_modifier
  | PreModType of pretyp_modifier * primitive_typ
  | PrimitiveType of primitive_typ

type bind = typ * string

type expr =
    IntLiteral of int
  | FloatLiteral of float
  | BoolLit of bool
  | Id of string
  | Binop of expr * op * expr
  | Unop of uop * expr
  | Assign of string * expr
  | Call of string * expr list
  | Noexpr

type stmt =
    Block of stmt list
  | Expr of expr
  | Return of expr
  | If of expr * stmt * stmt
  | For of expr * expr * expr * stmt
  | While of expr * stmt

type func_decl = {
    typ : typ;
    fname : string;
    formals : bind list;
    locals : bind list;
    body : stmt list;
  }

type struct_decl = {
    sname : string;
    formals: bind list;
}

type program = bind list * func_decl list * struct_decl list

(* Pretty-printing functions *)

let string_of_op = function
    Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | Equal -> "=="
  | Neq -> "!="
  | Less -> "<"
  | Leq -> "<="
  | Greater -> ">"
  | Geq -> ">="
  | And -> "&&"
  | Or -> "||"
  | Mod -> "%"
  | RShift -> ">>"
  | LShift -> "<<"

let string_of_uop = function
    Neg -> "-"
  | Not -> "!"
  | Deref -> "*"
  | Ref -> "&"

let rec string_of_expr = function
    IntLiteral(l) -> string_of_int l
  | FloatLiteral(l) -> string_of_float l
  | BoolLit(true) -> "true"
  | BoolLit(false) -> "false"
  | Id(s) -> s
  | Binop(e1, o, e2) ->
      string_of_expr e1 ^ " " ^ string_of_op o ^ " " ^ string_of_expr e2
  | Unop(o, e) -> string_of_uop o ^ string_of_expr e
  | Assign(v, e) -> v ^ " = " ^ string_of_expr e
  | Call(f, el) ->
      f ^ "(" ^ String.concat ", " (List.map string_of_expr el) ^ ")"
  | Noexpr -> ""

let rec string_of_stmt = function
    Block(stmts) ->
      "{\n" ^ String.concat "" (List.map string_of_stmt stmts) ^ "}\n"
  | Expr(expr) -> string_of_expr expr ^ ";\n";
  | Return(expr) -> "return " ^ string_of_expr expr ^ ";\n";
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s
  | If(e, s1, s2) ->  "if (" ^ string_of_expr e ^ ")\n" ^
      string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | For(e1, e2, e3, s) ->
      "for (" ^ string_of_expr e1  ^ " ; " ^ string_of_expr e2 ^ " ; " ^
      string_of_expr e3  ^ ") " ^ string_of_stmt s
  | While(e, s) -> "while (" ^ string_of_expr e ^ ") " ^ string_of_stmt s

let string_of_premodifier = function
    Atomic -> "atomic"

let string_of_postmodifier = function
    Pointer -> "*"

let string_of_primitivetyp = function
    Int -> "int"
  | Float -> "float"
  | Char -> "char"
  | Boolean -> "boolean"
  | Void -> "void"
  | Null -> "null"
  | StructType -> "struct"

let string_of_typ = function
  | PrePostModType (m1, t, m2) -> string_of_premodifier m1 ^ " " ^ 
    string_of_primitivetyp t ^ " " ^ string_of_postmodifier m2
  | PostModType(t, m) -> string_of_primitivetyp t ^ " " ^ string_of_postmodifier m
  | PreModType(m, t) -> string_of_premodifier m ^ " " ^ string_of_primitivetyp t
  | PrimitiveType(s) -> string_of_primitivetyp s

let string_of_vdecl (t, id) = string_of_typ t ^ " " ^ id ^ ";\n"

let string_of_fdecl fdecl =
  string_of_typ fdecl.typ ^ " " ^
  fdecl.fname ^ "(" ^ String.concat ", " (List.map snd fdecl.formals) ^
  ")\n{\n" ^
  String.concat "" (List.map string_of_vdecl fdecl.locals) ^
  String.concat "" (List.map string_of_stmt fdecl.body) ^
  "}\n"

let string_of_program (vars, funcs) =
  String.concat "" (List.map string_of_vdecl vars) ^ "\n" ^
  String.concat "\n" (List.map string_of_fdecl funcs)
