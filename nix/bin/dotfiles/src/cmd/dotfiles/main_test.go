package main

import (
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
)

func TestFindSubcommandPrefersSiblingOverPath(t *testing.T) {
	root := t.TempDir()
	siblingBin := filepath.Join(root, "sibling-bin")
	pathBin := filepath.Join(root, "path-bin")
	mkdirAll(t, siblingBin)
	mkdirAll(t, pathBin)
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles"), "")
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-sample"), "")
	writeExecutable(t, filepath.Join(pathBin, "dotfiles-sample"), "")
	t.Setenv("PATH", pathBin)

	got, err := findSubcommand("dotfiles-sample", filepath.Join(siblingBin, "dotfiles"))
	if err != nil {
		t.Fatalf("findSubcommand returned error: %v", err)
	}
	want := filepath.Join(siblingBin, "dotfiles-sample")
	if got != want {
		t.Fatalf("findSubcommand should prefer sibling command: got %q want %q", got, want)
	}
}

func TestFindSubcommandFallsBackToPath(t *testing.T) {
	root := t.TempDir()
	siblingBin := filepath.Join(root, "sibling-bin")
	pathBin := filepath.Join(root, "path-bin")
	mkdirAll(t, siblingBin)
	mkdirAll(t, pathBin)
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles"), "")
	writeExecutable(t, filepath.Join(pathBin, "dotfiles-sample"), "")
	t.Setenv("PATH", pathBin)

	got, err := findSubcommand("dotfiles-sample", filepath.Join(siblingBin, "dotfiles"))
	if err != nil {
		t.Fatalf("findSubcommand returned error: %v", err)
	}
	want := filepath.Join(pathBin, "dotfiles-sample")
	if got != want {
		t.Fatalf("findSubcommand should fall back to PATH: got %q want %q", got, want)
	}
}

func TestListSubcommands(t *testing.T) {
	root := t.TempDir()
	siblingBin := filepath.Join(root, "sibling-bin")
	pathBin := filepath.Join(root, "path-bin")
	mkdirAll(t, siblingBin)
	mkdirAll(t, pathBin)
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles"), "")
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-sample"), "")
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-configure"), "")
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-configure-nested"), "")
	writeExecutable(t, filepath.Join(pathBin, "dotfiles-path-only"), "")
	t.Setenv("PATH", pathBin)

	got := listSubcommands(filepath.Join(siblingBin, "dotfiles"))
	want := []string{"configure", "path-only", "sample"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("listSubcommands mismatch: got %#v want %#v", got, want)
	}
}

func TestDotfilesEnvProfileRoot(t *testing.T) {
	root := t.TempDir()
	profile := filepath.Join(root, "profile")
	binDir := filepath.Join(profile, ".local", "bin")
	mkdirAll(t, binDir)
	mkdirAll(t, filepath.Join(profile, ".local", "share", "dotfiles"))
	invoked := filepath.Join(binDir, "dotfiles")
	writeExecutable(t, invoked, "")
	t.Setenv("PATH", "")
	t.Setenv("DOTFILES_HOME", "")

	env, err := dotfilesEnv([]string{"PATH="}, invoked)
	if err != nil {
		t.Fatalf("dotfilesEnv returned error: %v", err)
	}
	assertEnv(t, env, "DOTFILES_HOME", profile)
}

func TestDotfilesEnvRepositoryRoot(t *testing.T) {
	root := t.TempDir()
	repo := filepath.Join(root, "repo")
	binDir := filepath.Join(repo, "bin")
	mkdirAll(t, binDir)
	mkdirAll(t, filepath.Join(repo, "nix"))
	writeFile(t, filepath.Join(repo, "flake.nix"), "")
	invoked := filepath.Join(binDir, "dotfiles")
	writeExecutable(t, invoked, "")
	t.Setenv("PATH", "")
	t.Setenv("DOTFILES_HOME", "")

	env, err := dotfilesEnv([]string{"PATH="}, invoked)
	if err != nil {
		t.Fatalf("dotfilesEnv returned error: %v", err)
	}
	assertEnv(t, env, "DOTFILES_HOME", repo)
}

func TestDotfilesEnvRejectsInvalidExplicitHome(t *testing.T) {
	invalid := t.TempDir()
	t.Setenv("DOTFILES_HOME", invalid)

	_, err := dotfilesEnv(nil, "dotfiles")
	if err == nil {
		t.Fatal("dotfilesEnv should reject invalid DOTFILES_HOME")
	}
	if !strings.Contains(err.Error(), "not a dotfiles repository or profile root") {
		t.Fatalf("unexpected error: %v", err)
	}
}

func mkdirAll(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", path, err)
	}
}

func writeExecutable(t *testing.T, path string, body string) {
	t.Helper()
	if body == "" {
		body = "#!/bin/sh\nexit 0\n"
	}
	writeFile(t, path, body)
	if err := os.Chmod(path, 0o755); err != nil {
		t.Fatalf("chmod %s: %v", path, err)
	}
}

func writeFile(t *testing.T, path string, body string) {
	t.Helper()
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}

func assertEnv(t *testing.T, env []string, key string, want string) {
	t.Helper()
	prefix := key + "="
	for _, entry := range env {
		if strings.HasPrefix(entry, prefix) {
			if got := strings.TrimPrefix(entry, prefix); got != want {
				t.Fatalf("%s mismatch: got %q want %q", key, got, want)
			}
			return
		}
	}
	t.Fatalf("%s was not set in environment", key)
}
