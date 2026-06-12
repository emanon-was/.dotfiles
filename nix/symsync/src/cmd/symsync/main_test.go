package main

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestParseArgs(t *testing.T) {
	t.Parallel()

	opts, code, err := parseArgs([]string{"symsync", "apply", "--src", ".", "--dest", "/tmp", "--dry-run"})
	if err != nil {
		t.Fatalf("parseArgs returned error: %v", err)
	}
	if code != -1 {
		t.Fatalf("parseArgs code: got %d want -1", code)
	}
	if opts.command != "apply" || opts.src == "" || opts.dest != "/tmp" || !opts.dryRun {
		t.Fatalf("unexpected options: %#v", opts)
	}
}

func TestParseArgsRejectsMissingSrc(t *testing.T) {
	t.Parallel()

	_, code, err := parseArgs([]string{"symsync", "apply", "--dest", "/tmp"})
	if err == nil {
		t.Fatal("parseArgs should reject missing --src")
	}
	if code != 2 {
		t.Fatalf("parseArgs code: got %d want 2", code)
	}
}

func TestPlanApplyCreatesDirectoriesAndLinks(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, ".config", "app", "config"), "config\n")
	writeFile(t, filepath.Join(src, ".zshrc"), "zsh\n")

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}

	assertActionKinds(t, actions, []actionKind{
		actionMkdir,
		actionMkdir,
		actionLink,
		actionLink,
	})

	if err := applyActions(actions); err != nil {
		t.Fatalf("applyActions returned error: %v", err)
	}
	assertSymlink(t, filepath.Join(dest, ".zshrc"), filepath.Join(src, ".zshrc"))
	assertSymlink(t, filepath.Join(dest, ".config", "app", "config"), filepath.Join(src, ".config", "app", "config"))
}

func TestPlanApplyConflictsWithExistingFile(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, ".bashrc"), "managed\n")
	writeFile(t, filepath.Join(dest, ".bashrc"), "existing\n")

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	if !hasConflict(actions) {
		t.Fatalf("expected conflict action, got %#v", actions)
	}
}

func TestPlanApplyKeepsManagedSymlink(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	srcFile := filepath.Join(src, ".profile")
	destFile := filepath.Join(dest, ".profile")
	writeFile(t, srcFile, "profile\n")
	mkdirAll(t, dest)
	if err := os.Symlink(srcFile, destFile); err != nil {
		t.Fatalf("symlink: %v", err)
	}

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionKeep})
}

func TestPlanUnapplyRemovesOnlyManagedSymlinks(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	managedSrc := filepath.Join(src, ".zshrc")
	unrelatedTarget := filepath.Join(root, "other", ".profile")
	writeFile(t, managedSrc, "zsh\n")
	writeFile(t, filepath.Join(src, ".bashrc"), "bash\n")
	writeFile(t, unrelatedTarget, "other\n")
	mkdirAll(t, dest)
	if err := os.Symlink(managedSrc, filepath.Join(dest, ".zshrc")); err != nil {
		t.Fatalf("managed symlink: %v", err)
	}
	if err := os.Symlink(unrelatedTarget, filepath.Join(dest, ".bashrc")); err != nil {
		t.Fatalf("unrelated symlink: %v", err)
	}
	writeFile(t, filepath.Join(dest, "manual"), "manual\n")

	actions, err := buildPlan(options{command: "unapply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionUnlink})

	if err := applyActions(actions); err != nil {
		t.Fatalf("applyActions returned error: %v", err)
	}
	if _, err := os.Lstat(filepath.Join(dest, ".zshrc")); !os.IsNotExist(err) {
		t.Fatalf("managed symlink should be removed, err=%v", err)
	}
	assertSymlink(t, filepath.Join(dest, ".bashrc"), unrelatedTarget)
	if _, err := os.Stat(filepath.Join(dest, "manual")); err != nil {
		t.Fatalf("manual file should remain: %v", err)
	}
}

func TestShouldUnlinkRelativeSymlink(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, "file"), "file\n")
	mkdirAll(t, dest)
	if err := os.Symlink("../src/file", filepath.Join(dest, "file")); err != nil {
		t.Fatalf("relative symlink: %v", err)
	}

	if !shouldUnlink(filepath.Join(dest, "file"), src) {
		t.Fatal("relative symlink into src should be unlinked")
	}
}

func assertActionKinds(t *testing.T, actions []action, want []actionKind) {
	t.Helper()
	got := make([]actionKind, 0, len(actions))
	for _, action := range actions {
		got = append(got, action.kind)
	}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("action kinds mismatch: got %#v want %#v; actions=%#v", got, want, actions)
	}
}

func assertSymlink(t *testing.T, path string, want string) {
	t.Helper()
	got, err := os.Readlink(path)
	if err != nil {
		t.Fatalf("readlink %s: %v", path, err)
	}
	if got != want {
		t.Fatalf("symlink target mismatch for %s: got %q want %q", path, got, want)
	}
}

func mkdirAll(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", path, err)
	}
}

func writeFile(t *testing.T, path string, body string) {
	t.Helper()
	mkdirAll(t, filepath.Dir(path))
	if err := os.WriteFile(path, []byte(body), 0o644); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}
