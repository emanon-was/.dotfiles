package main

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestParseArgs(t *testing.T) {
	t.Parallel()

	opts, code, err := parseArgs([]string{"dotfiles-cp", "apply", "--src", ".", "--dest", "/tmp", "--dry-run"})
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

	_, code, err := parseArgs([]string{"dotfiles-cp", "apply", "--dest", "/tmp"})
	if err == nil {
		t.Fatal("parseArgs should reject missing --src")
	}
	if code != 2 {
		t.Fatalf("parseArgs code: got %d want 2", code)
	}
}

func TestPlanApplyCreatesDirectoriesAndCopiesFiles(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, ".config", "app", "config"), "config\n", 0o600)
	writeFile(t, filepath.Join(src, ".profile"), "profile\n", 0o644)

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{
		actionMkdir,
		actionMkdir,
		actionCopy,
		actionCopy,
	})

	if err := applyActions(actions); err != nil {
		t.Fatalf("applyActions returned error: %v", err)
	}
	assertFile(t, filepath.Join(dest, ".profile"), "profile\n", 0o644)
	assertFile(t, filepath.Join(dest, ".config", "app", "config"), "config\n", 0o600)
}

func TestPlanApplyKeepsIdenticalFile(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, ".profile"), "same\n", 0o644)
	writeFile(t, filepath.Join(dest, ".profile"), "same\n", 0o600)

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionKeep})
}

func TestPlanApplyConflictsWithDifferentFile(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, ".profile"), "managed\n", 0o644)
	writeFile(t, filepath.Join(dest, ".profile"), "changed\n", 0o644)

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionConflict})
}

func TestPlanApplyConflictsWithSymlink(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	srcFile := filepath.Join(src, ".profile")
	writeFile(t, srcFile, "managed\n", 0o644)
	mkdirAll(t, dest)
	if err := os.Symlink(srcFile, filepath.Join(dest, ".profile")); err != nil {
		t.Fatalf("symlink: %v", err)
	}

	actions, err := buildPlan(options{command: "apply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionConflict})
}

func TestPlanUnapplyRemovesOnlyUnchangedCopies(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, "unchanged"), "same\n", 0o644)
	writeFile(t, filepath.Join(src, "missing"), "absent\n", 0o644)
	writeFile(t, filepath.Join(dest, "unchanged"), "same\n", 0o644)

	actions, err := buildPlan(options{command: "unapply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionRemove})

	if err := applyActions(actions); err != nil {
		t.Fatalf("applyActions returned error: %v", err)
	}
	if _, err := os.Lstat(filepath.Join(dest, "unchanged")); !os.IsNotExist(err) {
		t.Fatalf("unchanged copy should be removed, err=%v", err)
	}
}

func TestPlanUnapplyConflictsWithModifiedCopy(t *testing.T) {
	t.Parallel()

	root := t.TempDir()
	src := filepath.Join(root, "src")
	dest := filepath.Join(root, "dest")
	writeFile(t, filepath.Join(src, "file"), "managed\n", 0o644)
	writeFile(t, filepath.Join(dest, "file"), "modified\n", 0o644)

	actions, err := buildPlan(options{command: "unapply", src: src, dest: dest})
	if err != nil {
		t.Fatalf("buildPlan returned error: %v", err)
	}
	assertActionKinds(t, actions, []actionKind{actionConflict})
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

func assertFile(t *testing.T, path, wantBody string, wantMode os.FileMode) {
	t.Helper()
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatalf("read %s: %v", path, err)
	}
	if string(data) != wantBody {
		t.Fatalf("file body mismatch for %s: got %q want %q", path, data, wantBody)
	}
	info, err := os.Stat(path)
	if err != nil {
		t.Fatalf("stat %s: %v", path, err)
	}
	if info.Mode().Perm() != wantMode {
		t.Fatalf("file mode mismatch for %s: got %o want %o", path, info.Mode().Perm(), wantMode)
	}
}

func mkdirAll(t *testing.T, path string) {
	t.Helper()
	if err := os.MkdirAll(path, 0o755); err != nil {
		t.Fatalf("mkdir %s: %v", path, err)
	}
}

func writeFile(t *testing.T, path, body string, mode os.FileMode) {
	t.Helper()
	mkdirAll(t, filepath.Dir(path))
	if err := os.WriteFile(path, []byte(body), mode); err != nil {
		t.Fatalf("write %s: %v", path, err)
	}
}
