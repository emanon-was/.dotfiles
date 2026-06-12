package main

import (
	"errors"
	"flag"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

type actionKind string

const (
	actionLink     actionKind = "link"
	actionMkdir    actionKind = "mkdir"
	actionKeep     actionKind = "keep"
	actionConflict actionKind = "conflict"
	actionUnlink   actionKind = "unlink"
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
  symsync apply --src <src> --dest <dest> [--dry-run]
  symsync unapply --src <src> --dest <dest> [--dry-run]
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

	flags := flag.NewFlagSet("symsync "+command, flag.ContinueOnError)
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

		actions = append(actions, planLink(srcPath, destPath))
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

func planLink(srcPath, destPath string) action {
	info, err := os.Lstat(destPath)
	if err != nil {
		if os.IsNotExist(err) {
			return action{kind: actionLink, path: destPath, target: srcPath}
		}
		return action{kind: actionConflict, path: destPath, reason: err.Error()}
	}
	if info.Mode()&os.ModeSymlink != 0 {
		target, err := os.Readlink(destPath)
		if err != nil {
			return action{kind: actionConflict, path: destPath, reason: err.Error()}
		}
		if filepath.Clean(target) == srcPath {
			return action{kind: actionKeep, path: destPath, target: srcPath}
		}
		return action{kind: actionConflict, path: destPath, reason: "symlink points to a different target"}
	}
	return action{kind: actionConflict, path: destPath, reason: "exists and is not a managed symlink"}
}

func planUnapply(opts options) ([]action, error) {
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
			return nil
		}

		if shouldUnlink(destPath, opts.src) {
			actions = append(actions, action{kind: actionUnlink, path: destPath})
		}
		return nil
	})
	return actions, err
}

func shouldUnlink(destPath, srcRoot string) bool {
	info, err := os.Lstat(destPath)
	if err != nil || info.Mode()&os.ModeSymlink == 0 {
		return false
	}
	target, err := os.Readlink(destPath)
	if err != nil {
		return false
	}
	if !filepath.IsAbs(target) {
		absTarget, err := filepath.Abs(filepath.Join(filepath.Dir(destPath), target))
		if err != nil {
			return false
		}
		target = absTarget
	}
	target = filepath.Clean(target)
	return target == srcRoot || strings.HasPrefix(target, srcRoot+string(os.PathSeparator))
}

func printActions(actions []action) {
	for _, action := range actions {
		switch action.kind {
		case actionLink, actionKeep:
			fmt.Printf("%-9s %s -> %s\n", action.kind, action.path, action.target)
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
			if err := os.MkdirAll(action.path, 0755); err != nil {
				return err
			}
		case actionLink:
			if err := os.MkdirAll(filepath.Dir(action.path), 0755); err != nil {
				return err
			}
			if err := os.Symlink(action.target, action.path); err != nil {
				return err
			}
		case actionUnlink:
			if err := os.Remove(action.path); err != nil && !os.IsNotExist(err) {
				return err
			}
		}
	}
	return nil
}
