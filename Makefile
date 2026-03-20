fmt:
	nix fmt

lint:
	statix check .
	deadnix .

check:
	nix flake check

update:
	nix flake update;
