{ open Parser }

let floaty = (['0'-'9']+['.']['0'-'9']*)|(['0'-'9']*['.']['0'-'9']+)

rule token = parse
  [' ' '\t' '\r' '\n'] { token lexbuf } (* Whitespace *)
| "/*"       { comment lexbuf }           (* Comments *)
(* keywords *)
| "Endpoint" { END }
| "Object"   { OBJ }
| "Func"     { FUNC }
| "return"   { RETURN }
(* structure *)
| '('        { LPAREN }
| ')'        { RPAREN }
| '{'        { LBRACE }
| '}'        { RBRACE }
| ']'		 { RBRACKET }
| '['		 { LBRACKET }
| ';'        { SEMI }
| ':'        { COLON }
| ','        { COMMA }
(* operators *)
| '='        { ASSIGN }
| '+'        { PLUS }
| '-'        { MINUS }
| '*'        { TIMES }
| '/'        { DIVIDE }
| ".+"       { DOTPLUS }
| ".-"       { DOTMINUS }
| ".*"       { DOTTIMES }
| "./"       { DOTDIVIDE }
| "not"      { BNOT }
| "and"      { BAND }
| "or"       { BOR }
| "xor"      { BXOR }
| "mod"      { MOD }
| ">="       { GEQ }
| ">"        { GT }
| "<"        { LT }
| "<="       { LEQ }
| "!="       { NEQ }
| "=="       { EE }
(* lists & strings *)
| "list"     { LIST }
| "@"        { ACCESS }
|  "->"      { RANGE }
| "sizeof"   { SIZEOF}
| "cap"      { CAP }
| "low"      { LOW }
| "++"       { LCAT }
| "~="       { SCONT }
| "^"        { SCAT }
(* types *)
| "string"   { STRING }
| "bool"     { BOOL }
| "int"      { INT }
| "float"    { FLOAT }
| "Endpoint" { END }
| "Object"   { OBJ }
| "Func"     { FUNC }
| "if"       { IF }
| "else"     { ELSE }
| "while"    { WHILE }
| "return"   { RETURN }
(* htypes *)
| "GET"      { GET }
| "CRUD"	 { CRUD }
(* literals *)
| ['"']([^'"']* as str)['"']  { STRLIT(str) }
| "true"                      { BOOLLIT(true) }
| "false"                     { BOOLLIT(false) }
| (['0'-'9']+ as inte)        { INTLIT(int_of_string inte) }
| floaty as flt               { FLOATLIT(float_of_string flt) }
| ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']* as lxm { ID(lxm) }
| eof { EOF }
| _ as char { raise (Failure("illegal character " ^ Char.escaped char)) }

and comment = parse
  "*/" { token lexbuf }
| _    { comment lexbuf }
