module L = Llvm
module A = Ast
module StringMap = Map.Make(String)

let translate (globals, functions, structs) =
  let context = L.global_context () in
  let the_module = L.create_module context "Democritus"
  and i32_t  = L.i32_type  context
(*  and i8_t   = L.i8_type   context *)
  and i1_t   = L.i1_type   context
  and void_t = L.void_type context
  and ptr_t  = L.pointer_type (L.i8_type (context)) 
  and float_t = L.double_type context
  in
		

	let struct_types:(string, L.lltype) Hashtbl.t = Hashtbl.create 50 in

        let add_empty_named_struct_types sdecl =
		let struct_t = L.named_struct_type context sdecl.A.sname in
		Hashtbl.add struct_types sdecl.A.sname struct_t
	in
	let _  =
		List.map add_empty_named_struct_types structs 
	in

	let rec ltype_of_typ = function
		A.Int -> i32_t
	|       A.Float -> float_t
	| 	A.Bool -> i1_t
 	|	A.Void -> void_t
	| 	A.StructType s ->  Hashtbl.find struct_types s
	|	A.MyString -> ptr_t 
	| 	A.Voidstar -> ptr_t 
	|	A.PointerType t -> L.pointer_type (ltype_of_typ t) in 
	let populate_struct_type sdecl = 
		let struct_t = Hashtbl.find struct_types sdecl.A.sname in
		let type_list = Array.of_list(List.map (fun(t, _) -> ltype_of_typ t) sdecl.A.sformals) in
		L.struct_set_body struct_t type_list true
	in 
    ignore(List.map populate_struct_type structs);
  
  let string_option_to_string = function
	None -> ""
	| Some(s) -> s
  in
	
  (*struct_field_index is a map where key is struct name and value is another map*)
  (*in the second map, the key is the field name and the value is the index number*)
  let struct_field_index_list =
	let handle_list m individual_struct = 
		(*list of all field names for that struct*) 
		let struct_field_name_list = List.map snd individual_struct.A.sformals in
		let increment n = n + 1 in
		let add_field_and_index (m, i) field_name =
			(*add each field and index to the second map*)
			(StringMap.add field_name (increment i) m, increment i) in
		(*struct_field_map is the second map, with key = field name and value = index*)
		let struct_field_map = 
			List.fold_left add_field_and_index (StringMap.empty, -1) struct_field_name_list
		in
		(*add field map (the first part of the tuple) to the main map*)
		StringMap.add individual_struct.A.sname (fst struct_field_map) m	
	in
	List.fold_left handle_list StringMap.empty structs	
  in
    (* Declare each global variable; remember its value in a map *)
  let global_vars =
    let global_var m (t, n) =
      let init = L.const_int (ltype_of_typ t) 0
      in StringMap.add n (L.define_global n init the_module) m in
    List.fold_left global_var StringMap.empty globals in

  let append_strings_t = L.function_type void_t [| ptr_t; ptr_t |] in
  let append_strings_func = L.declare_function "append_strings" append_strings_t the_module in

  let int_to_string_t = L.function_type void_t [| i32_t; ptr_t |] in
  let int_to_string_func = L.declare_function "int_to_string" int_to_string_t the_module in

  (* Declare printf(), which the print built-in function will call *)
  let printf_t = L.var_arg_function_type i32_t [| ptr_t |] in
  let printf_func = L.declare_function "printf" printf_t the_module in

  let execl_t = L.var_arg_function_type i32_t [| ptr_t |] in
  let execl_func = L.declare_function "exec_prog" execl_t the_module in

  let free_t = L.function_type void_t [| ptr_t |] in
  let free_func = L.declare_function "free" free_t the_module in

  (* Declare malloc() *)
  let malloc_t = L.function_type ptr_t [| i32_t |] in
  let malloc_func = L.declare_function "malloc" malloc_t the_module in

  let request_from_server_t = L.function_type ptr_t [| ptr_t |] in
  let request_from_server_func = L.declare_function "request_from_server" request_from_server_t the_module in

  (* File I/O functions *)
  let open_t = L.function_type i32_t [| ptr_t; i32_t; i32_t |] in
  let open_func = L.declare_function "open" open_t the_module in

  let close_t = L.function_type i32_t [| i32_t |] in
  let close_func = L.declare_function "close" close_t the_module in

  let read_t = L.function_type i32_t [| i32_t; ptr_t; i32_t |] in
  let read_func = L.declare_function "read" read_t the_module in

  let write_t = L.function_type i32_t [| i32_t; ptr_t; i32_t |] in
  let write_func = L.declare_function "write" write_t the_module in 

  let lseek_t = L.function_type i32_t [| i32_t; i32_t; i32_t |] in
  let lseek_func = L.declare_function "lseek" lseek_t the_module in

  let sleep_t = L.function_type i32_t [| i32_t |] in
  let sleep_func = L.declare_function "sleep" sleep_t the_module in

  let default_t = L.function_type ptr_t [|ptr_t|] in
  let default_func = L.declare_function "default_start_routine" default_t the_module in

  let param_ty = L.function_type ptr_t [| ptr_t |] in (* a function that returns void_star and takes as argument void_star *)
let param_ptr = L.pointer_type param_ty in  
let thread_t = L.function_type void_t [| param_ptr; ptr_t; i32_t|] in (*a function that returns void and takes (above) and a voidstar and an int *)
  let thread_func = L.declare_function "init_thread" thread_t the_module in


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
    let float_format_str = L.build_global_stringptr "%f\n" "fmt" builder in   
 
    (* Construct the function's "locals": formal arguments and locally
       declared variables.  Allocate each on the stack, initialize their
       value, if appropriate, and remember their values in the "locals" map *)
    let local_vars =
      let add_formal m (t, n) p = L.set_value_name n p;
	let local = L.build_alloca (ltype_of_typ t) n builder in
	ignore (L.build_store p local builder);
	StringMap.add n local m in

      let add_local m (t, n) =
	let local_var = L.build_alloca (ltype_of_typ t) n builder
	in StringMap.add n local_var m in

      let formals = List.fold_left2 add_formal StringMap.empty fdecl.A.formals
          (Array.to_list (L.params the_function)) in
      List.fold_left add_local formals fdecl.A.locals in

    (* Return the value for a variable or formal argument *)
    let lookup n = try StringMap.find n local_vars
                 with Not_found -> try StringMap.find n global_vars
                 with Not_found -> raise (Failure ("undeclared variable " ^ n))
    in

    (* Construct code for an expression; return its value *)
    let rec llvalue_expr_getter builder = function
     	A.Id s -> lookup s
	|A.Dotop(e1, field) ->
		(match e1 with
			A.Id s -> let etype = fst( 
				try List.find (fun t->snd(t)=s) fdecl.A.locals
				with Not_found -> raise (Failure("Unable to find" ^ s ^ "in dotop")))
				in
				(try match etype with
					A.StructType t->
						let index_number_list = StringMap.find t struct_field_index_list in
						let index_number = StringMap.find field index_number_list in
						let struct_llvalue = lookup s in
						let access_llvalue = L.build_struct_gep struct_llvalue index_number "dotop_terminal" builder in
						access_llvalue

				| _ -> raise (Failure("No structype."))
			 with Not_found -> raise (Failure("unable to find" ^ s)) )
		| _ as e1_expr ->  let e1'_llvalue = llvalue_expr_getter builder e1_expr in
			let loaded_e1' = expr builder e1_expr in
			let e1'_lltype = L.type_of loaded_e1' in
			let e1'_struct_name_string_option = L.struct_name e1'_lltype in
			let e1'_struct_name_string = string_option_to_string e1'_struct_name_string_option in
			let index_number_list = StringMap.find e1'_struct_name_string struct_field_index_list in
			let index_number = StringMap.find field index_number_list in
			let access_llvalue = L.build_struct_gep e1'_llvalue index_number "gep_in_dotop" builder in
			access_llvalue )
	
	
	|A.Unop(op, e)  ->
		(match op with
			A.Deref ->
				let e_llvalue = (llvalue_expr_getter builder e) in
			        let e_loaded = L.build_load e_llvalue "loaded_deref" builder in 
				e_loaded
			|_ -> raise (Failure("nooo"))
		)
	|_ -> raise (Failure ("in llvalue_expr_getter but not a dotop!"))
    and
    expr builder = function
	A.Literal i -> L.const_int i32_t i
(*      | A.MyStringLit str -> L.const_stringz context str *)
      | A.FloatLiteral f -> L.const_float float_t f
      | A.MyStringLit str -> L.build_global_stringptr str "tmp" builder
      | A.BoolLit b -> L.const_int i1_t (if b then 1 else 0)
      | A.Noexpr -> L.const_int i32_t 0
      | A.Id s -> L.build_load (lookup s) s builder
      | A.Binop (e1, op, e2) ->
	  let e1' = expr builder e1
	  and e2' = expr builder e2 in
	  (match op with
	    A.Add     -> (let e1_type_string = L.string_of_lltype (L.type_of e1') in 
				(match e1_type_string with
					 "double" -> L.build_fadd 
		      			|"i32" -> L.build_add
					| _ -> raise(Failure("Can only add ints or floats")) ))
	   |A.Sub     -> (let e1_type_string = L.string_of_lltype (L.type_of e1') in 
				(match e1_type_string with
					 "double" -> L.build_fsub 
		      			|"i32" -> L.build_sub
					| _ -> raise(Failure("Can only subtract ints or floats")) ))
	   |A.Mult     -> (let e1_type_string = L.string_of_lltype (L.type_of e1') in 
				(match e1_type_string with
					 "double" -> L.build_fmul
		      			|"i32" -> L.build_mul 	
					| _ -> raise(Failure("Can only multiply ints or floats")) ))
	   |A.Div     -> (let e1_type_string = L.string_of_lltype (L.type_of e1') in 
				(match e1_type_string with
					 "double" -> L.build_fdiv 
		      			|"i32" -> L.build_sdiv
					| _ -> raise(Failure("Can only divide ints or floats")) ))
	  | A.Mod     -> L.build_srem
	  | A.And     -> L.build_and
	  | A.Or      -> L.build_or
	  | A.Equal   -> L.build_icmp L.Icmp.Eq
	  | A.Neq     -> L.build_icmp L.Icmp.Ne
	  | A.Less    -> L.build_icmp L.Icmp.Slt
	  | A.Leq     -> L.build_icmp L.Icmp.Sle
	  | A.Greater -> L.build_icmp L.Icmp.Sgt
	  | A.Geq     -> L.build_icmp L.Icmp.Sge
	  ) e1' e2' "tmp" builder
    | A.Dotop(e1, field) -> let _ = expr builder e1 in
	 (match e1 with
		A.Id s -> let etype = fst( 
			try List.find (fun t->snd(t)=s) fdecl.A.locals
			with Not_found -> raise (Failure("Unable to find" ^ s ^ "in dotop")))
			in
			(try match etype with
				A.StructType t->
					let index_number_list = StringMap.find t struct_field_index_list in
					let index_number = StringMap.find field index_number_list in
					let struct_llvalue = lookup s in
					let access_llvalue = L.build_struct_gep struct_llvalue index_number "dotop_terminal" builder in
					let loaded_access = L.build_load access_llvalue "loaded_dotop_terminal" builder in
					loaded_access

				| _ -> raise (Failure("No structype."))
			 with Not_found -> raise (Failure("unable to find" ^ s)) )
		| _ as e1_expr ->  let e1'_llvalue = llvalue_expr_getter builder e1_expr in
			let loaded_e1' = expr builder e1_expr in
			let e1'_lltype = L.type_of loaded_e1' in
			let e1'_struct_name_string_option = L.struct_name e1'_lltype in
			let e1'_struct_name_string = string_option_to_string e1'_struct_name_string_option in
			let index_number_list = StringMap.find e1'_struct_name_string struct_field_index_list in
			let index_number = StringMap.find field index_number_list in
			let access_llvalue = L.build_struct_gep e1'_llvalue index_number "gep_in_dotop" builder in
			L.build_load access_llvalue "loaded_dotop" builder )
      | A.Unop(op, e) ->
	  let e' = expr builder e in
	  (match op with
	    A.Neg     -> L.build_neg e' "tmp" builder
          | A.Not     -> L.build_not e' "temp" builder
	  | A.Deref -> let e_loaded = L.build_load e' "loaded_deref" builder in
			e_loaded
	  | A.Ref -> let e_llvalue = (llvalue_expr_getter builder e) in
		e_llvalue
	  )
      | A.Castop(ast_cast_type, e) ->
 		let cast_lltype = ltype_of_typ ast_cast_type in
	(*	let cast_lltype_string = L.string_of_lltype cast_lltype in *)
		let e_llvalue = expr builder e in
		L.build_pointercast e_llvalue cast_lltype "plz" builder
     (* | A.SAssign(e1, field, e2) -> let e2' = expr builder e2 in
	  (match e1 with
		A.Id s -> let e1typ = fst(
			try List.find (fun t -> snd(t) = s) fdecl.A.locals
			with Not_found -> raise(Failure("unable to find" ^ s ^ "in Sassign")))
			in
			(match e1typ with
				A.StructType t -> (try 
					let index_number_list = StringMap.find t struct_field_index_list in
					let index_number = StringMap.find field index_number_list in
					let struct_llvalue = lookup s in
					let access_llvalue = L.build_struct_gep struct_llvalue index_number field builder in
					(try (ignore(L.build_store e2' access_llvalue builder); e2')
						with Not_found -> raise (Failure("unable to store " ^ t )) )
					with Not_found -> raise (Failure("unable to find" ^ s)) )
				| _ -> raise (Failure("StructType not found.")))
		|_ as e1_expr -> let e1'_llvalue = llvalue_expr_getter builder e1_expr in 
			let loaded_e1' = expr builder e1_expr in
			let e1'_lltype = L.type_of loaded_e1' in
			let e1'_struct_name_string_option = L.struct_name e1'_lltype in
			let e1'_struct_name_string = string_option_to_string e1'_struct_name_string_option in
			let index_number_list = StringMap.find e1'_struct_name_string struct_field_index_list in
			let index_number = StringMap.find field index_number_list in
			let access_llvalue = L.build_struct_gep e1'_llvalue index_number "gep_in_Sassign" builder in
			let _ = L.build_store e2' access_llvalue builder in
			e2') 
	*)
      | A.Assign (lhs, e2) -> let e2' = expr builder e2 in
			(match lhs with
			A.Id s ->ignore (L.build_store e2' (lookup s) builder); e2'
			|A.Dotop (e1, field) ->
				(match e1 with 			
					
					A.Id s -> let e1typ = fst(
					try List.find (fun t -> snd(t) = s) fdecl.A.locals
					with Not_found -> raise(Failure("unable to find" ^ s ^ "in Sassign")))
					in
					(match e1typ with
						A.StructType t -> (try 
							let index_number_list = StringMap.find t struct_field_index_list in
							let index_number = StringMap.find field index_number_list in
							let struct_llvalue = lookup s in
							let access_llvalue = L.build_struct_gep struct_llvalue index_number field builder in
							(try (ignore(L.build_store e2' access_llvalue builder);e2')
								with Not_found -> raise (Failure("unable to store " ^ t )) )
							with Not_found -> raise (Failure("unable to find" ^ s)) )
						| _ -> raise (Failure("StructType not found.")))
				|_ as e1_expr -> let e1'_llvalue = llvalue_expr_getter builder e1_expr in 
					let loaded_e1' = expr builder e1_expr in
					let e1'_lltype = L.type_of loaded_e1' in
					let e1'_struct_name_string_option = L.struct_name e1'_lltype in
					let e1'_struct_name_string = string_option_to_string e1'_struct_name_string_option in
					let index_number_list = StringMap.find e1'_struct_name_string struct_field_index_list in
					let index_number = StringMap.find field index_number_list in
					let access_llvalue = L.build_struct_gep e1'_llvalue index_number "gep_in_Sassign" builder in
					let _ = L.build_store e2' access_llvalue builder in
					e2'
				)
			
			 |A.Unop(op, e)  ->
					(match op with
						A.Deref ->
							let e_llvalue = (llvalue_expr_getter builder e) in
						        let e_loaded = L.build_load e_llvalue "loaded_deref" builder in 
							let _ = L.build_store e2' e_loaded builder in
							e2'	
						|_ -> raise (Failure("nooo"))
					)
			 |_ -> raise (Failure("can't match in assign"))
			)
      | A.Call ("print_int", [e]) | A.Call ("printb", [e]) ->
	  L.build_call printf_func [| int_format_str ; (expr builder e) |]
	    "printf" builder
    | A.Call ("print_float", [e]) ->
	L.build_call printf_func [| float_format_str; (expr builder e) |] "printf" builder 

    | A.Call ("print", [e])->
        L.build_call printf_func [| (expr builder e) |] "printf" builder

    | A.Call ("append_strings", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call append_strings_func evald_expr_arr "" builder

    | A.Call ("int_to_string", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call int_to_string_func evald_expr_arr "" builder



    | A.Call ("exec_prog", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call execl_func evald_expr_arr "exec_prog" builder

    | A.Call("free", e) ->
	L.build_call free_func (Array.of_list (List.map (expr builder) e)) "" builder

    | A.Call ("malloc", e) ->
      	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call malloc_func evald_expr_arr "malloc" builder
(*
    | A.Call ("malloc_type", e) ->
	L.build_malloc e "malloc_type" builder
*)
  (* File I/O functions *)
    | A.Call("open", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call open_func evald_expr_arr "open" builder

    | A.Call("close", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
  	L.build_call close_func evald_expr_arr "close" builder

    | A.Call("read", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call read_func evald_expr_arr "read" builder

    | A.Call("write", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call write_func evald_expr_arr "write" builder

    | A.Call("lseek", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call lseek_func evald_expr_arr "lseek" builder

    | A.Call("sleep", e) ->
	let evald_expr_list = List.map (expr builder)e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call sleep_func evald_expr_arr "sleep" builder

    | A.Call ("thread", e)->
(*	L.build_call printf_func [| int_format_str ; L.const_int i32_t 8 |] "printf" builder	*)
	let evald_expr_list = List.map (expr builder)e in
(*	let target_func_strptr = List.hd evald_expr_list in  (* jsut get the string by doing List.hd on e *)
	let target_func_str = L.string_of_llvalue target_func_strptr in *)
	let get_string v = match v with
		| A.MyStringLit i -> i
		| _ -> "" in
	let target_func_str = get_string (List.hd e) in
	(*let target_func_str = Option.default "" Some(target_func_str_opt) in *)
	let target_func_llvalue_opt = L.lookup_function target_func_str the_module in
	let deopt x = match x with
		|Some f -> f
		| None -> default_func in
	let target_func_llvalue = deopt target_func_llvalue_opt in
	let remaining_list = List.tl evald_expr_list in
	let new_arg_list = target_func_llvalue :: remaining_list in
	let new_arg_arr = Array.of_list new_arg_list in
		L.build_call thread_func
		new_arg_arr	
                "" builder

    | A.Call ("request_from_server", e) ->
	let evald_expr_list = List.map (expr builder) e in
	let evald_expr_arr = Array.of_list evald_expr_list in
	L.build_call request_from_server_func evald_expr_arr "request_from_server" builder

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

  let llmem = Llvm.MemoryBuffer.of_file "bindings.bc" in
  let llm = Llvm_bitreader.parse_bitcode context llmem in
  ignore(Llvm_linker.link_modules the_module llm Llvm_linker.Mode.PreserveSource);

  the_module

