package main

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestFindSubcommandPrefersSiblingOverPath(t *testing.T) {
	root := t.TempDir()
	siblingBin := filepath.Join(root, "sibling-bin")
	pathBin := filepath.Join(root, "path-bin")
	mkdirAll(t, siblingBin)
	mkdirAll(t, pathBin)
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-configure"), "")
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-configure-sample"), "")
	writeExecutable(t, filepath.Join(pathBin, "dotfiles-configure-sample"), "")
	t.Setenv("PATH", pathBin)

	got, err := findSubcommand("dotfiles-configure-sample", filepath.Join(siblingBin, "dotfiles-configure"))
	if err != nil {
		t.Fatalf("findSubcommand returned error: %v", err)
	}
	want := filepath.Join(siblingBin, "dotfiles-configure-sample")
	if got != want {
		t.Fatalf("findSubcommand should prefer sibling command: got %q want %q", got, want)
	}
}

func TestListSubcommands(t *testing.T) {
	root := t.TempDir()
	siblingBin := filepath.Join(root, "sibling-bin")
	pathBin := filepath.Join(root, "path-bin")
	mkdirAll(t, siblingBin)
	mkdirAll(t, pathBin)
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-configure"), "")
	writeExecutable(t, filepath.Join(siblingBin, "dotfiles-configure-alpha"), "")
	writeExecutable(t, filepath.Join(pathBin, "dotfiles-configure-beta"), "")
	t.Setenv("PATH", pathBin)

	got := listSubcommands(filepath.Join(siblingBin, "dotfiles-configure"))
	want := []string{"alpha", "beta"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("listSubcommands mismatch: got %#v want %#v", got, want)
	}
}

func TestUnknownCommandReturnsNotFound(t *testing.T) {
	root := t.TempDir()
	binDir := filepath.Join(root, "bin")
	mkdirAll(t, binDir)
	invoked := filepath.Join(binDir, "dotfiles-configure")
	writeExecutable(t, invoked, "")
	t.Setenv("PATH", "")

	if status := run([]string{invoked, "missing"}); status != 127 {
		t.Fatalf("unknown configure command status: got %d want 127", status)
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
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
	if err := os.Chmod(path, 0o755); err != nil {
		t.Fatalf("chmod %s: %v", path, err)
	}
}
