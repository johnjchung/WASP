open Ast
open Gast

let go_imports = ref []

let add_to_go_imports import = ignore (if List.mem import !go_imports then () else go_imports := List.append [import] !go_imports)

let rec astvtype_to_gastvtype = function
	Ast.String      -> Gast.String
  | Ast.Bool        -> Gast.Bool
  | Ast.Integer     -> Gast.Integer
  | Ast.Float       -> Gast.Float
  | Ast.Custom(s)   -> Gast.Custom(s)
  | Ast.ListType(v) -> Gast.ListType(astvtype_to_gastvtype v)

let rec astbop_to_gastbop = function
	Ast.Add     -> add_to_go_imports "math"; Gast.Add
  | Ast.Sub     -> add_to_go_imports "math"; Gast.Sub
  | Ast.Mult    -> add_to_go_imports "math"; Gast.Mult
  | Ast.Div     -> add_to_go_imports "math"; Gast.Div
  | Ast.DotAdd  -> Gast.DotAdd
  | Ast.DotSub  -> Gast.DotSub
  | Ast.DotMult -> Gast.DotMult
  | Ast.DotDiv  -> Gast.DotDiv
  | Ast.And     -> Gast.And
  | Ast.Or      -> Gast.Or
  | Ast.Xor     -> Gast.Xor
  | Ast.Mod     -> Gast.Mod
  | Ast.Lt      -> Gast.Lt
  | Ast.Gt      -> Gast.Gt
  | Ast.Ee      -> Gast.Ee
  | Ast.Neq     -> Gast.Neq
  | Ast.Geq     -> Gast.Geq
  | Ast.Leq		-> Gast.Leq
  | Ast.Scont   -> add_to_go_imports "strings"; Gast.Scont
  | Ast.Scat    -> Gast.Scat
  | Ast.Access  -> Gast.Access
  | Ast.Range   -> Gast.Range
  | Ast.Lcat    -> Gast.Lcat

let rec astuop_to_gastuop = function
	Ast.Neg    -> Gast.Neg
  | Ast.Not    -> Gast.Not
  | Ast.Sizeof -> Gast.Sizeof
  | Ast.Cap    -> add_to_go_imports "strings"; Gast.Cap
  | Ast.Low    -> add_to_go_imports "strings"; Gast.Low

let vdecl_to_mdef v = {mdef_vtype = astvtype_to_gastvtype v.vtype; mdef_id = String.capitalize v.id}

let rec vdecls_to_mdefs = function
	[]   -> []
  | [h]  -> [vdecl_to_mdef h]
  | h::t -> vdecl_to_mdef h :: vdecls_to_mdefs t

let arg_to_garg arg = {g_argtype = astvtype_to_gastvtype arg.argtype; g_argid = String.capitalize arg.argid}

let rec args_to_gargs = function
	[]   -> []
  | [h]  -> [arg_to_garg h]
  | h::t -> arg_to_garg h :: args_to_gargs t

let asthtype_to_gasthtype = function
	Ast.Get -> Gast.Get
  | Ast.Crud -> add_to_go_imports "database/sql"; add_to_go_imports "gopkg.in/gorp.v1";
    add_to_go_imports "github.com/go-sql-driver/mysql"; add_to_go_imports "log";
    add_to_go_imports "strconv"; Gast.Crud
  | Ast.ObjHType -> Gast.ObjHType

let rec
ast_expr_list_to_gast_expr_list = function
	[] -> []
  | [h] -> [astexpr_to_gastexpr h]
  | h::t -> astexpr_to_gastexpr h :: ast_expr_list_to_gast_expr_list t
and
astexpr_to_gastexpr = function
	Ast.Strlit(lit)       -> Gast.Strlit(lit)
  | Ast.Boollit(lit)      -> Gast.Boollit(lit)
  | Ast.Intlit(lit)       -> Gast.Intlit(lit)
  | Ast.Floatlit(lit)     -> Gast.Floatlit(lit)
  | Ast.Listlit(lit)      -> let arg1 = List.map astexpr_to_gastexpr lit in Gast.Listlit(List.rev arg1)
  | Ast.Variable(i)       -> Gast.Variable(i)
  | Ast.Objlit(i, l)      -> Gast.Objlit(i, ast_expr_list_to_gast_expr_list (List.rev l))
  | Ast.Funcall(i, l)     -> Gast.Funcall(i, ast_expr_list_to_gast_expr_list (List.rev l))
  | Ast.Binop(e1,op,e2)   -> Gast.Binop(astexpr_to_gastexpr e1, astbop_to_gastbop op, astexpr_to_gastexpr e2)
  | Ast.Unop(o, e)        -> Gast.Unop(astuop_to_gastuop o, astexpr_to_gastexpr e)
  | Ast.Noexpr            -> Gast.Noexpr

let astvdecl_to_gastvdecl v = {g_vtype = astvtype_to_gastvtype v.vtype; g_id = String.capitalize v.id; g_expr = astexpr_to_gastexpr v.expr}

let rec astvdecls_to_gastvdecls = function
  	[] -> []
  | [h] -> [astvdecl_to_gastvdecl h]
  | h::t -> astvdecl_to_gastvdecl h :: astvdecls_to_gastvdecls t

let rec
aststmt_to_gaststmt = function
	Ast.Block(s)                -> Gast.Block(aststmts_to_gaststmts s)
  | Ast.Vardecl(v)              -> Gast.Vardecl(astvdecl_to_gastvdecl v)
  | Ast.Assign(s, expr)         -> Gast.Assign(s, astexpr_to_gastexpr expr)
  | Ast.If(eif, s1, s2)         -> Gast.If(astexpr_to_gastexpr eif, aststmt_to_gaststmt s1, aststmt_to_gaststmt s2)
  | Ast.While(e, s)				-> Gast.While(astexpr_to_gastexpr e, aststmt_to_gaststmt s)
  | Ast.Return(expr)            -> Gast.Return(astexpr_to_gastexpr expr)
and
aststmts_to_gaststmts = function
    [] -> []
  | [h] -> [aststmt_to_gaststmt h]
  | h::t -> aststmt_to_gaststmt h :: aststmts_to_gaststmts t

let object_to_struct obj =
	{sname = obj.oname ^ "_struct"; mdefs = vdecls_to_mdefs obj.vdecls; shtypes = asthtype_to_gasthtype obj.htypes}

let object_to_handledef obj =
	{hname_plain = obj.oname; path = "/" ^ obj.oname; hname = obj.oname ^ "_handler"; htypess = asthtype_to_gasthtype obj.htypes; hdargs = args_to_gargs obj.args; db = obj.oname ^ "_struct"}

let object_to_structwrapper obj =
	{wname = obj.oname ^ "_struct_wrapper"; returntype = obj.oname ^ "_struct"; wargs = args_to_gargs obj.args;
	members = astvdecls_to_gastvdecls obj.vdecls; wrap_htypes = asthtype_to_gasthtype obj.htypes}

let rec check_args_for_non_string_type = function
	[]   -> ()
  | [h]  -> if h.g_argtype != String then ignore(add_to_go_imports "strconv") else ()
  | h::t -> if h.g_argtype != String then ignore(add_to_go_imports "strconv") else check_args_for_non_string_type t

let object_to_handlefunction (obj : obj_decl) =
	let args = args_to_gargs obj.args in
	check_args_for_non_string_type args;
	{ hfname = obj.oname ^ "_handler"; structwrappername = obj.oname ^ "_struct_wrapper"; htypes = asthtype_to_gasthtype obj.htypes; fname_wrapper = obj.oname ^ "_struct_wrapper"; hfargs = args; fname_struct = obj.oname ^ "_struct"; fname_plain = obj.oname; func_mdefs = vdecls_to_mdefs obj.vdecls}

let func_to_go_func func =
  {go_ftype = astvtype_to_gastvtype func.ftype; go_fname = func.fname; go_args = args_to_gargs func.args; go_body = aststmts_to_gaststmts func.body;}

let rec translate_gvars = function
	[] -> []
  | [h] -> [astvdecl_to_gastvdecl h]
  | h::t -> astvdecl_to_gastvdecl h :: translate_gvars t

let rec translate_structs = function
	[] -> []
  | [h] -> [object_to_struct h]
  | h::t -> object_to_struct h :: translate_structs t

let rec translate_handledefs = function
	[] -> []
  | [h] when h.otype = Object    -> []
  | [h]							 -> [object_to_handledef h]
  | h::t when h.otype = Object   -> translate_handledefs t
  | h::t						 -> object_to_handledef h :: translate_handledefs t

let rec translate_funcs = function
  [] -> []
  | [h] -> [func_to_go_func h]
  | h::t -> func_to_go_func h :: translate_funcs t

let rec translate_structwrappers = function
	[]   -> []
  | [h]  -> [object_to_structwrapper h]
  | h::t -> object_to_structwrapper h :: translate_structwrappers t

let rec translate_handlefunctions = function
	[] -> []
  | [h] when h.otype = Object    -> []
  | [h]							 -> [object_to_handlefunction h]
  | h::t when h.otype = Object   -> translate_handlefunctions t
  | h::t						 -> object_to_handlefunction h :: translate_handlefunctions t

let generate_gast gvars objects funcs =
	let _ = ignore (List.iter add_to_go_imports ["github.com/gin-gonic/gin"; "os"; "math"]) in
	let go_gvars = List.rev (translate_gvars gvars) in
    let go_structs = List.rev (translate_structs objects) in
    let go_handledefs = List.rev (translate_handledefs objects) in
    let go_funcs = List.rev (translate_funcs funcs) in
	let go_structwrappers = List.rev (translate_structwrappers objects) in
    let go_handlefunctions = List.rev (translate_handlefunctions objects) in
    (List.sort compare !go_imports, go_gvars, go_structs, go_handledefs, go_funcs, go_structwrappers, go_handlefunctions)

let gast_from_ast ast =
	let (gvars, objects, funcs) = ast in
	generate_gast gvars objects funcs
