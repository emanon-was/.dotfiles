.PHONY: flake-develop flake-check flake-lock flake-update direnv-allow

# 開発用 shell に入る。
flake-develop:
	nix develop

# flake の評価と定義済み checks を確認する。
flake-check:
	nix flake check

# 現在の input 解決結果で flake.lock を作成または更新する。
flake-lock:
	nix flake lock

# flake inputs を最新版へ更新する。
flake-update:
	nix flake update

# direnv にこのディレクトリの .envrc 実行を許可する。
direnv-allow:
	direnv allow
