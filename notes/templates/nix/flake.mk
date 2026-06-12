.PHONY: flake-shell flake-lock flake-update direnv-allow

# 開発用 shell に入る。
flake-shell:
	nix develop

# 現在の input 解決結果で flake.lock を作成または更新する。
flake-lock:
	nix flake lock

# flake inputs を最新版へ更新する。
flake-update:
	nix flake update

# direnv にこのディレクトリの .envrc 実行を許可する。
direnv-allow:
	direnv allow
