# Democritus
Programming Language Project for PLT Spring 2016

Starting point is Stephen Edwards' (Columbia University) MicroC compiler.

Installation for Linux (Working on 15.04):

First, install all the required packages:

```
sudo apt-get install m4 clang-3.7 clang-3.7-doc libclang-common-3.7-dev libclang-3.7-dev libclang1-3.7 libclang1-3.7-dbg libllvm-3.7-ocaml-dev libllvm3.7 libllvm3.7-dbg lldb-3.7 llvm-3.7 llvm-3.7-dev llvm-3.7-doc llvm-3.7-examples llvm-3.7-runtime clang-modernize-3.7 clang-format-3.7 python-clang-3.7 lldb-3.7-dev liblldb-3.7-dbg opam llvm-runtime
```

Next, install and set up opam:

* For Ubuntu 15.04, we need the matching version of the LLVM 3.6 Ocaml Library

```
sudo apt-get install -y ocaml m4 llvm opam
opam init
opam install llvm.3.6 ocamlfind
eval `opam config env`
```

* For Ubuntu 14.04:

```
sudo apt-get install m4 llvm software-properties-common

sudo add-apt-repository --yes ppa:avsm/ppa
sudo apt-get update -qq
sudo apt-get install -y opam
opam init

eval `opam config env`

opam install llvm.3.4 ocamlfind
```

