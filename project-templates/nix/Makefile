.PHONY: develop check lock update direnv-allow

# 開発用 shell に入る。
develop:
	nix develop

# flake の評価と定義済み checks を確認する。
check:
	nix flake check

# 現在の input 解決結果で flake.lock を作成または更新する。
lock:
	nix flake lock

# flake inputs を最新版へ更新する。
update:
	nix flake update

# direnv にこのディレクトリの .envrc 実行を許可する。
direnv-allow:
	direnv allow
