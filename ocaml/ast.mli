type 'a option = None | Some of 'a

type htype = Get | Crud | ObjHType

type objtype = Object | Endpoint

type var_type = String | Bool | Integer | Float | Custom of string | ListType of var_type

type bop =
    Add | Sub | Mult | Div | Mod
  | DotAdd | DotSub | DotMult | DotDiv
  | And | Or | Xor | Leq | Geq | Neq | Ee | Lt | Gt
  | Scont | Scat
  | Access | Range | Lcat

type uop = Not | Neg | Sizeof | Cap | Low

type expr =
    Strlit of string
  | Boollit of bool
  | Intlit of int
  | Floatlit of float
  | Listlit of expr list
  | Variable of string
  | Objlit of string * expr list
  | Funcall of string * expr list
  | Binop of expr * bop * expr
  | Unop of uop * expr
  | Noexpr

type var_decl = {
    vtype : var_type;
    id : string;
    expr : expr;
}

type arg = {
    argtype : var_type;
    argid : string;
}

type obj_decl = {
    oname : string;
    otype : objtype;
    htypes : htype;
    args : arg list;
    vdecls : var_decl list;
}

type stmt =
    Block of stmt list
  | Vardecl of var_decl
  | Assign of string * expr
  | If of expr * stmt * stmt
  | While of expr * stmt
  | Return of expr

type func_decl = {
    fname : string;
    ftype : var_type;
    args : arg list;
    body : stmt list;
}

type program = var_decl list * obj_decl list * func_decl list
