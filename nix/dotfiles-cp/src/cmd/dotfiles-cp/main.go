package main

import (
	"bytes"
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

type actionKind string

const (
	actionCopy     actionKind = "copy"
	actionMkdir    actionKind = "mkdir"
	actionKeep     actionKind = "keep"
	actionConflict actionKind = "conflict"
	actionRemove   actionKind = "remove"
)

type action struct {
	kind   actionKind
	path   string
	target string
	reason string
}

type options struct {
	command string
	src     string
	dest    string
	dryRun  bool
}

const usageText = `Usage:
  dotfiles-cp apply --src <src> --dest <dest> [--dry-run]
  dotfiles-cp unapply --src <src> --dest <dest> [--dry-run]
`

func main() {
	code, err := run(os.Args)
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: %v\n", err)
	}
	os.Exit(code)
}

func run(args []string) (int, error) {
	opts, code, err := parseArgs(args)
	if err != nil || code != -1 {
		return code, err
	}

	actions, err := buildPlan(opts)
	if err != nil {
		return 2, err
	}

	printActions(actions)
	if hasConflict(actions) {
		return 1, nil
	}
	if opts.dryRun {
		return 0, nil
	}
	if err := applyActions(actions); err != nil {
		return 1, err
	}
	return 0, nil
}

func parseArgs(args []string) (options, int, error) {
	if len(args) < 2 {
		fmt.Fprint(os.Stdout, usageText)
		return options{}, 0, nil
	}

	command := args[1]
	switch command {
	case "-h", "--help", "help":
		fmt.Fprint(os.Stdout, usageText)
		return options{}, 0, nil
	case "apply", "unapply":
	default:
		fmt.Fprint(os.Stderr, usageText)
		return options{}, 2, fmt.Errorf("unknown command: %s", command)
	}

	flags := flag.NewFlagSet("dotfiles-cp "+command, flag.ContinueOnError)
	flags.SetOutput(os.Stderr)
	src := flags.String("src", "", "source tree")
	dest := flags.String("dest", "", "destination tree")
	dryRun := flags.Bool("dry-run", false, "show planned operations without changing the filesystem")
	if err := flags.Parse(args[2:]); err != nil {
		return options{}, 2, err
	}
	if flags.NArg() != 0 {
		return options{}, 2, fmt.Errorf("unexpected argument: %s", flags.Arg(0))
	}
	if *src == "" {
		return options{}, 2, errors.New("--src is required")
	}
	if *dest == "" {
		return options{}, 2, errors.New("--dest is required")
	}

	absSrc, err := absClean(*src)
	if err != nil {
		return options{}, 2, fmt.Errorf("invalid --src: %w", err)
	}
	absDest, err := absClean(*dest)
	if err != nil {
		return options{}, 2, fmt.Errorf("invalid --dest: %w", err)
	}

	return options{
		command: command,
		src:     absSrc,
		dest:    absDest,
		dryRun:  *dryRun,
	}, -1, nil
}

func absClean(path string) (string, error) {
	abs, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	return filepath.Clean(abs), nil
}

func buildPlan(opts options) ([]action, error) {
	info, err := os.Lstat(opts.src)
	if err != nil {
		return nil, fmt.Errorf("src not found: %s", opts.src)
	}
	if !info.IsDir() {
		return nil, fmt.Errorf("src must be a directory: %s", opts.src)
	}

	switch opts.command {
	case "apply":
		return planApply(opts)
	case "unapply":
		return planUnapply(opts)
	default:
		return nil, fmt.Errorf("unknown command: %s", opts.command)
	}
}

func planApply(opts options) ([]action, error) {
	var actions []action
	err := filepath.WalkDir(opts.src, func(srcPath string, entry fs.DirEntry, err error) error {
		if err != nil {
			actions = append(actions, action{kind: actionConflict, path: srcPath, reason: err.Error()})
			return nil
		}
		if srcPath == opts.src {
			return nil
		}

		rel, err := filepath.Rel(opts.src, srcPath)
		if err != nil {
			return err
		}
		destPath := filepath.Join(opts.dest, rel)
		if entry.IsDir() {
			actions = append(actions, planDestDir(destPath))
			return nil
		}

		actions = append(actions, planCopy(srcPath, destPath))
		return nil
	})
	return actions, err
}

func planDestDir(destPath string) action {
	info, err := os.Lstat(destPath)
	if err != nil {
		if os.IsNotExist(err) {
			return action{kind: actionMkdir, path: destPath}
		}
		return action{kind: actionConflict, path: destPath, reason: err.Error()}
	}
	if info.IsDir() && info.Mode()&os.ModeSymlink == 0 {
		return action{kind: actionKeep, path: destPath}
	}
	return action{kind: actionConflict, path: destPath, reason: "exists and is not a directory"}
}

func planCopy(srcPath, destPath string) action {
	srcData, err := os.ReadFile(srcPath)
	if err != nil {
		return action{kind: actionConflict, path: destPath, target: srcPath, reason: err.Error()}
	}

	info, err := os.Lstat(destPath)
	if err != nil {
		if os.IsNotExist(err) {
			return action{kind: actionCopy, path: destPath, target: srcPath}
		}
		return action{kind: actionConflict, path: destPath, target: srcPath, reason: err.Error()}
	}
	if !info.Mode().IsRegular() {
		return action{kind: actionConflict, path: destPath, target: srcPath, reason: "exists and is not a regular file"}
	}
	destData, err := os.ReadFile(destPath)
	if err != nil {
		return action{kind: actionConflict, path: destPath, target: srcPath, reason: err.Error()}
	}
	if bytes.Equal(srcData, destData) {
		return action{kind: actionKeep, path: destPath, target: srcPath}
	}
	return action{kind: actionConflict, path: destPath, target: srcPath, reason: "existing file differs from source"}
}

func planUnapply(opts options) ([]action, error) {
	var actions []action
	err := filepath.WalkDir(opts.src, func(srcPath string, entry fs.DirEntry, err error) error {
		if err != nil {
			actions = append(actions, action{kind: actionConflict, path: srcPath, reason: err.Error()})
			return nil
		}
		if srcPath == opts.src || entry.IsDir() {
			return nil
		}

		rel, err := filepath.Rel(opts.src, srcPath)
		if err != nil {
			return err
		}
		destPath := filepath.Join(opts.dest, rel)
		action := planRemove(srcPath, destPath)
		if action != nil {
			actions = append(actions, *action)
		}
		return nil
	})
	return actions, err
}

func planRemove(srcPath, destPath string) *action {
	info, err := os.Lstat(destPath)
	if err != nil {
		if os.IsNotExist(err) {
			return nil
		}
		return &action{kind: actionConflict, path: destPath, target: srcPath, reason: err.Error()}
	}
	if !info.Mode().IsRegular() {
		return &action{kind: actionConflict, path: destPath, target: srcPath, reason: "destination is not a regular file"}
	}
	srcData, err := os.ReadFile(srcPath)
	if err != nil {
		return &action{kind: actionConflict, path: destPath, target: srcPath, reason: err.Error()}
	}
	destData, err := os.ReadFile(destPath)
	if err != nil {
		return &action{kind: actionConflict, path: destPath, target: srcPath, reason: err.Error()}
	}
	if !bytes.Equal(srcData, destData) {
		return &action{kind: actionConflict, path: destPath, target: srcPath, reason: "destination differs from source"}
	}
	return &action{kind: actionRemove, path: destPath, target: srcPath}
}

func printActions(actions []action) {
	for _, action := range actions {
		switch action.kind {
		case actionCopy, actionKeep:
			fmt.Printf("%-9s %s <- %s\n", action.kind, action.path, action.target)
		case actionConflict:
			fmt.Printf("%-9s %s %s\n", action.kind, action.path, action.reason)
		default:
			fmt.Printf("%-9s %s\n", action.kind, action.path)
		}
	}
}

func hasConflict(actions []action) bool {
	for _, action := range actions {
		if action.kind == actionConflict {
			return true
		}
	}
	return false
}

func applyActions(actions []action) error {
	for _, action := range actions {
		switch action.kind {
		case actionMkdir:
			if err := os.MkdirAll(action.path, 0o755); err != nil {
				return err
			}
		case actionCopy:
			if err := copyFile(action.target, action.path); err != nil {
				return err
			}
		case actionRemove:
			if err := os.Remove(action.path); err != nil && !os.IsNotExist(err) {
				return err
			}
		}
	}
	return nil
}

func copyFile(srcPath, destPath string) error {
	data, err := os.ReadFile(srcPath)
	if err != nil {
		return err
	}
	info, err := os.Stat(srcPath)
	if err != nil {
		return err
	}
	if err := os.MkdirAll(filepath.Dir(destPath), 0o755); err != nil {
		return err
	}
	file, err := os.OpenFile(destPath, os.O_WRONLY|os.O_CREATE|os.O_EXCL, info.Mode().Perm())
	if err != nil {
		return err
	}
	completed := false
	defer func() {
		if !completed {
			os.Remove(destPath)
		}
	}()
	if _, err := file.Write(data); err != nil {
		file.Close()
		return err
	}
	if err := file.Close(); err != nil {
		return err
	}
	completed = true
	return nil
}
