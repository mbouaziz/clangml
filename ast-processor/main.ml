open ClangApi
open ClangAst


let memcad_parse file =
  let fh = open_in file in
  let lexbuf = Lexing.from_channel fh in
  let ast = C_parser.entry C_lexer.token lexbuf in
  close_in fh;
  prerr_endline "--------------------- MemCAD PP ---------------------";
  C_utils.ppi_c_prog "" stderr ast;
;;


let process () =
  let file, decl = request @@ Compose (Filename, TranslationUnit) in

  (*prerr_endline (Show.show<ClangAst.decl> decl);*)
  memcad_parse file;
  prerr_endline "--------------------- Clang AST ---------------------";
  Format.fprintf Format.err_formatter "@[<v2>Declaration:@,%a@]@."
    ClangPp.pp_decl decl;
  prerr_endline "----------------- Clang -> MemCAD -------------------";
  C_utils.ppi_c_prog "" stderr (Transform.c_prog_from_decl decl);
  prerr_endline "-----------------------------------------------------"


let initialise () =
  match request @@ Handshake ClangAst.version with
  | None ->
      (* Handshake OK; request filename and translation unit. *)
      process ()

  | Some version ->
      failwith (
        "AST versions do not match: \
         server says " ^ version ^
        ", but we have " ^ ClangAst.version
      )


let () =
  Printexc.record_backtrace true;
  initialise ();
;;