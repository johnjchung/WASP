type action = Ast | Sast | Gast
exception SyntaxError of int * int * string;;

let _ =
    let action = if Array.length Sys.argv > 1 then
        List.assoc Sys.argv.(1) [
            ("-a", Ast);
            ("-s", Sast);
            ("-g", Gast);
        ]
    else Gast in (* Assume compiling *)
    let lexbuf = Lexing.from_channel (open_in Sys.argv.(2)) in
    let ast = try
        Parser.program Scanner.token lexbuf
    with except ->
        let curr = lexbuf.Lexing.lex_curr_p in
        let line = curr.Lexing.pos_lnum in
        let col = curr.Lexing.pos_cnum in
        let tok = Lexing.lexeme lexbuf in
        raise (SyntaxError (line, col, tok))
    in
    match action with
        | Ast -> print_string (Ast_printer.string_of_program ast)
        | Sast -> let sast = Semantic_check.sast_from_ast ast in
                      print_string (Sast_printer.string_of_program sast)
        | Gast -> let _ = Semantic_check.sast_from_ast ast in
                  let gast = Translate.gast_from_ast ast 
            in
                    print_string (Gast_printer.string_of_program gast)