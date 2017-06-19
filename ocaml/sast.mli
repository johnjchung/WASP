type 'a option = None | Some of 'a

type htype = Get | Crud | ObjHType

type objtype = Object | Endpoint

type var_type = String | Bool | Integer | Float | Custom of string | ListType of var_type | RangeType

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
  | Listlit of typed_expr list
  | Objlit of string * typed_expr list
  | Variable of string
  | Funcall of string * typed_expr list
  | Binop of typed_expr * bop * typed_expr
  | Unop  of uop * typed_expr
  | Noexpr
and
typed_expr = expr * var_type

type var_decl = {
    s_vtype : var_type;
    s_id : string;
    s_expr : typed_expr;
}

type arg = {
    s_argtype : var_type;
    s_argid : string;
}

type st_arg = {
    st_argtype : var_type;
    st_argid : string;
    st_used : bool;
}

type obj_decl = {
    sast_oname : string;
    otype : objtype;
    htypes : htype;
    sast_args : arg list;
    vdecls : var_decl list;
  }

type stmt =
    Block of stmt list
  | Vardecl of var_decl
  | Assign of string * typed_expr
  | If of typed_expr * stmt * stmt
  | While of typed_expr * stmt
  | Return of typed_expr
  (* TODO: add If, While, Funccall *)

type func_decl = {
    sast_fname : string;
    ftype : var_type;
    args : arg list;
    body : stmt list;
}

type program = var_decl list * obj_decl list * func_decl list

(* Symbol Table Type - not part of SAST, used for semantic checking *)
type s_table = {
	scope_name : string;
	variables : st_arg list;
	objects : obj_decl list;
  funcs : func_decl list;
}
