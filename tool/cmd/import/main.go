package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

type importGroup int

const (
	groupDart importGroup = iota
	groupFlutter
	groupPulse
	groupOther
	groupRelative
)

var directoryAnchors = []string{
	"lib",
	"development",
	"test",
	"tool",
	"integration_test",
	"bin",
}

type importEntry struct {
	lines []string
	uri   string
	group importGroup
}

type dependencyGraph map[string]map[string]struct{}

func main() {
	root, err := os.Getwd()
	if err != nil {
		fatal(err)
	}

	graph := make(dependencyGraph)

	for _, dir := range directoryAnchors {
		abs := filepath.Join(root, dir)
		if err := walkDartFiles(abs, func(path string, d fs.DirEntry) error {
			rel := filepath.ToSlash(relPath(root, path))
			changed, err := processFile(root, path, rel, graph)
			if err != nil {
				return err
			}
			if changed {
				fmt.Printf("updated imports: %s\n", rel)
			}
			return nil
		}); err != nil {
			fatal(err)
		}
	}

	cycles := detectCycles(graph)
	if len(cycles) > 0 {
		fmt.Fprintln(os.Stderr, "pulse import cycles detected:")
		for _, cycle := range cycles {
			fmt.Fprintf(os.Stderr, " - %s\n", strings.Join(cycle, " -> "))
		}
		os.Exit(1)
	}
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(2)
}

func walkDartFiles(root string, fn func(string, fs.DirEntry) error) error {
	info, err := os.Stat(root)
	if errors.Is(err, fs.ErrNotExist) {
		return nil
	}
	if err != nil {
		return err
	}
	if !info.IsDir() {
		return nil
	}
	return filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Ext(path) != ".dart" {
			return nil
		}
		name := filepath.Base(path)
		if strings.HasSuffix(name, ".g.dart") || strings.HasSuffix(name, ".freezed.dart") || strings.HasSuffix(name, ".mocks.dart") {
			return nil
		}
		return fn(path, d)
	})
}

func processFile(root, path, rel string, graph dependencyGraph) (bool, error) {
	contentBytes, err := os.ReadFile(path)
	if err != nil {
		return false, err
	}
	content := string(contentBytes)
	lines := splitLines(content)

	entries, blockStart, blockEnd := extractImports(lines)
	if len(entries) == 0 {
		if strings.HasPrefix(rel, "lib/") {
			graph.ensureNode(rel)
		}
		return false, nil
	}

	inLib := strings.HasPrefix(rel, "lib/")

	if inLib {
		for i := range entries {
			if _, err := canonicalizeImport(root, path, &entries[i]); err != nil {
				return false, err
			}
		}
	}

	if inLib {
		graph.ensureNode(rel)
		for _, entry := range entries {
			if entry.group != groupPulse {
				continue
			}
			target := strings.TrimPrefix(entry.uri, "package:pulse/")
			if target == entry.uri {
				continue
			}
			targetPath := filepath.ToSlash(filepath.Clean(filepath.Join("lib", target)))
			graph.addEdge(rel, targetPath)
		}
	}

	rebuiltBlock := rebuildImportBlock(entries)
	newLines := append([]string{}, lines[:blockStart]...)
	newLines = append(newLines, rebuiltBlock...)
	newLines = append(newLines, lines[blockEnd+1:]...)

	newContent := strings.Join(newLines, "\n")
	if strings.HasSuffix(content, "\n") && !strings.HasSuffix(newContent, "\n") {
		newContent += "\n"
	}
	if newContent == content {
		return false, nil
	}
	if err := os.WriteFile(path, []byte(newContent), 0o600); err != nil {
		return false, err
	}
	return true, nil
}

func extractImports(lines []string) ([]importEntry, int, int) {
	var entries []importEntry
	blockStart := -1
	blockEnd := -1
	for i := 0; i < len(lines); {
		trimmed := strings.TrimSpace(lines[i])
		if strings.HasPrefix(trimmed, "import ") {
			start := i
			for start-1 >= 0 {
				prevTrim := strings.TrimSpace(lines[start-1])
				if prevTrim == "" {
					break
				}
				if strings.HasPrefix(prevTrim, "//") || strings.HasPrefix(prevTrim, "///") || strings.HasPrefix(prevTrim, "/*") || strings.HasPrefix(prevTrim, "*") || strings.HasSuffix(prevTrim, "*/") {
					start--
					continue
				}
				break
			}
			end := i
			for {
				if strings.Contains(lines[end], ";") || end == len(lines)-1 {
					break
				}
				end++
			}
			segment := strings.Join(lines[i:end+1], "\n")
			uri := parseImportURI(segment)
			if uri == "" {
				uri = segment
			}
			entryLines := append([]string{}, lines[start:end+1]...)
			entries = append(entries, importEntry{
				lines: entryLines,
				uri:   uri,
				group: classifyGroup(uri),
			})
			if blockStart == -1 || start < blockStart {
				blockStart = start
			}
			if end > blockEnd {
				blockEnd = end
			}
			i = end + 1
			continue
		}
		i++
	}
	if len(entries) == 0 {
		return nil, -1, -1
	}
	return entries, blockStart, blockEnd
}

func parseImportURI(stmt string) string {
	idx := strings.Index(stmt, "import")
	if idx == -1 {
		return ""
	}
	rest := strings.TrimSpace(stmt[idx+len("import"):])
	if rest == "" {
		return ""
	}
	quote := rune(rest[0])
	if quote != '\'' && quote != '"' {
		return ""
	}
	rest = rest[1:]
	end := strings.IndexRune(rest, quote)
	if end == -1 {
		return ""
	}
	return rest[:end]
}

func classifyGroup(uri string) importGroup {
	switch {
	case strings.HasPrefix(uri, "dart:"):
		return groupDart
	case strings.HasPrefix(uri, "package:flutter"):
		return groupFlutter
	case strings.HasPrefix(uri, "package:pulse/"):
		return groupPulse
	case strings.HasPrefix(uri, "package:"):
		return groupOther
	default:
		return groupRelative
	}
}

func rebuildImportBlock(entries []importEntry) []string {
	groups := map[importGroup][]importEntry{}
	for _, entry := range entries {
		groups[entry.group] = append(groups[entry.group], entry)
	}

	var result []string
	order := []importGroup{groupDart, groupFlutter, groupPulse, groupOther, groupRelative}
	for _, group := range order {
		items := groups[group]
		if len(items) == 0 {
			continue
		}
		sort.SliceStable(items, func(i, j int) bool {
			if items[i].uri == items[j].uri {
				return strings.Join(items[i].lines, "\n") < strings.Join(items[j].lines, "\n")
			}
			return items[i].uri < items[j].uri
		})
		if len(result) > 0 {
			result = append(result, "")
		}
		for _, item := range items {
			result = append(result, item.lines...)
		}
	}
	return result
}

func canonicalizeImport(root, filePath string, entry *importEntry) (bool, error) {
	uri := entry.uri
	if uri == "" {
		return false, nil
	}
	if strings.Contains(uri, ":") || strings.HasPrefix(uri, "/") {
		return false, nil
	}
	baseDir := filepath.Dir(filePath)
	targetPath := filepath.Clean(filepath.Join(baseDir, uri))
	relTarget, err := filepath.Rel(root, targetPath)
	if err != nil {
		return false, err
	}
	relTarget = filepath.ToSlash(relTarget)
	if !strings.HasPrefix(relTarget, "lib/") {
		return false, fmt.Errorf("relative import %q in %s points outside lib/", uri, filePath)
	}
	newURI := "package:pulse/" + strings.TrimPrefix(relTarget, "lib/")
	if newURI == uri {
		return false, nil
	}
	replaceImportURI(entry, uri, newURI)
	entry.uri = newURI
	entry.group = classifyGroup(newURI)
	return true, nil
}

func replaceImportURI(entry *importEntry, oldURI, newURI string) {
	singleNeedle := "'" + oldURI + "'"
	doubleNeedle := "\"" + oldURI + "\""
	replacementSingle := "'" + newURI + "'"
	replacementDouble := "\"" + newURI + "\""
	for idx, line := range entry.lines {
		if strings.Contains(line, singleNeedle) {
			entry.lines[idx] = strings.Replace(line, singleNeedle, replacementSingle, 1)
			return
		}
		if strings.Contains(line, doubleNeedle) {
			entry.lines[idx] = strings.Replace(line, doubleNeedle, replacementDouble, 1)
			return
		}
	}
	joined := strings.Join(entry.lines, "\n")
	if strings.Contains(joined, singleNeedle) {
		updated := strings.Replace(joined, singleNeedle, replacementSingle, 1)
		entry.lines = strings.Split(updated, "\n")
		return
	}
	if strings.Contains(joined, doubleNeedle) {
		updated := strings.Replace(joined, doubleNeedle, replacementDouble, 1)
		entry.lines = strings.Split(updated, "\n")
		return
	}
	if strings.Contains(joined, oldURI) {
		updated := strings.Replace(joined, oldURI, newURI, 1)
		entry.lines = strings.Split(updated, "\n")
	}
}

func splitLines(content string) []string {
	if content == "" {
		return []string{""}
	}
	parts := strings.Split(content, "\n")
	return parts
}

func (g dependencyGraph) ensureNode(node string) {
	if node == "" {
		return
	}
	if _, ok := g[node]; !ok {
		g[node] = make(map[string]struct{})
	}
}

func (g dependencyGraph) addEdge(from, to string) {
	if from == "" || to == "" {
		return
	}
	g.ensureNode(from)
	g.ensureNode(to)
	g[from][to] = struct{}{}
}

func detectCycles(graph dependencyGraph) [][]string {
	visited := make(map[string]int)
	stack := make([]string, 0)
	var cycles [][]string
	seenCycles := make(map[string]struct{})

	var dfs func(string)
	dfs = func(node string) {
		visited[node] = 1
		stack = append(stack, node)
		for neighbor := range graph[node] {
			state := visited[neighbor]
			if state == 0 {
				dfs(neighbor)
				continue
			}
			if state == 1 {
				cycle := extractCycle(stack, neighbor)
				key := strings.Join(cycle, "->")
				if _, ok := seenCycles[key]; !ok {
					seenCycles[key] = struct{}{}
					cycles = append(cycles, cycle)
				}
			}
		}
		stack = stack[:len(stack)-1]
		visited[node] = 2
	}

	nodes := make([]string, 0, len(graph))
	for node := range graph {
		nodes = append(nodes, node)
	}
	sort.Strings(nodes)
	for _, node := range nodes {
		if visited[node] == 0 {
			dfs(node)
		}
	}
	return cycles
}

func extractCycle(stack []string, target string) []string {
	idx := -1
	for i := len(stack) - 1; i >= 0; i-- {
		if stack[i] == target {
			idx = i
			break
		}
	}
	if idx == -1 {
		return []string{target}
	}
	cycle := append([]string{}, stack[idx:]...)
	cycle = append(cycle, target)
	return cycle
}

func relPath(root, path string) string {
	rel, err := filepath.Rel(root, path)
	if err != nil {
		return path
	}
	return rel
}
