open Gast

let sprintf = Format.sprintf

let rec string_expr_to_gotype = function
	  | Strlit(s)		  -> "string"
	  | Boollit(s) 		  -> "bool"
	  | Intlit(s)		  -> "int"
	  | Floatlit(s) 	  -> "float64"
	  | Listlit(s)		  -> "list_junk"
	  | Objlit(i, l)      -> "obj_junk"
	  | Funcall(i, l)     -> "func_junk"
	  | Binop(e1, op, e2) -> "binop_junk"
	  | Unop(op, e)       -> "unop_junk"
	  | Variable(s)       -> "var_junk"
	  | Noexpr            -> "noexpr_junk"

let rec
string_of_expr_list = function
		[] -> ""
	  | [h] -> string_of_expr h
	  | h::t -> string_of_expr h ^ ", " ^ string_of_expr_list t
and
	string_of_expr ex =
		match ex with
		Strlit(s)         -> "\"" ^ s ^ "\""
	  | Boollit(s)        -> string_of_bool s
	  | Intlit(s)         -> string_of_int s
	  | Floatlit(s)       -> string_of_float s
	  | Listlit(s)        -> "[]" ^ string_expr_to_gotype (List.hd s) ^ " {" ^ string_of_listlit s ^ "}"
	  | Variable(i)       -> i
	  | Objlit(i, l)      -> i ^ "_struct_wrapper(" ^ string_of_expr_list l ^ ")"
	  | Funcall(i, l)     -> i ^ "(" ^ string_of_expr_list l ^ ")"
	  | Binop(e1, op, e2) -> string_of_binop e1 e2 op
	  | Unop(op, e)       -> string_of_unop op e
	  | Noexpr            -> ""
and
	string_of_binop e1 e2 = function
		Add     -> "int_conv(" ^ (string_of_expr e1) ^ ") + int_conv(" ^ (string_of_expr e2) ^ ")"
	  | Sub     -> "int_conv(" ^ (string_of_expr e1) ^ ") - int_conv(" ^ (string_of_expr e2) ^ ")"
	  | Mult    -> "int_conv(" ^ (string_of_expr e1) ^ ") * int_conv(" ^ (string_of_expr e2) ^ ")"
	  | Div     -> "int_conv(" ^ (string_of_expr e1) ^ ") / int_conv(" ^ (string_of_expr e2) ^ ")"
	  | DotAdd  -> "float_conv(" ^ (string_of_expr e1) ^ ") + float_conv(" ^ (string_of_expr e2) ^ ")"
	  | DotSub  -> "float_conv(" ^ (string_of_expr e1) ^ ") - float_conv(" ^ (string_of_expr e2) ^ ")"
	  | DotMult -> "float_conv(" ^ (string_of_expr e1) ^ ") * float_conv(" ^ (string_of_expr e2) ^ ")"
	  | DotDiv  -> "float_conv(" ^ (string_of_expr e1) ^ ") / float_conv(" ^ (string_of_expr e2) ^ ")"
	  | And     -> "bool(" ^ (string_of_expr e1) ^ ") && bool(" ^ (string_of_expr e2) ^ ")"
	  | Or      -> "bool(" ^ (string_of_expr e1) ^ ") || bool(" ^ (string_of_expr e2) ^ ")"
	  | Xor	    -> "bool(" ^ (string_of_expr e1) ^ ") != bool(" ^ (string_of_expr e2) ^ ")"
  	  | Gt      -> "bool(" ^ (string_of_expr e1) ^ " > " ^ (string_of_expr e2) ^ ")"
	  | Lt  	-> (string_of_expr e1) ^ " < " ^ (string_of_expr e2)
  	  | Ee  	-> (string_of_expr e1) ^ " == " ^ (string_of_expr e2)
	  | Neq		-> (string_of_expr e1) ^ " != " ^ (string_of_expr e2)
  	  | Geq 	-> (string_of_expr e1) ^ " >= " ^ (string_of_expr e2)
  	  | Leq 	-> (string_of_expr e1) ^ " <= " ^ (string_of_expr e2)
  	  | Mod 	-> (string_of_expr e1) ^ " % " ^ (string_of_expr e2)
	  | Scont 	-> "strings.Contains(" ^ (string_of_expr e1) ^ ", " ^ (string_of_expr e2) ^ ")"
	  | Scat    -> "(" ^ (string_of_expr e1) ^ " + " ^ (string_of_expr e2) ^ ")"
	  | Access  -> string_of_expr e1 ^ "[" ^ (string_of_expr e2) ^ "]"
	  | Range   -> string_of_expr e1 ^ ":" ^ string_of_expr e2
	  | Lcat    -> "append(" ^ string_of_expr e1 ^ ", " ^ string_of_expr e2 ^ "...)"

and
	string_of_unop op e =
		match op with
			Not    -> "bool(!" ^ (string_of_expr e) ^ ")"
		  | Neg    -> "(-" ^ (string_of_expr e) ^ ")"
		  | Sizeof -> "len(" ^ string_of_expr e ^ ")"
		  | Cap    -> "strings.ToUpper(" ^ string_of_expr e ^ ")"
		  | Low    -> "strings.ToLower(" ^ string_of_expr e ^ ")"
and
    string_of_listlit = function
      [] -> ""
      | [h] -> string_of_expr h
      | h::t -> string_of_expr h ^ ", " ^ string_of_listlit t

let string_of_vdecl v = v.g_id ^ ": " ^ string_of_expr v.g_expr

let rec string_of_vdecls = function
	[]   -> ""
  | [h]  -> string_of_vdecl h
  | h::t -> string_of_vdecl h ^ ", " ^ string_of_vdecls t

let rec string_of_memdefs_post stru = function
	[]   -> ""
  | [h]  -> stru.fname_plain ^ "_post." ^ h.mdef_id ^ " != \"\" {"
  | h::t -> stru.fname_plain ^ "_post." ^ h.mdef_id ^ " != \"\" && "
     ^ string_of_memdefs_post stru t

let rec string_of_memdefs_put stru = function
  []   -> ""
  | [h]  -> stru.fname_plain ^ "_put." ^ h.mdef_id ^ " != \"\" {"
  | h::t -> stru.fname_plain ^ "_put." ^ h.mdef_id ^ " != \"\" && "
     ^ string_of_memdefs_put stru t

let rec string_of_memdefs_poster stru = function
  []   -> ""
  | [h]  -> String.uncapitalize (h.mdef_id)
  | h::t -> String.uncapitalize (h.mdef_id) ^ ", "
     ^ string_of_memdefs_poster stru t

let rec string_of_memdefs_poster_insert stru = function
  []   -> ""
  | [h]  -> stru.fname_plain ^ "_post." ^ h.mdef_id
  | h::t -> stru.fname_plain ^ "_post." ^ h.mdef_id ^ ", "
     ^ string_of_memdefs_poster_insert stru t

let rec string_of_memdefs_poster_insert_body stru = function
  []   -> ""
  | [h]  -> h.mdef_id  ^ ": " ^ stru.fname_plain ^ "_post." ^ h.mdef_id ^ ",\n"
  | h::t -> h.mdef_id  ^ ": " ^ stru.fname_plain ^ "_post." ^ h.mdef_id ^ ",\n\t\t\t\t"
     ^ string_of_memdefs_poster_insert_body stru t

let rec string_of_memdefs_put_body stru = function
  []   -> ""
  | [h]  -> h.mdef_id ^ ": " ^ "json." ^ h.mdef_id ^ ",\n"
  | h::t -> h.mdef_id  ^ ": " ^ "json." ^ h.mdef_id ^ ",\n\t\t\t"
     ^ string_of_memdefs_put_body stru t

let rec string_of_memdefs_GetID stru = function
  []   -> ""
  | [h]  -> h.mdef_id  ^ ": " ^ stru.fname_plain ^ "_GetID." ^ h.mdef_id ^ ",\n"
  | h::t -> h.mdef_id  ^ ": " ^ stru.fname_plain ^ "_GetID." ^ h.mdef_id ^ ",\n\t\t\t\t"
     ^ string_of_memdefs_GetID stru t

let string_of_struct_post stru =
	string_of_memdefs_post stru stru.func_mdefs

let string_of_struct_poster stru =
  string_of_memdefs_poster stru stru.func_mdefs

let string_of_struct_poster_insert stru =
  string_of_memdefs_poster_insert stru stru.func_mdefs

let string_of_struct_poster_insert_body stru =
  string_of_memdefs_poster_insert_body stru stru.func_mdefs

let string_of_struct_put_body stru =
  string_of_memdefs_put_body stru stru.func_mdefs

let string_of_struct_put stru =
  string_of_memdefs_put stru stru.func_mdefs

let string_of_struct_GetID stru =
  string_of_memdefs_GetID stru stru.func_mdefs

let string_of_handle_func_arg arg =
	let arg_string =
		match arg.g_argtype with
			String  -> " := c.Param(\"" ^ String.uncapitalize arg.g_argid ^ "\")"
		  | Bool    -> ", err := strconv.ParseBool(c.Param(\"" ^ String.uncapitalize arg.g_argid ^ "\"))"
		  | Integer -> ", err := strconv.Atoi(c.Param(\"" ^ String.uncapitalize arg.g_argid ^ "\"))"
		  | Float   -> ", err := strconv.ParseFloat(c.Param(\"" ^ String.uncapitalize arg.g_argid ^ "\"), 64)"
		  | _       -> print_string "two"; raise Not_found (* dumb, temp error *) in
		  let err_mesg =
			match arg.g_argtype with
				String  -> ""
			  | Bool    -> "\tif	err != nil { c.String(400, \"Error: " ^ arg.g_argid ^ " must be a bool.\"); return }\n"
			  | Integer -> "\tif	err != nil { c.String(400, \"Error: " ^ arg.g_argid ^ " must be an integer.\"); return }\n"
			  | Float   -> "\tif	err != nil { c.String(400, \"Error: " ^ arg.g_argid ^ " must be a float.\"); return }\n"
			  | _       -> print_string "three"; raise Not_found (* dumb, temp error *) in
				  "\t" ^ String.uncapitalize arg.g_argid ^ arg_string ^ "\n" ^ err_mesg

let rec string_of_handle_func_args = function
	[]   -> ""
  | [h]  -> string_of_handle_func_arg h
  | h::t -> string_of_handle_func_arg h ^ string_of_handle_func_args t

let string_of_wrapper_param p = String.uncapitalize p.g_argid

let rec string_of_wrapper_params = function
	[]   -> ""
  | [h]  -> string_of_wrapper_param h
  | h::t -> string_of_wrapper_param h ^ ", " ^ string_of_wrapper_params t

let string_of_handle_func handlefunc = if handlefunc.htypes = Crud then
	"func " ^ "Get_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
	"\tvar " ^ handlefunc.fname_plain ^ "_get " ^ "[]" ^ handlefunc.fname_struct ^ "\n" ^
	"\t_, err := dbmap.Select(&" ^ handlefunc.fname_plain ^ "_get, \"SELECT * FROM " ^ handlefunc.fname_struct ^"\")\n" ^
    "\tif err == nil {\n" ^
    "  " ^ "\t\tc.JSON(200, " ^ handlefunc.fname_plain ^ "_get)\n" ^
    "\t}" ^ " " ^ "else" ^ " " ^ "{\n" ^
    "  " ^ "\t\tc.JSON(404, gin.H{\"error\": \"not able to find in the table\"})\n" ^
    "\t}" ^
"\n}\n\n" ^
	"func " ^ "Get_whereclause_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
	"\twhereclause := c.Params.ByName(\"whereclause\")\n" ^
	"\tvar " ^ handlefunc.fname_plain ^ "_get " ^ "[]" ^ handlefunc.fname_struct ^ "\n" ^
	"\t_, err := dbmap.Select(&" ^ handlefunc.fname_plain ^ "_get, \"SELECT * FROM " ^ handlefunc.fname_struct ^ " WHERE \" + whereclause)\n" ^
    "\tif err == nil {\n" ^
    "  " ^ "\t\tc.JSON(200, " ^ handlefunc.fname_plain ^ "_get)\n" ^
    "\t}" ^ " " ^ "else" ^ " " ^ "{\n" ^
    "  " ^ "\t\tc.JSON(404, gin.H{\"error\": \"not able to find in the table\"})" ^
    "\n\t}" ^
"\n}\n\n" ^
"func GetID_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
    "\tid := c.Params.ByName(\"id\")\n" ^
    "\tvar " ^ handlefunc.fname_plain ^ "_GetID " ^ handlefunc.fname_struct ^ "\n" ^
    "\terr := dbmap.SelectOne(&" ^ handlefunc.fname_plain ^ "_GetID, \"SELECT * FROM " ^ handlefunc.fname_struct ^ " WHERE id=?\", id)\n" ^
    "\tif err == nil {\n" ^
        "\t\t" ^ handlefunc.fname_plain ^ "_GetID_id, _ := strconv.ParseInt(id, 0, 64)\n" ^
        "\t\tcontent := &" ^ handlefunc.fname_struct ^ " {\n" ^
            "\t\t\tId: " ^ handlefunc.fname_plain ^ "_GetID_id,\n" ^
            "\t\t\t" ^ string_of_struct_GetID handlefunc ^
    "\t}\n" ^
        "\t\tc.JSON(200, content)\n" ^
    "\t} else {\n" ^
        "\t\tc.JSON(404, gin.H{\"error\": \"content not found\"})\n" ^
    "\t}\n" ^
"}\n\n" ^
	"func " ^ "Post_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
	"\tvar " ^ handlefunc.fname_plain ^ "_post " ^ handlefunc.fname_struct ^ "\n" ^
  "\tc.Bind(&" ^ handlefunc.fname_plain ^ "_post " ^ ")\n" ^
	"\tif " ^ string_of_struct_post handlefunc ^ "\n" ^
	"\t\tif insert, _ := dbmap.Exec(`INSERT INTO " ^ handlefunc.fname_struct ^ "("
    ^  string_of_struct_poster handlefunc ^ ")" ^ " VALUES (?, ?)`,\n" ^
	  "\t\t" ^string_of_struct_poster_insert handlefunc ^ ");" ^ "insert != nil {\n" ^
    "\t\t\t" ^ handlefunc.fname_plain ^ "_post_id, err := insert.LastInsertId()\n" ^
    "\t\t\tif err == nil {\n" ^
    "\t\t\t\tcontent := &" ^ handlefunc.fname_struct ^ " {\n" ^
    "\t\t\t\tId: " ^ handlefunc.fname_plain ^ "_post_id" ^ ",\n" ^
    "\t\t\t\t" ^ string_of_struct_poster_insert_body handlefunc ^
    "\t\t\t\t}\n" ^
    "\t\t\t\tc.JSON(201, content)\n" ^
   	"\t\t\t} else {\n" ^
      "\t\t\t\tcheckErr(err, \"Insert failed\")\n" ^
            "\t\t\t}\n" ^
        "\t\t}\n" ^
    "\t} else {\n" ^
        "\t\t\tc.JSON(422, gin.H{\"error\": \"fields are empty\"})\n" ^
    "\t}\n" ^
    "}\n\n" ^
"func Put_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
    "\tid := c.Params.ByName(\"id\")\n" ^
    "\tvar " ^ handlefunc.fname_plain ^ "_put " ^ handlefunc.fname_struct ^ "\n" ^
    "\terr := dbmap.SelectOne(&" ^ handlefunc.fname_plain ^ "_put, " ^ "\"SELECT * FROM " ^ handlefunc.fname_struct ^ " WHERE id=?\", id)\n" ^
    "\tif err == nil {\n" ^
        "\t\tvar json " ^ handlefunc.fname_struct ^ "\n" ^
        "\t\tc.Bind(&json)\n" ^
        "\t\t" ^ handlefunc.fname_plain ^ "_put_id, _ := strconv.ParseInt(id, 0, 64)\n" ^
        "\t\t" ^ handlefunc.fname_plain ^ "_put :=" ^ handlefunc.fname_struct ^ "{\n" ^
            "\t\t\tId: " ^ handlefunc.fname_plain ^ "_put_id,\n" ^
            "\t\t\t" ^ string_of_struct_put_body handlefunc ^
    "\t}\n" ^

    "\tif " ^ string_of_struct_put handlefunc ^ "\n" ^
        "\t\t_, err = dbmap.Update(&" ^ handlefunc.fname_plain ^ "_put " ^ ")\n" ^
        "\t\tif err == nil {\n" ^
        "\t\tc.JSON(200, " ^ handlefunc.fname_plain ^ "_put)\n" ^
    "\t} else {\n" ^
        "\t\tcheckErr(err, \"Update failed\")\n" ^
    "\t}\n" ^
    "\t} else {\n" ^
        "\t\tc.JSON(422, gin.H{\"error\": \"fields are empty\"})\n" ^
    "\t}\n" ^
    "\t} else {\n" ^
        "\t\tc.JSON(404, gin.H{\"error\": \"content not found\"})\n" ^
    "\t}\n" ^
"}\n\n" ^
"func Delete_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
    "\tid := c.Params.ByName(\"id\")\n" ^
    "\tvar " ^ handlefunc.fname_plain ^ "_delete " ^ handlefunc.fname_struct ^ "\n" ^
    "\terr := dbmap.SelectOne(&" ^ handlefunc.fname_plain ^ "_delete," ^
     "\"SELECT id FROM " ^ handlefunc.fname_struct ^ " WHERE id=?\", id)\n" ^
    "\tif err == nil {\n" ^
        "\t\t_, err = dbmap.Delete(&" ^ handlefunc.fname_plain ^ "_delete)\n" ^
        "\t\tif err == nil {\n" ^
            "\t\t\tc.JSON(200, gin.H{\"id #\" + id: \" deleted\"})\n" ^
        "\t\t} else {\n" ^
            "\t\t\tcheckErr(err, \"Delete failed\")\n" ^
        "\t\t}\n" ^
    "\t} else {\n" ^
        "\t\tc.JSON(404, gin.H{\"error\": \"content not found\"})\n" ^
    "\t}\n" ^
"}\n\n"
else 	"func " ^ "Get_" ^ handlefunc.fname_plain ^ "(c *gin.Context) {\n" ^
	string_of_handle_func_args handlefunc.hfargs ^
	"\t" ^ handlefunc.fname_struct ^ " := " ^ handlefunc.fname_wrapper ^
	"(" ^ string_of_wrapper_params handlefunc.hfargs ^ ")\n" ^
    "\tc.JSON(200, " ^ handlefunc.fname_struct ^ ")\n" ^
"}\n\n"

let rec string_of_handle_funcs = function
	[]   -> ""
  | [h]  -> string_of_handle_func h
  | h::t -> string_of_handle_func h ^ string_of_handle_funcs t

let rec string_of_vartype = function
    String  -> "string"
  | Bool    -> "bool"
  | Integer -> "int"
  | Float   -> "float64"
  | Custom(s) -> s ^ "_struct"
  | ListType(t) -> "[]" ^ string_of_vartype t

let string_of_garg m = String.uncapitalize m.g_argid ^ " " ^ string_of_vartype m.g_argtype

let rec string_of_gargs = function
	[]   -> ""
  | [h]  -> string_of_garg h
  | h::t -> string_of_garg h ^ ", " ^ string_of_gargs t

let struct_member_to_arg mem = {g_argid = mem.g_id; g_argtype = mem.g_vtype}

let rec struct_members_to_args = function
	[]   -> []
  | [h]  -> [struct_member_to_arg h]
  | h::t -> struct_member_to_arg h :: struct_members_to_args t

let set_struct_member_direct_assignment mem = {g_id = mem.g_id; g_vtype = mem.g_vtype; g_expr = Variable(String.uncapitalize mem.g_id);}

let rec set_struct_members_direct_assignment = function
	[]   -> []
  | [h]  -> [set_struct_member_direct_assignment h]
  | h::t -> set_struct_member_direct_assignment h :: set_struct_members_direct_assignment t

let string_of_struct_wrapper structwrapper =
	if structwrapper.wrap_htypes = Get
	then
		"func " ^ structwrapper.wname ^ "(" ^ string_of_gargs structwrapper.wargs ^ ") " ^
		structwrapper.returntype ^ " {\n\treturn " ^ structwrapper.returntype ^ "{" ^
		string_of_vdecls structwrapper.members ^ "}\n}\n\n"
	else (if structwrapper.wrap_htypes = ObjHType
		  then
			  "func " ^ structwrapper.wname ^ "(" ^ string_of_gargs (struct_members_to_args structwrapper.members) ^ ") " ^
			  structwrapper.returntype ^ " {\n\treturn " ^ structwrapper.returntype ^ "{" ^
			  string_of_vdecls (set_struct_members_direct_assignment structwrapper.members) ^ "}\n}\n\n"
		  else "")

let rec string_of_struct_wrappers = function
	[]   -> ""
  | [h]  -> string_of_struct_wrapper h
  | h::t -> string_of_struct_wrapper h ^ string_of_struct_wrappers t

let string_of_queryarg a = "/:" ^ String.uncapitalize a.g_argid

let rec string_of_queryargs = function
	[]   -> ""
  | [h]  -> string_of_queryarg h
  | h::t -> string_of_queryarg h ^ string_of_queryargs t

let string_of_handledef hdef =
	if hdef.htypess = Crud then
		"\trouter.GET(\"" ^ hdef.path ^ "\", " ^ "Get_" ^ hdef.hname_plain ^ ")\n" ^
		"\trouter.GET(\"" ^ hdef.path ^ "/where/:whereclause" ^ "\", " ^ "Get_whereclause_" ^ hdef.hname_plain ^ ")\n" ^
		"\trouter.GET(\"" ^ hdef.path ^ "/id/:id" ^ "\", " ^ "GetID_" ^ hdef.hname_plain ^ ")\n" ^
		"\trouter.POST(\"" ^ hdef.path ^ "\", " ^ "Post_" ^ hdef.hname_plain ^ ")\n" ^
		"\trouter.PUT(\"" ^ hdef.path ^ "/:id\", " ^ "Put_" ^ hdef.hname_plain ^ ")\n" ^
		"\trouter.DELETE(\"" ^ hdef.path ^ "/:id\", " ^ "Delete_" ^ hdef.hname_plain ^ ")"
	else "\trouter.GET(\"" ^ hdef.path ^ string_of_queryargs hdef.hdargs ^ "\", " ^ "Get_" ^ hdef.hname_plain ^ ")"

let rec string_of_handledefs = function
	[]   -> ""
  | [h]  -> string_of_handledef h
  | h::t -> string_of_handledef h ^ "\n" ^ string_of_handledefs t

let string_of_main handledefs =
	"func main() {\n" ^
	"\trouter := gin.Default()\n" ^
	string_of_handledefs handledefs ^ "\n" ^
	"\trouter.Run(\":\"+os.Getenv(\"PORT\"))\n}"

let string_of_handledef_db hdef =
	hdef.db

let rec string_of_handledefs_db = function
	[]   -> ""
  | [h]  when h.htypess = Crud ->
    "\tdbmap.AddTableWithName(" ^ string_of_handledef_db h ^ "{}, " ^ "\"" ^string_of_handledef_db h ^ "\""
        ^ ").SetKeys(true, \"Id\")\n"
  | h::t when h.htypess = Crud ->
    "\tdbmap.AddTableWithName(" ^ string_of_handledef_db h ^ "{}, " ^ "\"" ^ string_of_handledef_db h ^ "\""
        ^ ").SetKeys(true, \"Id\")\n" ^ string_of_handledefs_db t
  | h::t -> string_of_handledefs_db t

let string_of_main_db handlefunc handledefs count =
	if handlefunc.htypes = Crud && count == 0 then
		"var dbmap = initDb()\n\n" ^
		"func initDb() *gorp.DbMap {\n" ^
		"\tdb, err := sql.Open(\"mysql\", \"root:root@tcp(localhost:8889)/wasp\")\n" ^
		"\tcheckErr(err, \"sql.Open failed\")\n" ^
	"\tdbmap := &gorp.DbMap{Db: db, Dialect:gorp.MySQLDialect{\"InnoDB\", \"UTF8\"}}\n" ^
    	string_of_handledefs_db handledefs ^
	"\terr = dbmap.CreateTablesIfNotExists()\n" ^
	"\tcheckErr(err, \"Create table failed\")\n" ^
	"\treturn dbmap\n}" ^ "\n\n" ^
	"func checkErr(err error, msg string) {\n" ^
	"\tif err != nil {log.Fatalln(msg, err)}\n}" ^ "\n\n"
	else ""

let rec string_of_main_dbs handledefs count= function
	[]   -> ""
  | [h]  -> string_of_main_db h handledefs count
  | h::t -> string_of_main_db h handledefs count ^ "" ^ string_of_main_dbs handledefs (count+1) t

let string_of_memdef m =
	"\t" ^ m.mdef_id ^ " " ^ string_of_vartype m.mdef_vtype ^ " `db:\"" ^ String.uncapitalize m.mdef_id ^
	"\"" ^ " json:\"" ^ String.uncapitalize m.mdef_id ^ "\"`\n"

let rec string_of_memdefs = function
	[]   -> ""
  | [h]  -> string_of_memdef h
  | h::t -> string_of_memdef h ^ string_of_memdefs t

let memdef_to_arg m = m.mdef_id ^ " " ^ string_of_vartype m.mdef_vtype

let rec memdefs_to_args = function
	[]   -> ""
  | [h]  -> memdef_to_arg h
  | h::t -> memdef_to_arg h ^ ", " ^ memdefs_to_args t

let string_of_struct stru = if stru.shtypes = Crud then
	"type " ^ stru.sname ^ " struct {\n" ^ "\tId int64 `db:\"id\" json:\"id\"`\n" ^ string_of_memdefs stru.mdefs ^ "}\n\n"
else "type " ^ stru.sname ^ " struct {\n" ^ string_of_memdefs stru.mdefs ^ "}\n\n"
let rec string_of_structs = function
	[]   -> ""
  | [h]  -> string_of_struct h
  | h::t -> string_of_struct h ^ string_of_structs t

let string_of_import import =
	if import ="github.com/go-sql-driver/mysql" then
		"\t_ \"" ^ import ^ "\""
	else "\t\"" ^ import ^ "\""

let rec string_of_imports = function
	[]   -> ""
  | [h]  -> string_of_import h
  | h::t -> string_of_import h ^ "\n" ^ string_of_imports t

let string_of_func_vdecl v = String.uncapitalize v.g_id ^ " := " ^ string_of_expr v.g_expr

let rec
string_of_func_stmt = function
	Block(s)            -> "{\n" ^ string_of_func_stmts s ^ "\t}"
  | Vardecl(v)          -> "\t" ^ string_of_func_vdecl v ^ "\n"
  | Assign(s, e)        -> "\t" ^ s ^ " = " ^ string_of_expr e ^ "\n"
  | If(e, s, Block([])) -> "\tif " ^ string_of_expr e ^ " " ^ string_of_func_stmt s ^ "\n"
  | If(e, s1, s2)       -> "\tif " ^ string_of_expr e  ^ " " ^ string_of_func_stmt s1 ^ " else " ^ string_of_func_stmt s2 ^ "\n"
  | While(e, s)         -> "\tfor " ^ string_of_expr e ^ " " ^ string_of_func_stmt s ^ "\n"
  | Return(e)           -> "\treturn " ^ string_of_expr e ^ "\n"
and
string_of_func_stmts = function
	[]   -> ""
  | [h]  -> string_of_func_stmt h
  | h::t -> string_of_func_stmt h ^ string_of_func_stmts t

let string_of_func func =
	"func " ^ func.go_fname ^ "(" ^ string_of_gargs func.go_args ^ ") " ^ string_of_vartype func.go_ftype ^ " {\n" ^ string_of_func_stmts func.go_body ^ "}\n\n"

let rec string_of_funcs = function
	[]   -> ""
  | [h]  -> string_of_func h
  | h::t -> string_of_func h ^ string_of_funcs t

let string_of_global v = "var " ^ String.uncapitalize v.g_id ^ " = " ^ (string_of_expr v.g_expr) ^ "\n"

let rec string_of_globals = function
	[]   -> ""
  | [h]  -> string_of_global h ^ "\n"
  | h::t -> string_of_global h ^ string_of_globals t

let string_of_conv_funcs =
"func int_conv(anything interface{}) int {
	switch v := anything.(type) {
		case int:
			return v
		case float64, float32:
			var float_var = v.(float64)
			return int(math.Trunc(float_var))
		default:
			return 0
	}
	return 0
}

func float_conv(anything interface{}) float64 {
 	 switch v := anything.(type) {
		case int:
            return float64(v)
		case float64:
			return v
		default:
			return 0
	}
	return 0.0
}\n\n"

let skeleton imports gvars structs handledefs funcs structwrappers handlefunctions =
    let formatted_imports = string_of_imports imports in
	let formatted_conv_functions = string_of_conv_funcs in
	let formatted_gvars = string_of_globals gvars in
    let formatted_structs = string_of_structs structs in
    let main_db = (string_of_main_dbs handledefs 0 handlefunctions) in
	let main_func = string_of_main handledefs in
	let formatted_funcs = string_of_funcs funcs in
	let formatted_swrappers = string_of_struct_wrappers structwrappers in
	let formatted_hfuncs = (string_of_handle_funcs handlefunctions) in
	let program_string =
    "package main\n\n" ^
    "import (\n" ^ formatted_imports ^ "\n)\n\n" ^
	formatted_conv_functions ^
	formatted_gvars ^
    formatted_structs ^
    main_db ^
    main_func ^ "\n\n" ^
    formatted_funcs ^
	formatted_swrappers ^
    formatted_hfuncs in
	(* Remove the additional newline found at the end of all program strings *)
	String.sub program_string 0 ((String.length program_string) - 1)

let string_of_program gast =
    let (imports, gvars, structs, handledefs, funcs, structwrappers, handlefunctions) = gast in
    skeleton imports gvars structs handledefs funcs structwrappers handlefunctions
