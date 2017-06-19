%{ open Ast %}

%token SEMI LPAREN RPAREN LBRACE RBRACE COLON COMMA LIST LBRACKET RBRACKET
%token PLUS MINUS TIMES DIVIDE DOTPLUS DOTMINUS DOTTIMES DOTDIVIDE BNOT BAND BXOR BOR MOD GT LT GEQ LEQ EE SCONT NEQ SCAT
%token ACCESS RANGE SIZEOF LCAT CAP LOW
%token UMINUS
%token ASSIGN
%token STRING BOOL INT FLOAT
%token END OBJ
%token FUNC IF ELSE RETURN WHILE
%token GET CRUD
%token <string> STRLIT
%token <bool>   BOOLLIT
%token <int>    INTLIT
%token <float>  FLOATLIT
%token <string> ID
%token EOF

%nonassoc NOELSE
%nonassoc ELSE
%right ASSIGN
%left BAND BXOR BOR
%left GT LT GEQ LEQ EE SCONT NEQ
%left DOTPLUS DOTMINUS PLUS MINUS SCAT LCAT
%left DOTTIMES DOTDIVIDE TIMES DIVIDE MOD
%left ACCESS
%left RANGE
%left SIZEOF
%left CAP LOW
%right BNOT UMINUS

%start program
%type <Ast.program> program

%%

program:
  decls EOF { $1 }

decls:
    /* nothing */ { [], [], [] }
  | decls vdecl { let (members, odecls, fdecls) = $1 in
                      ($2::members, odecls, fdecls) }
  | decls odecl { let (members, odecls, fdecls) = $1 in
                      (members, $2::odecls, fdecls) }
  | decls fdecl { let (members, odecls, fdecls) = $1 in
                      (members, odecls, $2::fdecls) }

odecl:
    END ID LPAREN htype COLON arg_list_opt RPAREN LBRACE vdecl_list RBRACE
      { { oname = $2;
          otype = Endpoint;
          htypes = $4;
          args = List.rev $6;
          vdecls = List.rev $9 } }
 |  OBJ ID LPAREN RPAREN LBRACE vdecl_list RBRACE
      { { oname = $2;
          otype = Object;
          htypes = ObjHType;
          args = [];
          vdecls = List.rev $6 } }

fdecl:
    FUNC var_type ID LPAREN arg_list_opt RPAREN LBRACE stmt_list_opt RBRACE
      { { fname = $3;
          ftype = $2;
          args = List.rev $5;
          body = List.rev $8 } }

htype:
    GET  { Get }
  | CRUD { Crud }

var_type:
    STRING              { String }
  | BOOL                { Bool }
  | INT                 { Integer }
  | FLOAT               { Float }
  | ID                  { Custom($1) } /* User-defined Object Type */
  | LIST LT var_type GT { ListType($3) }

arg_list_opt:
    /* nothing */   { [] }
  | arg_list        { $1 }

arg_list:
  | arg_def                  { [$1] }
  | arg_list COMMA arg_def   { $3 :: $1 }

arg_def:
    var_type ID { { argtype = $1; argid = $2 } }

vdecl_list:
    vdecl             { [$1] }
  | vdecl_list vdecl  { $2 :: $1 }

vdecl:
    var_type ID ASSIGN expr SEMI { { vtype = $1; id = $2; expr = $4; } }
  | var_type ID SEMI             { { vtype = $1; id = $2; expr = Noexpr} }

stmt:
    vdecl                                   		 { Vardecl($1) }
  | ID ASSIGN expr SEMI                     		 { Assign($1, $3) }
  | LBRACE stmt_list RBRACE                 		 { Block(List.rev $2) }
  | IF LPAREN expr RPAREN stmt %prec NOELSE 		 { If($3, $5, Block([])) }
  | IF LPAREN expr RPAREN stmt ELSE stmt    		 { If($3, $5, $7) }
  | WHILE LPAREN expr RPAREN stmt 					 { While($3, $5) }
  | RETURN expr SEMI                        		 { Return($2) }

stmt_list_opt:
    /* nothing */  { [] }
  | stmt_list      { $1 }

stmt_list:
    stmt           { [$1] }
  | stmt_list stmt { $2 :: $1 }

expr_list_opt:
    /* nothing */  { [] }
  | expr_list        { $1 }

expr_list:
  | expr                 { [$1] }
  | expr_list COMMA expr { $3 :: $1 }

list_data_list:
  | expr            { [$1] }
  | list_data_list COMMA expr { $3 :: $1 }

expr:
    LPAREN expr RPAREN                   { $2 }
  /* literals */
  | STRLIT                               { Strlit($1) }
  | BOOLLIT                              { Boollit($1) }
  | INTLIT                               { Intlit($1) }
  | FLOATLIT                             { Floatlit($1) }
  | ID LBRACE expr_list_opt RBRACE       { Objlit($1, $3) }
  | LBRACKET list_data_list RBRACKET     { Listlit($2) }
  /* variable */
  | ID                                   { Variable($1) }
  /* function call */
  | ID LPAREN expr_list_opt RPAREN       { Funcall($1, $3) }
  /* binops */
  | expr PLUS   expr                     { Binop($1, Add,   $3) }
  | expr MINUS  expr                     { Binop($1, Sub,   $3) }
  | expr TIMES  expr                     { Binop($1, Mult,  $3) }
  | expr DIVIDE expr                     { Binop($1, Div,   $3) }
  | expr DOTPLUS   expr                  { Binop($1, DotAdd,   $3) }
  | expr DOTMINUS  expr                  { Binop($1, DotSub,   $3) }
  | expr DOTTIMES  expr                  { Binop($1, DotMult,  $3) }
  | expr DOTDIVIDE expr                  { Binop($1, DotDiv,   $3) }
  | expr BAND expr                       { Binop($1, And, $3) }
  | expr BOR expr                        { Binop($1, Or,  $3) }
  | expr BXOR expr                       { Binop($1, Xor, $3) }
  | expr MOD expr                        { Binop($1, Mod, $3) }
  | expr SCONT expr                      { Binop($1, Scont, $3) }
  | expr LT expr                         { Binop($1, Lt, $3) }
  | expr GT expr                         { Binop($1, Gt, $3) }
  | expr EE expr                         { Binop($1, Ee, $3) }
  | expr GEQ expr                        { Binop($1, Geq, $3) }
  | expr LEQ expr                        { Binop($1, Leq, $3) }
  | expr NEQ expr                        { Binop($1, Neq, $3) }
  | expr SCAT expr                       { Binop($1, Scat, $3) }
  | expr ACCESS expr                     { Binop($1, Access, $3) }
  | expr RANGE expr                      { Binop($1, Range, $3) }
  | expr LCAT expr                       { Binop($1, Lcat, $3) }
  /* unops */
  | CAP expr                             { Unop(Cap, $2) }
  | LOW expr                             { Unop(Low, $2) }
  | SIZEOF expr                          { Unop(Sizeof, $2) }
  | BNOT expr                            { Unop(Not, $2) }
  | MINUS expr %prec UMINUS              { Unop(Neg, $2) }
