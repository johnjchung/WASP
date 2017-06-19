open Ast

let sprintf = Format.sprintf

let string_of_htype = function
	Get -> "GET"
  | Crud -> "CRUD"
  | ObjHType -> ""

let rec string_of_vartype = function
    String  	-> "string"
  | Bool    	-> "bool"
  | Integer 	-> "int"
  | Float   	-> "float"
  | Custom(s)   -> s
  | ListType(t) -> "list<" ^ string_of_vartype t ^ ">"

let string_of_binop = function
	Add -> "+"
  | Sub -> "-"
  | Mult -> "*"
  | Div -> "/"
  | DotAdd -> ".+"
  | DotSub -> ".-"
  | DotMult -> ".*"
  | DotDiv -> "./"
  | And -> "and"
  | Or  -> "or"
  | Xor -> "xor"
  | Gt  -> ">"
  | Lt  -> "<"
  | Ee  -> "=="
  | Neq -> "!="
  | Geq -> ">="
  | Leq -> "<="
  | Mod -> "mod"
  | Scont -> "~="
  | Scat -> "^"
  | Access -> "@"
  | Range -> "->"
  | Lcat -> "++"

let string_of_unop = function
	Not    -> "not"
  | Neg    -> "-"
  | Sizeof -> "sizeof"
  | Cap    -> "cap"
  | Low    -> "low"

let string_of_arg arg = arg.argid ^ " " ^ string_of_vartype arg.argtype

let rec string_of_args = function
	[]   -> ""
  | [h]  -> string_of_arg h
  | h::t -> string_of_arg h ^ ", " ^ string_of_args t

let rec string_of_expr_list = function
		[] -> ""
	  | [h] -> string_of_expr h
	  | h::t -> string_of_expr h ^ ", " ^ string_of_expr_list t
and
	string_of_expr = function
		Strlit(s)         -> "\"" ^ s ^ "\""
	  | Boollit(s)        -> string_of_bool s
	  | Intlit(s)         -> string_of_int s
	  | Floatlit(s)	      -> string_of_float s
	  | Listlit(s)        -> "[" ^ string_of_listlit s ^ "]"
	  | Variable(s)       -> s
	  | Objlit(i, l)     -> i ^ "{" ^ string_of_expr_list l ^ "}"
	  | Funcall(i, l)    -> i ^ "(" ^ string_of_expr_list l ^ "}"
	  | Binop(e1, o, e2)  -> sprintf "(Binop (%s) %s (%s))"
							(string_of_expr e1) (string_of_binop o) (string_of_expr e2)
	  | Unop(o, e)        -> sprintf "(Unop %s (%s))" (string_of_unop o) (string_of_expr e)
	  | Noexpr            -> ""
and
	string_of_listlit = function
        [] -> ""
      | [h] -> string_of_expr h
      | h::t -> string_of_expr h ^ ", " ^ string_of_listlit t

let string_of_vdecl v =
	match v.expr with
		Noexpr -> string_of_vartype v.vtype ^ " " ^ v.id ^ ";"
	  | _      -> string_of_vartype v.vtype ^ " " ^ v.id ^ " = " ^ string_of_expr v.expr ^ ";"

let rec string_of_vdecls = function
	[] -> ""
  | [h] -> string_of_vdecl h
  | h::t -> string_of_vdecl h ^ ", " ^ string_of_vdecls t

let rec
string_of_stmt = function
	Block(s)            -> "{" ^ string_of_stmt_list s ^ "}\n"
  | Vardecl(v)          -> "\t" ^ string_of_vdecl v ^ "\n"
  | Assign(s, e)        -> "\t" ^ s ^ " = " ^ string_of_expr e ^ ";\n"
  | If(e, s, Block([])) -> "if (" ^ string_of_expr e ^ ")\n" ^ string_of_stmt s ^ "\n"
  | While(e, s)         -> "while (" ^ string_of_expr e ^ ") {\n" ^ string_of_stmt s ^ "\n}\n"
  | If(e, s1, s2)       -> "if (" ^ string_of_expr e ^ ")\n" ^
  						   string_of_stmt s1 ^ "else\n" ^ string_of_stmt s2
  | Return(expr)        -> "\treturn " ^ string_of_expr expr ^ ";\n"
and
string_of_stmt_list = function
	[] -> ""
  | [h] -> string_of_stmt h
  | h::t -> string_of_stmt h ^ string_of_stmt_list t

let string_of_obj_decl obj_decl =
	match obj_decl.otype with
		Endpoint -> "Endpoint " ^ obj_decl.oname ^ "( " ^ string_of_htype obj_decl.htypes ^ ":" ^ string_of_args obj_decl.args ^ ") {" ^ string_of_vdecls obj_decl.vdecls ^ "}"
	  | Object   -> "Object " ^ obj_decl.oname ^ " {" ^ string_of_vdecls obj_decl.vdecls ^ "}"

let string_of_func_decl func_decl =
	"Func " ^ string_of_vartype func_decl.ftype ^ " " ^ func_decl.fname ^ "(" ^ string_of_args func_decl.args ^ ") {\n" ^ string_of_stmt_list func_decl.body ^ "}\n"

let string_of_program ast =
	let (gvars, objects, funcs) = ast in
		String.concat "" (List.map string_of_vdecl (List.rev gvars)) ^
		String.concat "" (List.map string_of_obj_decl objects) ^
		String.concat "" (List.map string_of_func_decl funcs) ^ "\n"
