(* MicroC by Stephen Edwards Columbia University *)
(* Code generation: translate takes a semantically checked AST and
produces LLVM IR

LLVM tutorial: Make sure to read the OCaml version of the tutorial

http://llvm.org/docs/tutorial/index.html

Detailed documentation on the OCaml LLVM library:

http://llvm.moe/
http://llvm.moe/ocaml/

*)

module L = Llvm
module A = Ast

module StringMap = Map.Make(String)

let translate (globals, functions, structs) =
  let context = L.global_context () in
  let the_module = L.create_module context "MicroC"
  and i32_t  = L.i32_type  context
  and i8_t   = L.i8_type   context
  and i1_t   = L.i1_type   context
  and void_t = L.void_type context
  and ptr_t  = L.pointer_type (L.i8_type (context))  in



	
(*	1. Define map at the beginning
	2. Write get_type function that takes A.type -> ltype
		a. In the case of struct, lookup in map
	3. Define loop that goes over sdecls and adds them to map
	4. Add loop to series of calls at end of translate
*)
	

	let struct_types:(string, L.lltype) Hashtbl.t = Hashtbl.create 50 in

        let add_empty_named_struct_types sdecl =
		let struct_t = L.named_struct_type context sdecl.A.sname in
		Hashtbl.add struct_types sdecl.A.sname struct_t
	in
	let generate_struct_types =
		List.map add_empty_named_struct_types structs 
	in
	let find_struct_type sname =
		Hashtbl.find struct_types sname
	in

	let ltype_of_typ = function
		A.Int -> i32_t
	| 	A.Bool -> i1_t
 	|	A.Void -> void_t
	| 	A.StructType s ->  Hashtbl.find struct_types s
	|	A.MyString -> ptr_t in 

	let populate_struct_type sdecl = 
		let struct_t = Hashtbl.find struct_types sdecl.A.sname in
		let type_list = Array.of_list(List.map (fun(t, _) -> ltype_of_typ t) sdecl.A.formals) in
		L.struct_set_body struct_t type_list true
	in 
	let whatever = List.map populate_struct_type structs in
	
  (*struct_field_index is a map where key is struct name and value is another map*)
  (*in the second map, the key is the field name and the value is the index number*)
  let struct_field_index_list =
	let handle_list m individual_struct = 
		(*list of all field names for that struct*) 
		let struct_field_name_list = List.map snd individual_struct.A.formals in
		let increment n = n + 1 in
		let add_field_and_index (m, i) field_name =
			(*add each field and index to the second map*)
			(StringMap.add field_name (increment i) m, increment i) in
		(*struct_field_map is the second map, with key = field name and value = index*)
		let struct_field_map = 
			List.fold_left add_field_and_index (StringMap.empty, -1) struct_field_name_list
		in
		(*add field map (the first part of the tuple) to the main map*)
		StringMap.add individual_struct.sname (fst struct_field_map) m	
	in
	List.fold_left handle_list StringMap.empty structs	
  in

  (* Declare each global variable; remember its value in a map *)
  let global_vars =
    let global_var m (t, n) =
      let init = L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in

  (* Declare printf(), which the print built-in function will call *)
  let printf_t = L.var_arg_function_type i32_t [| L.pointer_type i8_t |] in
  let printf_func = L.declare_function "printf" printf_t the_module in

  (* Define each function (arguments and return type) so we can call it *)
  let function_decls =
    let function_decl m fdecl =
      let name = fdecl.A.fname
      and formal_types =
	Array.of_list (List.map (fun (t,_) -> ltype_of_typ t) fdecl.A.formals)
      in let ftype = L.function_type (ltype_of_typ fdecl.A.typ) formal_types in
      StringMap.add name (L.define_function name ftype the_module, fdecl) m in
    List.fold_left function_decl StringMap.empty functions in
  
  (* Fill in the body of the given function *)
  let build_function_body fdecl =
    let (the_function, _) = StringMap.find fdecl.A.fname function_decls in
    let builder = L.builder_at_end context (L.entry_block the_function) in

    let int_format_str = L.build_global_stringptr "%d\n" "fmt" builder in
   
    let llvalue_lltype_hash:(L.llvalue, L.lltype) Hashtbl.t = Hashtbl.create 50 in
 
    let add_to_llvalue_lltype_hash value var_type =
	Hashtbl.add llvalue_lltype_hash value var_type
    in
 
    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
      let add_formal m (t, n) p = L.set_value_name n p;
	let local_vars_type = ltype_of_typ t
        in
	let local = L.build_alloca local_vars_type n builder
        in
	let blah = add_to_llvalue_lltype_hash local local_vars_type
	in
	ignore (L.build_store p local builder);
	StringMap.add n local m in

      let add_local m (t, n) =
        let local_type = ltype_of_typ t
        in
	let local_var = L.build_alloca local_type n builder
	in
	let blah = add_to_llvalue_lltype_hash local_var local_type
	in StringMap.add n local_var m in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.A.formals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.A.locals in

    (* Return the value for a variable or formal argument *)
    let lookup n = try StringMap.find n local_vars
                 with Not_found -> try StringMap.find n global_vars
                 with Not_found -> raise (Failure ("undeclared variable " ^ n))
    in
    let string_option_to_string = function
	None -> ""
	|Some(s) -> s

    in
    (* Construct code for an expression; return its value *)
    let rec expr builder = function
	A.Literal i -> L.const_int i32_t i
(*      | A.MyStringLit str -> L.const_stringz context str *)
      | A.MyStringLit str -> L.build_global_stringptr str "tmp" builder
      | A.BoolLit b -> L.const_int i1_t (if b then 1 else 0)
      | A.Noexpr -> L.const_int i32_t 0
      | A.Id s -> L.build_load (lookup s) s builder
      | A.Binop (e1, op, e2) ->
	  let e1' = expr builder e1
	  and e2' = expr builder e2 in
	  (match op with
	    A.Add     -> L.build_add
	  | A.Sub     -> L.build_sub
	  | A.Mult    -> L.build_mul
          | A.Div     -> L.build_sdiv
	  | A.And     -> L.build_and
	  | A.Or      -> L.build_or
	  | A.Equal   -> L.build_icmp L.Icmp.Eq
	  | A.Neq     -> L.build_icmp L.Icmp.Ne
	  | A.Less    -> L.build_icmp L.Icmp.Slt
	  | A.Leq     -> L.build_icmp L.Icmp.Sle
	  | A.Greater -> L.build_icmp L.Icmp.Sgt
	  | A.Geq     -> L.build_icmp L.Icmp.Sge
	  ) e1' e2' "tmp" builder
    | A.Dotop(e1, field) -> let e' = expr builder e1 in
      (match e1 with
          A.Id s -> let etype = fst( 
                try
                    List.find (fun t->snd(t)=s) fdecl.A.locals
                with Not_found -> raise (Failure("Unable to find" ^ s)))
                in
            (try match etype with
              A.StructType t-> 
		(*	raise (Failure(L.string_of_lltype (L.type_of (L.build_load (L.build_struct_gep (lookup s) (StringMap.find field (StringMap.find t struct_field_index_list)) field builder) "tmp" builder))))
*)

 	 L.build_load (L.build_struct_gep (lookup s) (StringMap.find field (StringMap.find t struct_field_index_list)) field builder) "tmp" builder
	(*let dot_op_answer_type = L.type_of dot_op_answer in
	let dot_op_answer_type_string_option = L.struct_name dot_op_answer_type in
	let dot_op_answer_type_string = string_option_to_string dot_op_answer_type_string_option in
	try let _ = Hashtbl.find struct_types dot_op_answer_type_string in
	    
 	L.build_struct_gep (lookup s) (StringMap.find field (StringMap.find t struct_field_index_list)) field builder
		 with Not_found -> dot_op_answer*)
              | _ -> raise (Failure("No structype.")) 
              with Not_found -> raise (Failure("unable to find" ^s)) 
            )
        | _ -> raise (Failure("Not a struct."))
      )
      | A.Unop(op, e) ->
	  let e' = expr builder e in
	  (match op with
	    A.Neg     -> L.build_neg
          | A.Not     -> L.build_not) e' "tmp" builder
      | A.SAssign(e1, field, e2) -> 
	let e2' = expr builder e2 in
	(match e1 with
		A.Id s ->
			let e1typ = fst(try
				List.find (fun t -> snd(t) = s) fdecl.A.locals
				with Not_found -> raise(Failure("poop1")))
			in
			(match e1typ with
				A.StructType t -> (try 
					let index_number_list = StringMap.find t struct_field_index_list in
                      			let index_number = StringMap.find field index_number_list in
                      			let pointer_to_struct_field =
						L.build_struct_gep (lookup s) index_number field builder
					in
                      		(*	in raise(Failure(L.string_of_llvalue pointer_to_struct_field)) *)
                      			(try (ignore (L.build_store e2' pointer_to_struct_field builder); e2')
                        		with Not_found -> raise (Failure("unable to find " ^ t)))
                    	 	with Not_found -> raise(Failure("_")) )
                 	|_ -> raise (Failure("StructType not found")) )
		|_ as e1_expr ->
			let e1' = expr builder e1_expr in
			let e1'_lltype = L.type_of e1'  in
			let e1'_struct_name_string_option = L.struct_name e1'_lltype in
			let e1'_struct_name_string = string_option_to_string e1'_struct_name_string_option in
			let index_number_list = (StringMap.find e1'_struct_name_string struct_field_index_list) in
			let index_number = StringMap.find field index_number_list in
			let e1'_pointer_value = L.build_pointercast e1' (L.type_of e1') "temp" builder in
			let e1'_pointer_type = L.pointer_type e1'_lltype in
			let e1'_pointer_value = L.build_alloca e1'_pointer_type "pointer_val" builder in
			let val_store = L.build_alloca e1'_lltype "help" builder in
			let _ =  L.build_store e1' val_store in
			let _ = L.build_store val_store e1'_pointer_value in
			(*raise (Failure(L.string_of_llvalue e1'_pointer_value)) *)
			let pointer_to_struct_field = L.build_struct_gep val_store index_number field builder in
			(*raise (Failure(L.string_of_llvalue pointer_to_struct_field))*)
			L.build_store e2' pointer_to_struct_field builder; e2' 

 )





      | A.Assign (s, e) -> let e' = expr builder e in
	                   ignore (L.build_store e' (lookup s) builder); e'
      | A.Call ("print_int", [e]) | A.Call ("printb", [e]) ->
	  L.build_call printf_func [| int_format_str ; (expr builder e) |]
	    "printf" builder
      | A.Call ("print", [e])->
                L.build_call printf_func [| (expr builder e) |] "printf" builder
      | A.Call (f, act) ->
         let (fdef, fdecl) = StringMap.find f function_decls in
	 let actuals = List.rev (List.map (expr builder) (List.rev act)) in
	 let result = (match fdecl.A.typ with A.Void -> ""
                                            | _ -> f ^ "_result") in
         L.build_call fdef (Array.of_list actuals) result builder
    in

    (* Invoke "f builder" if the current block doesn't already
       have a terminal (e.g., a branch). *)
    let add_terminal builder f =
      match L.block_terminator (L.insertion_block builder) with
	Some _ -> ()
      | None -> ignore (f builder) in
	
    (* Build the code for the given statement; return the builder for
       the statement's successor *)
    let rec stmt builder = function
	A.Block sl -> List.fold_left stmt builder sl
      | A.Expr e -> ignore (expr builder e); builder
      | A.Return e -> ignore (match fdecl.A.typ with
	  A.Void -> L.build_ret_void builder
	| _ -> L.build_ret (expr builder e) builder); builder
      | A.If (predicate, then_stmt, else_stmt) ->
         let bool_val = expr builder predicate in
	 let merge_bb = L.append_block context "merge" the_function in

	 let then_bb = L.append_block context "then" the_function in
	 add_terminal (stmt (L.builder_at_end context then_bb) then_stmt)
	   (L.build_br merge_bb);

	 let else_bb = L.append_block context "else" the_function in
	 add_terminal (stmt (L.builder_at_end context else_bb) else_stmt)
	   (L.build_br merge_bb);

	 ignore (L.build_cond_br bool_val then_bb else_bb builder);
	 L.builder_at_end context merge_bb

      | A.While (predicate, body) ->
	  let pred_bb = L.append_block context "while" the_function in
	  ignore (L.build_br pred_bb builder);

	  let body_bb = L.append_block context "while_body" the_function in
	  add_terminal (stmt (L.builder_at_end context body_bb) body)
	    (L.build_br pred_bb);

	  let pred_builder = L.builder_at_end context pred_bb in
	  let bool_val = expr pred_builder predicate in

	  let merge_bb = L.append_block context "merge" the_function in
	  ignore (L.build_cond_br bool_val body_bb merge_bb pred_builder);
	  L.builder_at_end context merge_bb

      | A.For (e1, e2, e3, body) -> stmt builder
	    ( A.Block [A.Expr e1 ; A.While (e2, A.Block [body ; A.Expr e3]) ] )
    in

    (* Build the code for each statement in the function *)
    let builder = stmt builder (A.Block fdecl.A.body) in

    (* Add a return if the last block falls off the end *)
    add_terminal builder (match fdecl.A.typ with
        A.Void -> L.build_ret_void
      | t -> L.build_ret (L.const_int (ltype_of_typ t) 0))
  in

  List.iter build_function_body functions;
  the_module
