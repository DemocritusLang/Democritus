open Llvm

open Llvm.MemoryBuffer
open Llvm_bitreader
open Llvm_bitwriter

let context = global_context () 
let the_module = create_module context "MicroC"
let builder = builder context

let i32_t = i32_type context;;
let i8_t = i8_type context;;
let f_t = double_type context;;
let i1_t = i1_type context;;
let str_t = pointer_type i8_t;;
let i64_t = i64_type context;;
let void_t = void_type context;;
let void_star = pointer_type i8_t;;
	
	let printf_ty = var_arg_function_type i32_t  [| void_star |] in
	let printf_llvalue = declare_function "printf" printf_ty the_module in

(* void pointers *)
	let param_ty = function_type void_star [| void_star |] in
	let param_ptr = pointer_type param_ty in 
	let thread_ty = function_type void_t [| param_ptr; i32_t; i32_t |] in
	let thread_func = declare_function "init_thread" thread_ty the_module in
(* define is same as C++ define- header syntax: declare , define: actually put body of fn in *)
	let sayhello_ty = function_type void_star [|void_star|] in
	let sayhello_func = define_function "sayhello" sayhello_ty the_module in
	let sayhello_builder = builder_at_end context (entry_block sayhello_func) in
(*	let string_llvalue = const_string context "hello" in *)
	let string_llvalue = build_global_stringptr "hello" "" sayhello_builder in
	let zero = const_int i32_t 0 in
	let string_ptr = build_in_bounds_gep string_llvalue [| zero |] "" builder in
(*	let string_llvalue = build_global_stringptr "hello" "tmp" sayhello_builder in *)
(*	let sptr = build_alloca void_star "tmp" builder in*)
(*	let string_llvalue = build_store string_llvalue sptr builder in*)
	let sayhello_llvalue = build_call printf_llvalue [|string_ptr|] "" sayhello_builder in
	let sayhello_ret = build_ret (const_pointer_null void_star) sayhello_builder in
(*	and codegen_func_call fname el d llbuilder = 
	let f = func_lookup fname in
	let params = List.map (codegen_sexpr llbuilder) el in
	match d with
		Datatype(Void_t) -> build_call f (Array.of_list params) "" llbuilder
| _ -> build_call f (Array.of_list params) "tmp" llbuilder
in*)
	let fty = function_type i32_t [||] in   (* define a main() that takes no args *)
	let f = define_function "main" fty the_module in     
	let llbuilder = builder_at_end context (entry_block f) in (* get the instr builder for main *)

	let main_llvalue = build_call thread_func [|sayhello_func; const_int i32_t 0; const_int i32_t 8|] "" llbuilder 
	in let main_ret = build_ret (const_int i32_t 0) llbuilder 

(*let main_llvalue = build_call sayhello_llvalue [| undef void_star |] "main" llbuilder *)
(*	let string_llvalue = build_global_stringptr "hello" "tmp" llbuilder  in 
	let main_llvalue = build_call printf_llvalue [| string_llvalue |] "result" llbuilder  *)
in	


 let linker filename = 
	let llctx = Llvm.global_context () in
	let llmem = Llvm.MemoryBuffer.of_file filename in
	let llm = Llvm_bitreader.parse_bitcode llctx llmem in
	ignore (Llvm_linker.link_modules the_module llm Llvm_linker.Mode.PreserveSource)
in
let codegen_sprogram ()= 
	let _ = linker "bindings.bc" in
	(*Llvm_bitwriter.write_bitcode_file the_module "the_module.ll"*) 
	print_module "themodule.ll" the_module 
(*	print_string (string_of_llmodule the_module)*)
in
codegen_sprogram ()

(*TODO hardcode main(), init_thread(), and sayhello() and then call them together. No AST, no scanner, no parser *)


(* so like in main() you'll  put build_call for init_thread, and in sayhello you'll put build_call for printf *)
