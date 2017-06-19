open Sast
open Sast_printer

exception BinopTypeError of string
exception UnopTypeError  of string
exception VariableDeclarationTypeError of string
exception NoReturnErr of string
exception ReturnTypeMismatchErr of string
exception MissingObjectVariableDeclarationErr of string
exception ListLitTypeError of string

let raise_binop_type_error  = function
  | (lhs, o, rhs) -> raise(BinopTypeError(Format.sprintf "THE BINARY OPERATION OF TYPES IS NOT ALLOWED: %s %s %s"
      (Sast_printer.string_of_vartype lhs)
      (Sast_printer.string_bin_op o)
      (Sast_printer.string_of_vartype rhs)))

let raise_unop_type_error = function
	| (o, rhs) -> raise(UnopTypeError(Format.sprintf "THE UNARY OPERATION OF TYPE IS NOT ALLOWED: %s %s"
	  (Sast_printer.string_of_unop o)
	  (Sast_printer.string_of_vartype rhs)))

let raise_list_type_inconsistency_error typ1 typ2 =
    raise(ListLitTypeError(Format.sprintf "A LIST LITERAL CANNOT BE DECLARED WITH EXPRESSIONS OF MIXED TYPES: %s AND %s"
        (Sast_printer.string_of_vartype typ1)
        (Sast_printer.string_of_vartype typ2)))

(*Regular Binop*)
let validate_add_binop = function
    (Integer, _, Integer) -> Integer
  | (Integer, _, Float)   -> Integer
  | (Float, _, Float)     -> Integer
  | (Float, _, Integer)   -> Integer
  | (String, _, String)   -> String
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_sub_binop = function
    (Integer, _, Integer) -> Integer
  | (Integer, _, Float)   -> Integer
  | (Float, _, Float)     -> Integer
  | (Float, _, Integer)   -> Integer
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_mult_binop = function
    (Integer, _, Integer) -> Integer
  | (Integer, _, Float)   -> Integer
  | (Float, _, Float)     -> Integer
  | (Float, _, Integer)   -> Integer
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_div_binop = function
    (Integer, _, Integer) -> Integer
  | (Integer, _, Float)   -> Integer
  | (Float, _, Float)     -> Integer
  | (Float, _, Integer)   -> Integer
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

(*Dot Binop*)
let validate_dotadd_binop = function
    (Integer, _, Integer) -> Float
  | (Integer, _,  Float)   -> Float
  | (Float, _, Float)     -> Float
  | (Float, _, Integer)   -> Float
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_dotsub_binop = function
    (Integer, _, Integer) -> Float
  | (Integer, _, Float)   -> Float
  | (Float, _, Float)     -> Float
  | (Float, _, Integer)   -> Float
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_dotmult_binop = function
    (Integer, _, Integer) -> Float
  | (Integer, _, Float)   -> Float
  | (Float, _, Float)     -> Float
  | (Float, _, Integer)   -> Float
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_dotdiv_binop = function
    (Integer, _, Integer) -> Float
  | (Integer, _, Float)   -> Float
  | (Float, _, Float)     -> Float
  | (Float, _, Integer)   -> Float
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_bool_binops = function
	(Bool, _, Bool) -> Bool
  | (lhs, o, rhs) -> raise_binop_type_error (lhs, o, rhs)

let validate_not_unop = function
	  (_, Bool) -> Bool
	| (o, rhs) -> raise_unop_type_error (o, rhs)

let validate_neg_unop = function
	  (_, Float)   -> Float
	| (_, Integer) -> Integer
    | (o, rhs)     -> raise_unop_type_error (o, rhs)

let validate_sizeof_unop = function
	(_, ListType(_)) -> Integer
  | (_, String)      -> Integer
  | (o, rhs)         -> raise_unop_type_error (o, rhs)

let validate_cap_unop = function
  	(_, String) -> String
  | (o, rhs)         -> raise_unop_type_error (o, rhs)

 let validate_low_unop = function
	(_, String) -> String
  | (o, rhs)         -> raise_unop_type_error (o, rhs)

let validate_mod_binop = function
	  (Integer, _, Integer) -> Integer
	| (lhs, o, rhs) -> raise_binop_type_error(lhs, o, rhs)

let validate_comparison_binop = function
	  (Integer, _, Integer) -> Bool
    | (Float, _, Integer)   -> Bool
    | (Integer, _, Float)   -> Bool
    | (Float, _, Float)     -> Bool
	| (lhs, o, rhs)         -> raise_binop_type_error(lhs, o, rhs)

let validate_equals_binop = function
	  (Integer, _, Integer) -> Bool
    | (Float, _, Integer)   -> Bool
    | (Integer, _, Float)   -> Bool
    | (Float, _, Float)     -> Bool
    | (lhs, o, rhs)         -> raise_binop_type_error(lhs, o, rhs)

let validate_scont_binop = function
	  (String, _, String)   -> Bool
	| (lhs, o, rhs)         -> raise_binop_type_error(lhs, o, rhs)

let validate_access_binop = function
	(ListType(t), _, Integer)   -> t
  | (ListType(t), _, RangeType) -> ListType(t)
  | (String, _, RangeType)      -> String
  | (lhs, o, rhs)               -> raise_binop_type_error(lhs, o, rhs)

let validate_range_binop = function
    (Integer, _, Integer)   -> RangeType
  | (lhs, o, rhs)           -> raise_binop_type_error(lhs, o, rhs)

let validate_lcat_binop = function
    (ListType(a), o, ListType(b)) -> if a = b then ListType(a)
                                     else (raise_binop_type_error (ListType(a), o, ListType(b)))
  | (lhs, o, rhs)                 -> raise_binop_type_error(lhs, o, rhs)

let validate_binop_types binop =
    let ((_, lhs_typ), o, (_, rhs_typ)) = binop in
    match o with
    | Add     -> validate_add_binop (lhs_typ, o, rhs_typ)
    | Sub     -> validate_sub_binop (lhs_typ, o, rhs_typ)
    | Mult    -> validate_mult_binop (lhs_typ, o, rhs_typ)
    | Div     -> validate_div_binop (lhs_typ, o, rhs_typ)
    | DotAdd  -> validate_dotadd_binop (lhs_typ, o, rhs_typ)
    | DotSub  -> validate_dotsub_binop (lhs_typ, o, rhs_typ)
    | DotMult -> validate_dotmult_binop (lhs_typ, o, rhs_typ)
    | DotDiv  -> validate_dotdiv_binop (lhs_typ, o, rhs_typ)
	| And     -> validate_bool_binops(lhs_typ, o, rhs_typ)
    | Or      -> validate_bool_binops(lhs_typ, o, rhs_typ)
    | Xor     -> validate_bool_binops(lhs_typ, o, rhs_typ)
    | Mod     -> validate_mod_binop(lhs_typ, o, rhs_typ)
    | Leq     -> validate_comparison_binop(lhs_typ, o, rhs_typ)
    | Geq     -> validate_comparison_binop(lhs_typ, o, rhs_typ)
    | Ee      -> validate_equals_binop(lhs_typ, o, rhs_typ)
	| Neq     -> validate_equals_binop(lhs_typ, o, rhs_typ)
    | Lt      -> validate_comparison_binop(lhs_typ, o, rhs_typ)
    | Gt      -> validate_comparison_binop(lhs_typ, o, rhs_typ)
    | Scont   -> validate_scont_binop(lhs_typ, o, rhs_typ)
	| Scat    -> validate_add_binop(lhs_typ, o, rhs_typ)
    | Access  -> validate_access_binop(lhs_typ, o, rhs_typ)
    | Range   -> validate_range_binop(lhs_typ, o, rhs_typ)
    | Lcat    -> validate_lcat_binop(lhs_typ, o, rhs_typ)

let validate_unop_types unop =
	let (o, (_, rhs_typ)) = unop in
	match o with
	| Not    -> validate_not_unop (o, rhs_typ)
	| Neg    -> validate_neg_unop (o, rhs_typ)
    | Sizeof -> validate_sizeof_unop (o, rhs_typ)
    | Cap    -> validate_cap_unop (o, rhs_typ)
    | Low    -> validate_low_unop (o, rhs_typ)

(* Takes a type and a typed sexpr and confirms it is the proper type *)
let validate_vdecl_types vtype exp =
    let (expr, expr_type) = exp in
    if Symbol_table.is_current_scope_type "object"
        then (if expr != Noexpr
                  then raise(VariableDeclarationTypeError(Format.sprintf "Variables defined in Objects should not be assigned expressions."))
              else ())
    else (if Symbol_table.is_current_scope_type "crud"
              then (if expr != Noexpr
                        then raise(VariableDeclarationTypeError(Format.sprintf "Variables defined in CRUD Endpoints should not be assigned expressions.")))
    else (if Symbol_table.is_current_scope_type "get" && expr == Noexpr
              then raise(VariableDeclarationTypeError(Format.sprintf "Variables defined in GET Endpoints must be assigned expressions."))
    else (if vtype = expr_type
              then ()
          else raise(VariableDeclarationTypeError(Format.sprintf "Expected %s expression, found %s"(Sast_printer.string_of_vartype vtype)
              (Sast_printer.string_of_vartype expr_type))))))

let check_for_return func_name func_type func_body =
    let last_stmt = List.hd func_body in
    match last_stmt with
        | Return(typed_e) -> let (_, r_type) = typed_e in
          if r_type = func_type
            then func_body
            else raise(ReturnTypeMismatchErr(Format.sprintf "Expected %s return type, found %s"(Sast_printer.string_of_vartype func_type)(Sast_printer.string_of_vartype r_type)))
        | _ -> raise (NoReturnErr(Format.sprintf "No return statement found for function %s()" (func_name)))

let check_obj_vd_count vd_list name =
    let cnt = List.length vd_list in
        if cnt = 0
            then raise(MissingObjectVariableDeclarationErr(Format.sprintf "OBJECT (OR ENDPOINT) DECLARATION REQUIRES AT LEAST ONE VARIABLE DECLARATION FOR: %s" name))

let rec check_list_literal_consistency list_type = function
    []       -> []
  | [(_,h)]  -> if h = list_type then [] else raise_list_type_inconsistency_error h list_type
  | (_,h)::t -> if h = list_type then (check_list_literal_consistency list_type t) else raise_list_type_inconsistency_error h list_type
