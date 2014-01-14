module Log = Logger.Make(struct let tag = "main" end)


(**
  Turn an underscore_name into a CamelcaseName.
  This function is non-destructive and returns a new string.
 *)
let cpp_name name =
  let rec to_camelcase length name =
    try
      let underscore = String.index name '_' in
      String.blit
        name (underscore + 1)
        name underscore
        (length - underscore - 1);
      name.[underscore] <- Char.uppercase name.[underscore];
      to_camelcase (length - 1) name
    with Not_found ->
      (* Second copy here. *)
      String.sub name 0 length
  in
  (* First copy here. *)
  to_camelcase (String.length name) (String.capitalize name)


(*****************************************************
 * Enum (all tycons are nullary)
 *****************************************************)

let enum_interface_for_constant_sum_type (sum_type_name, branches) =
  (* Explicitly make the first enum have value 0, the second have value 2, etc.*)
  let enum_elements =
    List.mapi (fun i (branch_name, _) ->
      (branch_name, Some i)
    ) branches
  in

  Codegen.({
    enum_name = sum_type_name;
    enum_elements = enum_elements;
  })


let sum_type_is_enum (sum_type_name, branches) =
  List.for_all (fun (branch_name, types) ->
    types = []
  ) branches


(*****************************************************
 * Class (none of the tycons are nullary)
 *****************************************************)


let class_interface_for_sum_type (sum_type_name, branches) =
  let open Codegen in

  (* Base class *)
  let base =
    let class_members =
      [
        MemberFunction ([], TyInt, "doStuff", []);
        MemberField { decl_type = TyInt; decl_name = "field"; };
      ]
    in
    {
      class_name = cpp_name sum_type_name;
      class_bases = ["OCamlADTBase"];
      class_members;
    }
  in

  let derived =
    let toValue =
      MemberFunction ([Virtual], TyName "value", "ToValue", [])
    in
    List.map (fun (branch_name, types) ->
      let rec translate_type = let open Parse in function
        | NamedType "int" ->
            TyInt
        | NamedType "string" ->
            TyString
        | NamedType name ->
            TyPointer (TyName (cpp_name name))
        | ClangType name ->
            TyPointer (TyName ("clang::" ^ name))
        | ListOfType ty ->
            TyTemplate ("std::list", translate_type ty)
      in

      let constructors =
        let args = 
          List.mapi (fun i ty ->
            {
              decl_type = translate_type ty;
              decl_name = "arg" ^ string_of_int i;
            }
          ) types
        in
        [
          (* Constructor without clang object; pointer will be NULL. *)
          MemberConstructor (List.tl args);
          (* Constructor with pointer to clang object. *)
          MemberConstructor (args);
        ]
      in

      let fields =
        List.mapi (fun i ty ->
          MemberField {
            decl_type = translate_type ty;
            decl_name = "field" ^ string_of_int i;
          }
        ) types
      in

      let class_members =
        toValue :: constructors @ fields
      in

      {
        class_name = branch_name;
        class_bases = [base.class_name];
        class_members;
      }
    ) branches
  in
  base :: derived


(*****************************************************
 * Main
 *****************************************************)

let gen_code_for_sum_type (sum_type : Parse.sum_type) =
  if sum_type_is_enum sum_type then
    [Codegen.Enum (enum_interface_for_constant_sum_type sum_type)]
  else
    List.map (fun i -> Codegen.Class i)
      (class_interface_for_sum_type sum_type)


let gen_code_for_ocaml_type = function
  | Parse.SumType sum_type ->
      gen_code_for_sum_type sum_type
  | Parse.RecursiveType rec_types ->
      List.map gen_code_for_sum_type rec_types
      |> List.flatten


let code_gen (sum_types : Parse.ocaml_type list) =
  let cpp_types =
    List.map gen_code_for_ocaml_type sum_types
    |> List.flatten
  in
  let cg = Codegen.make_codegen_with_channel stdout in
  Codegen.emit_interfaces cg cpp_types;
  Codegen.flush cg


let parse_and_generate filename =
  let sum_types = Parse.parse_file filename in
  print_endline (Show.show_list<Parse.ocaml_type> sum_types);
  code_gen sum_types

  (* TODO: Think about detecting versioning mismatch between generated and ocaml ast.*)
  (* Maybe keep a version number around someplace?*)


let () =
  parse_and_generate "hello_ast.ml"
