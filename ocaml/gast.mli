type 'a option = None | Some of 'a

type htype = Get | Crud | ObjHType

type var_type = String | Bool | Integer | Float | Custom of string | ListType of var_type

type bop =
    Add | Sub | Mult | Div | Mod
  | DotAdd | DotSub | DotMult | DotDiv
  | And | Or | Xor | Leq | Neq | Geq | Ee | Lt | Gt
  | Scont | Scat
  | Access | Range | Lcat

type uop = Neg | Not | Sizeof | Cap | Low

type expr =
    Strlit of string
  | Boollit of bool
  | Intlit of int
  | Floatlit of float
  | Listlit of expr list
  | Objlit of string * expr list
  | Variable of string
  | Funcall of string * expr list
  | Binop of expr * bop * expr
  | Unop of uop * expr
  | Noexpr

type var_decl = {
    g_vtype : var_type;
    g_id : string;
    g_expr : expr;
}

type arg = {
    g_argtype : var_type;
    g_argid : string;
}

type mdef = {
    mdef_vtype : var_type;
    mdef_id : string
}

type go_struct = {
    sname : string;
    mdefs : mdef list;
    shtypes : htype;
}

type go_handledef = {
    path : string;
    hname : string;
    htypess : htype;
    hdargs : arg list;
    db : string;
    hname_plain : string;
}

type go_structwrapper = {
    wname : string;
    returntype : string;
    wargs : arg list;
    members : var_decl list;
    wrap_htypes : htype;
}

type go_handlefunction = {
    hfname : string;
    structwrappername : string;
    htypes : htype;
    fname_plain : string;
    hfargs : arg list;
    fname_struct : string;
    fname_wrapper : string;
    func_mdefs : mdef list;
}

type stmt =
    Block of stmt list
  | Vardecl of var_decl
  | Assign of string * expr
  | If of expr * stmt * stmt
  | While of expr * stmt
  | Return of expr

type go_func = {
    go_fname : string;
    go_ftype : var_type;
    go_args : arg list;
    go_body : stmt list;
}

type go_program = string list * var_decl list * go_struct list * go_handledef list * go_func list * go_structwrapper list * go_handlefunction list
