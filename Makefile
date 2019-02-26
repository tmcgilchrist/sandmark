.SECONDARY:
export OPAMROOT=$(CURDIR)/_opam

PACKAGES = \
  cpdf menhir minilight camlimages yojson  \
  lwt ctypes orun cil frama-c alt-ergo \
  js_of_ocaml-compiler uuidm react ocplib-endian nbcodec

ITER = 5

.PHONY: bash list clean

ocamls=$(wildcard ocaml-versions/*.comp)

_opam/opam-init/init.sh:
	opam init --bare --no-setup --no-opamrc ./dependencies

_opam/%: _opam/opam-init/init.sh ocaml-versions/%.comp
	rm -rf dependencies/packages/ocaml/ocaml.$*
	rm -rf dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	mkdir -p dependencies/packages/ocaml/ocaml.$*
	cp -R dependencies/template/ocaml/* dependencies/packages/ocaml/ocaml.$*/
	mkdir -p dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*
	cp -R dependencies/template/ocaml-base-compiler/* \
	  dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/
	{ url="$$(cat ocaml-versions/$*.comp)"; echo "url { src: \"$$url\" }"; echo "setenv: [ [ ORUN_CONFIG_ocaml_url = \"$$url\" ] ]"; } \
	  >> dependencies/packages/ocaml-base-compiler/ocaml-base-compiler.$*/opam
	opam update
	opam switch create $* ocaml-base-compiler.$*
	opam pin add -n --yes --switch $* orun orun/

.PHONY: .FORCE
.FORCE:
ocaml-versions/%.bench: ocaml-versions/%.comp _opam/% .FORCE
	@opam update
	@opam install --switch=$* --best-effort --yes $(PACKAGES) || true
	@{ echo '(lang dune 1.0)'; \
	   for i in `seq 1 $(ITER)`; do \
	     echo "(context (opam (switch $*) (name $*_$$i)))"; \
           done } > ocaml-versions/.workspace.$*
	opam exec --switch $* -- dune build -j 1 --profile=release --workspace=ocaml-versions/.workspace.$* @bench; \
	  ex=$$?; find _build/$*_* -name '*.bench' | xargs cat > $@; exit $$ex


clean:
	rm -rf dependencies/packages/ocaml/*
	rm -rf dependencies/packages/ocaml-base-compiler/*
	rm -rf ocaml-versions/.packages.*
	rm -rf ocaml-versions/*.bench
	rm -rf _build
	rm -rf _opam


list:
	@echo $(ocamls)

bash:
	bash
	@echo "[opam subshell completed]"
