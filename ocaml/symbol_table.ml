open Sast
open Sast_printer

exception DuplicateObjFuncError of string
exception DuplicateVariableError of string
exception ObjectNotDefinedError of string
exception VariableNotDefinedError of string
exception FunctionNotDefinedError of string
exception NoEndpointError of string
exception UnusedVariableError of string

let raise_duplicate_func_error name =
	raise (DuplicateObjFuncError(Format.sprintf "YOU CANNOT DECLARE TWO OBJECTS, ENDPOINTS, OR FUNCS IN THE SAME PROGRAM WITH THE SAME NAME: %s" name ))

let raise_duplicate_obj_error name =
	raise (DuplicateObjFuncError(Format.sprintf "YOU CANNOT DECLARE TWO OBJECTS, ENDPOINTS, OR FUNCS IN THE SAME PROGRAM WITH THE SAME NAME: %s" name ))

let raise_duplicate_variable_error vname =
	raise (DuplicateVariableError(Format.sprintf "YOU CANNOT DECLARE TWO VARIABLES IN THE SAME SCOPE WITH THE SAME NAME: %s" vname))

let raise_object_not_defined_error obj_name =
	raise (ObjectNotDefinedError(Format.sprintf "THE OBJECT (OR ENDPOINT) %s WAS NEVER DEFINED." obj_name))

let raise_variable_not_defined_error var_name =
	raise (VariableNotDefinedError(Format.sprintf "THE VARIABLE %s WAS NEVER DEFINED" var_name))

let raise_function_not_defined_error func_name =
	raise (FunctionNotDefinedError(Format.sprintf "THE FUNCTION %s WAS NEVER DEFINED" func_name))

let raise_NoEndpointError obj_name =
	raise (NoEndpointError(Format.sprintf "YOU NEED TO DECLARE AT LEAST ONE %s" obj_name))

let raise_unused_variable_error var_name =
	raise (UnusedVariableError(Format.sprintf "THE VARIABLE %s WAS NEVER USED" var_name))

let symbol_table = ref []

let rec mark_specific_arg_used_helper arg variables =
	match variables with
	| [] -> []
	| h::t when h.st_argid = arg.st_argid -> {st_argtype = h.st_argtype; st_argid = h.st_argid; st_used = true}::t
	| h::t -> h::(mark_specific_arg_used_helper arg t)

let rec mark_st_arg_used_helper searched_scopes unsearched_scopes arg =
	let scopes = (searched_scopes, unsearched_scopes) in
		match scopes with
  	  | (_,[])     -> ()
	  | (s,[hu])   -> (try let _ = List.find (fun v -> v.st_argid = arg.st_argid) hu.variables in
  						ignore (symbol_table := s @ [{scope_name = hu.scope_name; variables = mark_specific_arg_used_helper arg hu.variables; objects = hu.objects;funcs = hu.funcs}])
				  	  with Not_found -> mark_st_arg_used_helper (s @ [hu]) [] arg)
	  | (s,hu::tu) -> (try let _ = List.find (fun v -> v.st_argid = arg.st_argid) hu.variables in
						ignore (symbol_table := s @ [{scope_name = hu.scope_name; variables = mark_specific_arg_used_helper arg hu.variables; objects = hu.objects;funcs = hu.funcs}] @ tu)
					  with Not_found -> mark_st_arg_used_helper (s @ [hu]) tu arg)

let mark_st_arg_used arg = mark_st_arg_used_helper [] !symbol_table arg

let rec find_variable_helper st name =
	match st with
		[]   -> raise Not_found
	  | [h]  -> let var = List.find (fun v ->
				v.st_argid = name) h.variables in let _ = mark_st_arg_used var in var
	  | h::t -> try
	  				let var = List.find (fun v ->
	  				v.st_argid = name) h.variables in let _ = mark_st_arg_used var in var
	  				with Not_found -> find_variable_helper t name

let find_variable name =
	let st = !symbol_table in
		find_variable_helper st name

let rec find_object_helper st name =
	match st with
		[]   -> raise Not_found
	  | [h]  -> List.find (fun obj -> obj.sast_oname = name) h.objects (* raises Not_found if no object in global sym_tab*)
	  | h::t -> try List.find (fun obj -> obj.sast_oname = name) h.objects with Not_found -> find_object_helper t name

let find_object name =
	let st = !symbol_table in
		find_object_helper st name

let rec find_endpoint_st_helper st name =
	match st with
		[]   -> raise Not_found
	  | [h]  -> List.find (fun obj -> obj.otype = name ) h.objects
	  | h::t -> try List.find (fun obj -> obj.otype =  name) h.objects
				with Not_found -> find_endpoint_st_helper t name

let find_endpoint_st name =
	let st = !symbol_table in
		find_endpoint_st_helper st name

let check_endpoint name = try
	let endpoint = find_endpoint_st name in
		endpoint.otype with Not_found -> raise_NoEndpointError "ENDPOINT"

let rec find_func_helper st name =
	match st with
		[]   -> raise Not_found
	  | [h]  -> List.find (fun func -> func.sast_fname = name) h.funcs (* raises Not_found if no funcs in global sym_tab*)
	  | h::t -> try List.find (fun func -> func.sast_fname = name) h.funcs with Not_found -> find_func_helper t name

let find_func name =
	let st = !symbol_table in
		find_func_helper st name

let add_object_to_symbol_table obj_decl =
	ignore (
		try ignore (let obj = find_object obj_decl.sast_oname in raise_duplicate_obj_error obj.sast_oname)
			with Not_found ->
				match !symbol_table with
					[]   -> ()
				  | [h]  -> ignore (symbol_table := [{scope_name = h.scope_name; variables = h.variables; objects = List.append h.objects [obj_decl]; funcs = h.funcs}])
				  | h::t -> ignore (symbol_table := [{scope_name = h.scope_name; variables = h.variables; objects = List.append h.objects [obj_decl]; funcs = h.funcs}] @ t))

let add_func_to_symbol_table func_decl =
	ignore (
		try ignore (let func = find_func func_decl.sast_fname in raise_duplicate_func_error func.sast_fname)
			with Not_found ->
				match !symbol_table with
					[]   -> ()
				  | [h]  -> ignore (symbol_table := [{scope_name = h.scope_name; variables = h.variables; objects = h.objects; funcs = List.append h.funcs [func_decl]}])
				  | h::t -> ignore (symbol_table := [{scope_name = h.scope_name; variables = h.variables; objects = h.objects; funcs = List.append h.funcs [func_decl]}] @ t))

(* convert var_decl to st_arg *)
let v_to_a v = {st_argtype = v.s_vtype; st_argid = v.s_id; st_used = false}

let add_variable_to_symbol_table v =
	ignore (try ignore (let var = find_variable v.s_id in raise_duplicate_variable_error var.st_argid)
		with Not_found ->
			match !symbol_table with
				[]   -> ()
			  | [h]  -> ignore (symbol_table := [{scope_name = h.scope_name; variables = h.variables @ [v_to_a v];objects = h.objects; funcs = h.funcs}])
			  | h::t -> ignore (symbol_table := [{scope_name = h.scope_name; variables = h.variables @ [v_to_a v]; objects = h.objects;funcs = h.funcs}] @ t))

let find_type_of_variable name = try
	let var = find_variable name in
		var.st_argtype with Not_found -> raise_variable_not_defined_error name

let find_type_of_function name = try
	let func = find_func name in
		func.ftype with Not_found -> raise_function_not_defined_error name

let is_current_scope_type name =
	match !symbol_table with
		[] -> false
	  | [h] -> h.scope_name = name
  	  | h::t -> h.scope_name = name

let push_scope_to_symbol_table (scope : s_table) =
	ignore (symbol_table := [scope] @ !symbol_table)

let check_unused_variable_in_scope st_arg_list =
	try
		let found = List.find (fun v -> v.st_used = false) st_arg_list
	in
	raise_unused_variable_error found.st_argid with Not_found -> ()

let pop_scope_from_symbol_table () =
	match !symbol_table with
		[] -> ()
	  | h::t -> ignore(let _ = check_unused_variable_in_scope h.variables in symbol_table := t)
