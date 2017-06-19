open Ast
open Sast

exception EmptyListLitError of string
exception FunctionArgTypeMismatchError of string
exception ObjectArgTypeMismatchError of string

let raise_function_arg_type_mismatch_error func_name =
	raise (FunctionArgTypeMismatchError(Format.sprintf "ARG TYPE MISMATCH ERROR ON FUNCTION CALL TO FUNCTION %s" func_name))

let raise_obj_arg_type_mismatch_error obj_name =
  raise (ObjectArgTypeMismatchError(Format.sprintf "ARG TYPE MISMATCH ERROR ON OBJECT LITERAL TO OBJECT %s" obj_name))

let rec astvtype_to_sastvtype = function
	Ast.String      -> Sast.String
  | Ast.Bool        -> Sast.Bool
  | Ast.Integer     -> Sast.Integer
  | Ast.Float       -> Sast.Float
  | Ast.Custom(s)   -> Sast.Custom(s)
  | Ast.ListType(i) -> Sast.ListType(astvtype_to_sastvtype i)

let rec astlit_to_sastvtype = function
    Ast.Strlit(s)    -> Sast.String
  | Ast.Boollit(s)   -> Sast.Bool
  | Ast.Intlit(s)    -> Sast.Integer
  | Ast.Floatlit(s)  -> Sast.Float
  | Ast.Objlit(i, a) -> Sast.Custom(i)
  | _                -> print_string "one"; raise Not_found (* dumb, temporary error for non-literals *)

let asthtype_to_sasthtype = function
	Ast.Get      -> Sast.Get
  | Ast.Crud     -> Sast.Crud
  | Ast.ObjHType -> Sast.ObjHType

let astbop_to_sastbop = function
	Ast.Add     -> Sast.Add
  | Ast.Sub     -> Sast.Sub
  | Ast.Mult    -> Sast.Mult
  | Ast.Div     -> Sast.Div
  | Ast.DotAdd  -> Sast.DotAdd
  | Ast.DotSub  -> Sast.DotSub
  | Ast.DotMult -> Sast.DotMult
  | Ast.DotDiv  -> Sast.DotDiv
  | Ast.And     -> Sast.And
  | Ast.Or      -> Sast.Or
  | Ast.Xor     -> Sast.Xor
  | Ast.Mod     -> Sast.Mod
  | Ast.Lt      -> Sast.Lt
  | Ast.Gt      -> Sast.Gt
  | Ast.Ee      -> Sast.Ee
  | Ast.Neq     -> Sast.Neq
  | Ast.Geq     -> Sast.Geq
  | Ast.Leq     -> Sast.Leq
  | Ast.Scont   -> Sast.Scont
  | Ast.Scat    -> Sast.Scat
  | Ast.Access  -> Sast.Access
  | Ast.Range   -> Sast.Range
  | Ast.Lcat    -> Sast.Lcat

let astuop_to_sastuop = function
	Ast.Neg     -> Sast.Neg
  | Ast.Not     -> Sast.Not
  | Ast.Sizeof  -> Sast.Sizeof
  | Ast.Cap     -> Sast.Cap
  | Ast.Low     -> Sast.Low

let astobjtype_to_sastobjtype = function
    Ast.Endpoint  -> Sast.Endpoint
  | Ast.Object    -> Sast.Object

let rec match_pwfa_helper f_name = function
	([],[])               -> ()
  | ([(_,ph)],[ah])       -> if	ph = ah.s_argtype then () else raise_function_arg_type_mismatch_error f_name
  | ((_,ph)::pt),(ah::at) -> if	ph = ah.s_argtype then () else raise_function_arg_type_mismatch_error f_name;
							 match_pwfa_helper f_name (pt,at)
  | _                     -> raise_function_arg_type_mismatch_error f_name

let match_params_with_func_args params f =
	let p_and_args = (params, f.args) in
		match_pwfa_helper f.sast_fname p_and_args

let rec match_pwov_helper o_name = function
  ([],[])               -> ()
  | ([(_,ph)],[ah])       -> if ph = ah.s_vtype then () else raise_obj_arg_type_mismatch_error o_name
  | ((_,ph)::pt),(ah::at) -> if ph = ah.s_vtype then () else raise_obj_arg_type_mismatch_error o_name;
               match_pwov_helper o_name (pt,at)
  | _                     -> raise_obj_arg_type_mismatch_error o_name

let match_params_with_obj_vdecls params o =
	let p_and_vdecls = (params, o.vdecls) in
		match_pwov_helper o.sast_oname p_and_vdecls

let rec match_pwoa_helper o_name = function
	([],[])               -> ()
  | ([(_,ph)],[ah])       -> if ph = ah.s_argtype then () else raise_obj_arg_type_mismatch_error o_name
  | ((_,ph)::pt),(ah::at) -> if ph = ah.s_argtype then () else raise_obj_arg_type_mismatch_error o_name;
               match_pwoa_helper o_name (pt,at)
  | _                     -> raise_obj_arg_type_mismatch_error o_name

let match_params_with_obj_args params o =
	let p_and_args = (params, o.sast_args) in
    	match_pwoa_helper o.sast_oname p_and_args

let rec
ast_expr_list_to_sast_expr_list = function
    [] -> []
    | [h] -> [astexpr_to_sastexpr h]
    | h::t -> astexpr_to_sastexpr h :: ast_expr_list_to_sast_expr_list t
and
astvdecl_to_sastvdecl v =
  let vtype = astvtype_to_sastvtype v.vtype in
  let expr = astexpr_to_sastexpr v.expr in
    ignore(Type_checking.validate_vdecl_types vtype expr);
    let sast_vdecl = {s_vtype = vtype; s_id = v.id; s_expr = expr} in
  ignore (
    if Symbol_table.is_current_scope_type "crud" || Symbol_table.is_current_scope_type "get" ||
    Symbol_table.is_current_scope_type "object"
    then ()
    else ignore(Symbol_table.add_variable_to_symbol_table sast_vdecl)); sast_vdecl
and
astexpr_to_sastexpr = function
	Ast.Strlit(lit)       -> (Sast.Strlit(lit), Sast.String)
  | Ast.Boollit(lit)      -> (Sast.Boollit(lit), Sast.Bool)
  | Ast.Intlit(lit)       -> (Sast.Intlit(lit), Sast.Integer)
  | Ast.Floatlit(lit)     -> (Sast.Floatlit(lit), Sast.Float)
  | Ast.Objlit(i, l)      -> let obj_params = ast_expr_list_to_sast_expr_list l in
                             let obj = try Symbol_table.find_object i
							 				with Not_found -> Symbol_table.raise_object_not_defined_error i in
                             	ignore(if obj.otype = Object
							 		then (match_params_with_obj_vdecls obj_params obj)
							 		else (match_params_with_obj_args obj_params obj));
							 (Sast.Objlit(i, obj_params), Sast.Custom(i))
  | Ast.Listlit(lit)      -> let arg1 = List.map astexpr_to_sastexpr lit in
							 let arg2 = astlit_to_sastvtype (List.hd lit) in
							 let _ = Type_checking.check_list_literal_consistency arg2 arg1 in
							 (Sast.Listlit(arg1) , Sast.ListType(arg2))
  | Ast.Variable(i)       -> (Sast.Variable(i), Symbol_table.find_type_of_variable i)
  | Ast.Funcall(i, l)     -> let call_params = ast_expr_list_to_sast_expr_list l in
							 let func = try Symbol_table.find_func i
							 				with Not_found -> Symbol_table.raise_function_not_defined_error i in
							 ignore(match_params_with_func_args call_params func);
							 (Sast.Funcall(i, call_params), Symbol_table.find_type_of_function i)
  | Ast.Binop(e1,op,e2)   -> let e1 = astexpr_to_sastexpr e1 in
                             let e2 = astexpr_to_sastexpr e2 in
                             let op = astbop_to_sastbop op in
                             let typ = Type_checking.validate_binop_types (e1, op, e2) in
                             let exp = Sast.Binop(e1, op, e2) in
                             (exp, typ)
  | Ast.Unop(o, e)        -> let o = astuop_to_sastuop o in
					    	 let e = astexpr_to_sastexpr e in
					         let typ = Type_checking.validate_unop_types (o, e) in
					         let exp = Sast.Unop(o, e) in
					         (exp, typ)
  | Ast.Noexpr            -> (Sast.Noexpr, Sast.Custom(""))

let rec astvdecls_to_sastvdecls = function
  	[] -> []
  | [h] -> [astvdecl_to_sastvdecl h]
  | h::t -> astvdecl_to_sastvdecl h :: astvdecls_to_sastvdecls t

let astvdecl_to_sastvdecl_ignore_exp v =
	let vtype = astvtype_to_sastvtype v.vtype in
	let expr = (Noexpr, Custom("notype")) in
	let sast_vdecl = {s_vtype = vtype; s_id = v.id; s_expr = expr} in
	sast_vdecl

let rec astvdecls_to_sastvdecls_ignore_exp = function
	[] -> []
  | [h] -> [astvdecl_to_sastvdecl_ignore_exp h]
  | h::t -> astvdecl_to_sastvdecl_ignore_exp h :: astvdecls_to_sastvdecls_ignore_exp t

let astarg_to_sastarg a = {s_argtype = astvtype_to_sastvtype a.argtype; s_argid = a.argid}

let rec astarglist_to_sastarglist = function
	[] -> []
  | [h] -> [astarg_to_sastarg h]
  | h::t -> astarg_to_sastarg h :: astarglist_to_sastarglist t

let sastarg_to_sast_st_arg a = {st_argtype = a.s_argtype; st_argid = a.s_argid; st_used = false}

let rec sastarglist_to_sast_st_arglist = function
  [] -> []
  | [h] -> [sastarg_to_sast_st_arg h]
  | h::t -> sastarg_to_sast_st_arg h :: sastarglist_to_sast_st_arglist t

let translate_obj_decl obj_decl =
	let name = obj_decl.oname in
	let typ = astobjtype_to_sastobjtype obj_decl.otype in
	let ht = asthtype_to_sasthtype obj_decl.htypes in
	let ar = astarglist_to_sastarglist obj_decl.args in
	let objtype = if obj_decl.otype = Object then "object" else (if obj_decl.htypes = Crud then "crud" else "get") in
	ignore (Symbol_table.push_scope_to_symbol_table {scope_name = objtype; variables = sastarglist_to_sast_st_arglist ar; objects = []; funcs = []});
	let vd = astvdecls_to_sastvdecls (List.rev obj_decl.vdecls) in
	let sast_obj_decl = {sast_oname = name; otype = typ; htypes = ht; sast_args = ar; vdecls = vd;} in
    let _ =  Type_checking.check_obj_vd_count vd name in
	ignore (Symbol_table.pop_scope_from_symbol_table ());
	sast_obj_decl

let rec translate_obj_decls = function
	[]   -> []
  | [h]  -> [translate_obj_decl h]
  | h::t -> translate_obj_decl h :: translate_obj_decls t

let rec
aststmt_to_saststmt = function
	Ast.Block(s)                -> 	let _ = Symbol_table.push_scope_to_symbol_table {scope_name = "block"; variables = []; objects = []; funcs = [];} in
									let blockStatements = aststmts_to_saststmts (List.rev s) in
									let _ = Symbol_table.pop_scope_from_symbol_table () in
									Sast.Block(List.rev blockStatements)
  | Ast.Vardecl(v)              -> Sast.Vardecl(astvdecl_to_sastvdecl v)
  | Ast.Assign(s, e)            -> Sast.Assign(s, astexpr_to_sastexpr e)
  | Ast.If(eif, s1, s2)         -> Sast.If(astexpr_to_sastexpr eif, aststmt_to_saststmt s1, aststmt_to_saststmt s2)
  | Ast.While(e, s)				-> Sast.While(astexpr_to_sastexpr e, aststmt_to_saststmt s)
  | Ast.Return(expr)            -> Sast.Return(astexpr_to_sastexpr expr)
and
aststmts_to_saststmts = function
  	[] -> []
  | [h] -> [aststmt_to_saststmt h]
  | h::t -> aststmt_to_saststmt h :: aststmts_to_saststmts t

let translate_func_decl func_decl =
	let fn = func_decl.fname in
	let ft = astvtype_to_sastvtype func_decl.ftype in
	let fa = astarglist_to_sastarglist func_decl.args in
	ignore (Symbol_table.push_scope_to_symbol_table {scope_name = "func"; variables = sastarglist_to_sast_st_arglist fa; objects = []; funcs = [];});
	let fb = aststmts_to_saststmts (List.rev func_decl.body) in
	let _ =  Type_checking.check_for_return fn ft fb in (* checking return at the last line *)
	let sast_func_decl = {sast_fname = fn; ftype = ft; args = fa; body = fb} in
	ignore (Symbol_table.pop_scope_from_symbol_table ());
	sast_func_decl

let rec translate_func_decls = function
	[]   -> []
  | [h]  -> [translate_func_decl h]
  | h::t -> translate_func_decl h :: translate_func_decls t

let translate_gvar_decl gvar_decl =
	let sast_gvar_decl = astvdecl_to_sastvdecl gvar_decl in sast_gvar_decl

let rec translate_gvar_decls = function
	[]   -> []
  | [h]  -> [translate_gvar_decl h]
  | h::t -> translate_gvar_decl h :: translate_gvar_decls t

let add_obj_to_symbol_table obj_decl =
	let name = obj_decl.oname in
	let typ = astobjtype_to_sastobjtype obj_decl.otype in
	let ht = asthtype_to_sasthtype obj_decl.htypes in
	let ar = astarglist_to_sastarglist obj_decl.args in
	let objtype = if obj_decl.otype = Object then "object" else (if obj_decl.htypes = Crud then "crud" else "get") in
	ignore (Symbol_table.push_scope_to_symbol_table {scope_name = objtype; variables = []; objects = []; funcs = []});
	let vd = astvdecls_to_sastvdecls_ignore_exp (List.rev obj_decl.vdecls) in
	ignore (Symbol_table.pop_scope_from_symbol_table ());
	let sast_obj_decl = {sast_oname = name; otype = typ; htypes = ht; sast_args = ar; vdecls = vd;} in
	Symbol_table.add_object_to_symbol_table sast_obj_decl

let rec add_objs_to_symbol_table = function
	[]   -> []
  | [h]  -> [add_obj_to_symbol_table h]
  | h::t -> add_obj_to_symbol_table h :: add_objs_to_symbol_table t

let add_func_to_symbol_table func_decl =
	let fn = func_decl.fname in
	let ft = astvtype_to_sastvtype func_decl.ftype in
	let fa = astarglist_to_sastarglist func_decl.args in
	let sast_func_decl = {sast_fname = fn; ftype = ft; args = fa; body = []} in
	Symbol_table.add_func_to_symbol_table sast_func_decl

let rec add_funcs_to_symbol_table = function
  	[]   -> []
  | [h]  -> [add_func_to_symbol_table h]
  | h::t -> add_func_to_symbol_table h :: add_funcs_to_symbol_table t

let generate_sast gvar_decls obj_decls func_decls =
	let sast_gvar_decls = translate_gvar_decls gvar_decls in
	(* first pass to add objects and funcs to global symbol table, ignore all errors *)
	let _ = add_objs_to_symbol_table obj_decls in
	let _ = add_funcs_to_symbol_table func_decls in
	(* second pass does semantic checking, but doesn't add the objects to a symbol table *)
	let sast_func_decls = translate_func_decls func_decls in
	let sast_obj_decls = translate_obj_decls obj_decls in
	ignore(Symbol_table.check_endpoint Endpoint);
    ignore (Symbol_table.pop_scope_from_symbol_table ());
    (sast_gvar_decls, sast_obj_decls, sast_func_decls)

let sast_from_ast ast =
	let (gvar_decls, obj_decls, func_decls) = ast in
	ignore (Symbol_table.push_scope_to_symbol_table {scope_name = "global"; variables = []; objects = []; funcs = []});
	generate_sast gvar_decls obj_decls func_decls
