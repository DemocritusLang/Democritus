# Makefile for printing parse branch

make:
	ocamllex scanner.mll
	ocamlyacc parser.mly
	ocamlc -c ast.ml
	ocamlc -c parser.mli
	ocamlc -c scanner.ml
	ocamlc -c parser.ml
	ocamlc -c test.ml
	ocamlc -o test parser.cmo scanner.cmo test.cmo

clean:
	rm -f *cmo *cmi parser.mli parser.ml scanner.ml ./test *output

