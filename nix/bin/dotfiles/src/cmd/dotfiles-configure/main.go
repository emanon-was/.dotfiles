package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
)

const usageText = `Usage:
  dotfiles configure <command> [args...]
  dotfiles configure help

Dispatches to dotfiles-configure-<command> found next to this executable or on PATH.
Run a subcommand with --help for command-specific usage.
`

func usage(w *os.File, invoked string) {
	fmt.Fprint(w, usageText)
	commands := listSubcommands(invoked)
	if len(commands) == 0 {
		return
	}
	fmt.Fprintln(w)
	fmt.Fprintln(w, "Commands:")
	for _, command := range commands {
		fmt.Fprintf(w, "  %s\n", command)
	}
}

func main() {
	os.Exit(run(os.Args))
}

func run(args []string) int {
	if len(args) < 2 {
		usage(os.Stdout, args[0])
		return 0
	}

	subcommand := args[1]
	switch subcommand {
	case "-h", "--help", "help":
		usage(os.Stdout, args[0])
		return 0
	case "--commands":
		printCommands(os.Stdout, args[0])
		return 0
	}
	if len(subcommand) > 0 && subcommand[0] == '-' {
		usage(os.Stderr, args[0])
		return 2
	}

	executable := "dotfiles-configure-" + subcommand
	path, err := findSubcommand(executable, args[0])
	if err != nil {
		fmt.Fprintf(os.Stderr, "error: unknown dotfiles configure command: %s\n", subcommand)
		usage(os.Stderr, args[0])
		return 127
	}

	cmd := exec.Command(path, args[2:]...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = os.Environ()
	if err := cmd.Run(); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			return exitErr.ExitCode()
		}
		fmt.Fprintf(os.Stderr, "error: failed to run %s: %v\n", executable, err)
		return 126
	}
	return 0
}

func findSubcommand(name string, invoked string) (string, error) {
	for _, self := range executablePaths(invoked) {
		sibling := filepath.Join(filepath.Dir(self), name)
		if isExecutable(sibling) {
			return sibling, nil
		}
	}

	path, err := exec.LookPath(name)
	if err != nil {
		return "", err
	}
	return path, nil
}

func isExecutable(path string) bool {
	info, err := os.Stat(path)
	if err != nil || info.IsDir() {
		return false
	}
	return info.Mode().Perm()&0111 != 0
}

func listSubcommands(invoked string) []string {
	commands := map[string]struct{}{}

	for _, dir := range commandDirs(invoked) {
		entries, err := os.ReadDir(dir)
		if err != nil {
			continue
		}
		for _, entry := range entries {
			name := entry.Name()
			if !strings.HasPrefix(name, "dotfiles-configure-") {
				continue
			}
			path := filepath.Join(dir, name)
			if !isExecutable(path) {
				continue
			}
			command := strings.TrimPrefix(name, "dotfiles-configure-")
			if command == "" {
				continue
			}
			commands[command] = struct{}{}
		}
	}

	result := make([]string, 0, len(commands))
	for command := range commands {
		result = append(result, command)
	}
	sort.Strings(result)
	return result
}

func commandDirs(invoked string) []string {
	dirs := []string{}
	seen := map[string]struct{}{}
	addDir := func(dir string) {
		if dir == "" {
			return
		}
		if _, ok := seen[dir]; ok {
			return
		}
		seen[dir] = struct{}{}
		dirs = append(dirs, dir)
	}

	for _, self := range executablePaths(invoked) {
		addDir(filepath.Dir(self))
	}

	for _, dir := range filepath.SplitList(os.Getenv("PATH")) {
		addDir(dir)
	}
	return dirs
}

func executablePaths(invoked string) []string {
	paths := []string{}
	seen := map[string]struct{}{}
	addPath := func(path string) {
		if path == "" {
			return
		}
		if abs, err := filepath.Abs(path); err == nil {
			path = abs
		}
		if _, ok := seen[path]; ok {
			return
		}
		seen[path] = struct{}{}
		paths = append(paths, path)
	}

	if strings.ContainsRune(invoked, os.PathSeparator) {
		addPath(invoked)
	} else if path, err := exec.LookPath(invoked); err == nil {
		addPath(path)
	}

	for _, path := range append([]string{}, paths...) {
		if resolved, err := filepath.EvalSymlinks(path); err == nil && resolved != path {
			addPath(resolved)
		}
	}

	if self, err := os.Executable(); err == nil {
		addPath(self)
	}

	return paths
}

func printCommands(w *os.File, invoked string) {
	for _, command := range listSubcommands(invoked) {
		fmt.Fprintln(w, command)
	}
}
