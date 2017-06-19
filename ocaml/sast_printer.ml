open Sast

let sprintf = Format.sprintf

let string_of_htype = function
	Get -> "GET"
  | Crud -> "CRUD"
  | ObjHType -> ""

let rec string_of_vartype = function
    String    -> "string"
  | Bool      -> "bool"
  | Integer   -> "int"
  | Float     -> "float"
  | Custom(i) -> i
  | ListType(t) -> "list<" ^ string_of_vartype t ^ ">"
  | RangeType -> "range"

let string_bin_op = function
	Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | DotAdd -> ".+"
  | DotSub -> ".-"
  | DotMult -> ".*"
  | DotDiv -> "./"
  | And    -> "and"
  | Xor    -> "xor"
  | Or     -> "or"
  | Gt  -> ">"
  | Lt  -> "<"
  | Ee  -> "=="
  | Neq -> "!="
  | Geq -> ">="
  | Leq -> "<="
  | Mod -> "mod"
  | Scont -> "~="
  | Scat  -> "^"
  | Access -> "@"
  | Range -> "->"
  | Lcat -> "++"

let string_of_unop = function
	Not    -> "not"
  | Neg    -> "-"
  | Sizeof -> "sizeof"
  | Cap    -> "cap"
  | Low    -> "low"

let string_of_arg arg = arg.s_argid ^ " " ^ string_of_vartype arg.s_argtype

let rec string_of_args = function
	[]   -> ""
  | [h]  -> string_of_arg h
  | h::t -> string_of_arg h ^ string_of_args t

let rec
	string_of_typed_expr_list = function
		[] -> ""
	  | [h] -> string_of_typed_expr h
	  | h::t -> string_of_typed_expr h ^ ", " ^ string_of_typed_expr_list t
and
string_of_typed_expr typ_exp =
	let (exp, typ) = typ_exp in
	"[" ^ string_of_vartype typ ^ "] " ^ string_of_expr exp
and
string_of_expr = function
	Strlit(s)         -> "\"" ^ s ^ "\""
  | Boollit(s)        -> string_of_bool s
  | Intlit(s)         -> string_of_int s
  | Floatlit(s)       -> string_of_float s
  | Variable(s)       -> s
  | Listlit(s)        -> "[" ^ string_of_listlit s ^ "]"
  | Objlit(i, l)      -> i ^ "{" ^ string_of_typed_expr_list l ^ "}"
  | Funcall(i, l)     -> i ^ "(" ^ string_of_typed_expr_list l ^ ")"
  | Binop(e1, o, e2)  -> sprintf "(Binop (%s) %s (%s))"
						 (string_of_typed_expr e1) (string_bin_op o) (string_of_typed_expr e2)
  | Unop(o, e)        -> sprintf "(Unop %s (%s))" (string_of_unop o) (string_of_typed_expr e)
  | Noexpr            -> ""
and
string_of_listlit = function
    [] -> ""
    | [h] -> string_of_typed_expr h
    | h::t -> string_of_typed_expr h ^ ", " ^ string_of_listlit t

let string_of_vdecl v =
	let (e, t) = v.s_expr in
		match e with
			Noexpr -> string_of_vartype v.s_vtype ^ " " ^ v.s_id ^ ";"
		  | _      -> string_of_vartype v.s_vtype ^ " " ^ v.s_id ^ " = " ^ string_of_typed_expr v.s_expr ^ ";"

let rec string_of_vdecls = function
	[] -> ""
  | [h] -> string_of_vdecl h
  | h::t -> string_of_vdecl h ^ ", " ^ string_of_vdecls t

let rec
string_of_stmt = function
	Block(s)            -> " {" ^ string_of_stmt_list s ^ "}\n"
  | Vardecl(v)          -> "\t" ^ string_of_vdecl v ^ "\n"
  | Assign(s, e)        ->  "\t" ^ s ^ " = " ^ string_of_typed_expr e ^ ";\n"
  | If(e, s, Block([])) -> "if (" ^ string_of_typed_expr e ^ ")\n" ^ string_of_stmt s ^ "\n"
  | If(e, s1, s2)       -> "if (" ^ string_of_typed_expr e ^ ")\n" ^ string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | While(e, s)         -> "while (" ^ string_of_typed_expr e ^ ") {\n" ^ string_of_stmt s ^ "\n}\n"
  | Return(e)           ->  "\tReturn " ^ string_of_typed_expr e ^ ";\n"
and
string_of_stmt_list = function
	[] -> ""
  | [h] -> string_of_stmt h
  | h::t -> string_of_stmt h ^ string_of_stmt_list t

let rec string_of_htype_list = function
	[] -> ""
  | [h] -> string_of_htype h
  | h::t -> string_of_htype h ^ ", " ^ string_of_htype_list t

let string_of_obj_decl obj_decl =
	match obj_decl.otype with
		Endpoint -> "Endpoint " ^ obj_decl.sast_oname ^ "( " ^ string_of_htype obj_decl.htypes ^ ":) {" ^ (string_of_vdecls (List.rev obj_decl.vdecls)) ^ "}"
	  | Object   -> "Object " ^ obj_decl.sast_oname ^ " {" ^ (string_of_vdecls (List.rev obj_decl.vdecls)) ^ "}"

let string_of_func_decl func_decl =
		"Func " ^ string_of_vartype func_decl.ftype ^ " " ^ func_decl.sast_fname ^ "( " ^ string_of_args func_decl.args ^ ") {\n" ^ (string_of_stmt_list (List.rev func_decl.body)) ^ "\n}"

let string_of_program sast =
	let (gvars, objects, funcs) = sast in
		String.concat "" (List.map string_of_vdecl (List.rev gvars)) ^
		String.concat "" (List.map string_of_obj_decl objects) ^
		String.concat "" (List.map string_of_func_decl funcs) ^ "\n"
