package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

type symbol struct {
	Label      string
	Deprecated bool
	Path       string
	Line       int
}

type entry struct {
	Types           []symbol
	ExportedFuncs   []symbol
	UnexportedFuncs []symbol
	Tests           []string
	HasContent      bool
	HasDeprecated   bool
}

var (
	classPattern          = regexp.MustCompile(`(?m)^\s*((?:(?:abstract|sealed|base|final|interface|mixin)\s+)*class)\s+([A-Za-z_]\w*)`)
	mixinPattern          = regexp.MustCompile(`(?m)^\s*((?:base\s+)?mixin)\s+([A-Za-z_]\w*)`)
	enumPattern           = regexp.MustCompile(`(?m)^\s*((?:sealed\s+)?enum)\s+([A-Za-z_]\w*)`)
	typedefPattern        = regexp.MustCompile(`(?m)^\s*(typedef)\s+([A-Za-z_]\w*)`)
	extensionPattern      = regexp.MustCompile(`(?m)^\s*extension(?:\s+([A-Za-z_]\w*))?\s+on\s+([^\s{]+)`)
	extensionTypePattern  = regexp.MustCompile(`(?m)^\s*extension\s+type\s+([A-Za-z_]\w*)\s*=\s*([^;{]+)`)
	functionPattern       = regexp.MustCompile(`(?m)^\s*((?:[A-Za-z_][\w<>,?\[\]]*\s+)+)([A-Za-z_]\w*)\s*\([^;{=]*\)\s*(?:=>|\{)`)
	importPattern         = regexp.MustCompile(`(?m)import\s+['"]([^'"\n]+)['"][^;]*;`)
	partPattern           = regexp.MustCompile(`(?m)part\s+['"]([^'"\n]+)['"];`)
	partOfPattern         = regexp.MustCompile(`(?m)part\s+of\s+['"]([^'"\n]+)['"];`)
	blockCommentPattern   = regexp.MustCompile(`(?s)/\*.*?\*/`)
	lineCommentPattern    = regexp.MustCompile(`(?m)^\s*//.*$`)
	testInvocationPattern = regexp.MustCompile(`^test(?:Widgets|Goldens)?(?:<[^>]+>)?\s*\(`)
)

const (
	legendLine = "_Legend: 🪦 unused file · ⚠️ deprecated symbol · 🧪 no dedicated test_"
)

func main() {
	root, err := os.Getwd()
	if err != nil {
		fatal(err)
	}

	catalog, unused, deprecated, emptyDirs, unexpected, missingComments, err := buildCatalog(root)
	if err != nil {
		fatal(err)
	}

	docPath := filepath.Join(root, "docs", "catalog.md")
	if err := os.WriteFile(docPath, []byte(catalog), 0o644); err != nil {
		fatal(err)
	}
	fmt.Printf("catalog written to %s\n", docPath)

	if len(unused) > 0 || len(deprecated) > 0 || len(emptyDirs) > 0 || len(unexpected) > 0 || len(missingComments) > 0 {
		if len(unused) > 0 {
			fmt.Printf("unused files (%d):\n", len(unused))
			dumpList(unused)
		}
		if len(deprecated) > 0 {
			fmt.Printf("files with deprecated symbols (%d):\n", len(deprecated))
			dumpList(deprecated)
		}
		if len(emptyDirs) > 0 {
			fmt.Printf("empty directories (%d):\n", len(emptyDirs))
			dumpList(emptyDirs)
		}
		if len(unexpected) > 0 {
			fmt.Printf("unexpected files (%d):\n", len(unexpected))
			dumpList(unexpected)
		}
		if len(missingComments) > 0 {
			fmt.Printf("tests missing intent comments (%d):\n", len(missingComments))
			dumpList(missingComments)
		}
		os.Exit(1)
	}
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(2)
}

func buildCatalog(root string) (string, []string, []string, []string, []string, []string, error) {
	libDir := filepath.Join(root, "lib")
	testDir := filepath.Join(root, "test")

	entries, unexpectedFiles, err := gatherEntries(root, libDir)
	if err != nil {
		return "", nil, nil, nil, nil, nil, err
	}

	usage, err := gatherUsage(root, libDir, testDir)
	if err != nil {
		return "", nil, nil, nil, nil, nil, err
	}

	libTests, strayTests, missingComments, err := gatherTestMappings(root, testDir)
	if err != nil {
		return "", nil, nil, nil, nil, nil, err
	}

	emptyDirs, err := findEmptyDirs(root, []string{"lib", "test"})
	if err != nil {
		return "", nil, nil, nil, nil, nil, err
	}

	duplicateFunctions, err := gatherDuplicateFunctionSignatures(root, []string{"lib", "test"})
	if err != nil {
		return "", nil, nil, nil, nil, nil, err
	}

	paths := make([]string, 0, len(entries))
	for path := range entries {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	var builder strings.Builder
	builder.WriteString("# Library Catalog\n\n")
	builder.WriteString(
		fmt.Sprintf("Generated on %s by `go run ./tool/cmd/catalog`.\n\n", time.Now().UTC().Format("2006-01-02 15:04 UTC")),
	)
	builder.WriteString(legendLine)
	builder.WriteString("\n\n")
	builder.WriteString("| Status | File | Top-level types | Exported functions | Unexported functions | File test | Related tests |\n")
	builder.WriteString("| --- | --- | --- | --- | --- | --- | --- |\n")

	unusedSet := make(map[string]struct{})
	deprecatedSet := make(map[string]struct{})

	for _, path := range paths {
		entry := entries[path]
		dedicatedPath := dedicatedTestFor(path)
		dedicatedExists := hasFile(root, dedicatedPath)
		tests := filterRelatedTests(libTests[path], dedicatedPath)
		entry.Tests = append(entry.Tests, tests...)
		hasDeprecated := entry.HasDeprecated
		statuses := make([]string, 0, 3)

		if !usage[path] || !entry.HasContent {
			statuses = append(statuses, "🪦")
			unusedSet[path] = struct{}{}
		}
		if hasDeprecated {
			statuses = append(statuses, "⚠️")
			deprecatedSet[path] = struct{}{}
		}
		if !dedicatedExists {
			statuses = append(statuses, "🧪")
		}

		statusCell := "—"
		if len(statuses) > 0 {
			statusCell = strings.Join(statuses, " ")
		}

		typeCell := formatSymbols(entry.Types)
		exportedCell := formatSymbols(entry.ExportedFuncs)
		unexportedCell := formatSymbols(entry.UnexportedFuncs)
		fileTestCell := formatFileTest(dedicatedPath, dedicatedExists)
		testCell := formatTests(tests)
		builder.WriteString(fmt.Sprintf("| %s | [`%s`](../%s) | %s | %s | %s | %s | %s |\n",
			statusCell,
			path,
			path,
			typeCell,
			exportedCell,
			unexportedCell,
			fileTestCell,
			testCell,
		))
	}

	builder.WriteString("\n---\n\n")
	builder.WriteString("### Tests missing intent comments\n")
	if len(missingComments) == 0 {
		builder.WriteString("- None\n")
	} else {
		sortedMissing := append([]string(nil), missingComments...)
		sort.Strings(sortedMissing)
		for _, entry := range sortedMissing {
			path, line := splitPathAndLine(entry)
			if line > 0 {
				builder.WriteString(fmt.Sprintf("- [`%s`](../%s#L%d) — line %d\n", path, path, line, line))
			} else {
				builder.WriteString(fmt.Sprintf("- [`%s`](../%s)\n", path, path))
			}
		}
	}
	builder.WriteString("\n> _Every `test` and `testWidgets` block should include an intent comment explaining its purpose._\n\n")
	builder.WriteString("### Stray test files\n")
	if len(strayTests) == 0 {
		builder.WriteString("- None\n")
	} else {
		sort.Strings(strayTests)
		for _, testPath := range strayTests {
			builder.WriteString(fmt.Sprintf("- [`%s`](../%s)\n", testPath, testPath))
		}
	}
	builder.WriteString("\n> _A test is considered stray if it lacks a `lib/` import or its path/name doesn't mirror the file it covers—`lib/foo/bar.dart` expects `test/foo/bar_test.dart`._\n\n")

	builder.WriteString("### Possibly duplicate functions\n")
	if len(duplicateFunctions) == 0 {
		builder.WriteString("- None\n")
	} else {
		signatures := make([]string, 0, len(duplicateFunctions))
		for signature := range duplicateFunctions {
			signatures = append(signatures, signature)
		}
		sort.Strings(signatures)
		for _, signature := range signatures {
			builder.WriteString(fmt.Sprintf("- `%s`\n", signature))
			locations := append([]string(nil), duplicateFunctions[signature]...)
			sort.Strings(locations)
			for _, location := range locations {
				path, line := splitPathAndLine(location)
				if line > 0 {
					builder.WriteString(fmt.Sprintf("  - [`%s`](../%s#L%d)\n", path, path, line))
				} else {
					builder.WriteString(fmt.Sprintf("  - [`%s`](../%s)\n", path, path))
				}
			}
		}
	}
	builder.WriteString("\n> _Functions with identical signatures may indicate duplication._\n\n")

	if len(strayTests) > 0 {
		fmt.Printf("warning: %d stray test files found\n", len(strayTests))
	}
	if len(duplicateFunctions) > 0 {
		fmt.Printf("warning: %d possible duplicate function signatures found\n", len(duplicateFunctions))
	}

	return builder.String(), toSortedSlice(unusedSet), toSortedSlice(deprecatedSet), emptyDirs, unexpectedFiles, missingComments, nil
}

var controlKeywords = map[string]struct{}{
	"return":   {},
	"await":    {},
	"yield":    {},
	"throw":    {},
	"case":     {},
	"default":  {},
	"break":    {},
	"continue": {},
	"if":       {},
	"else":     {},
	"for":      {},
	"while":    {},
	"switch":   {},
	"do":       {},
	"try":      {},
	"catch":    {},
	"finally":  {},
}

func gatherEntries(root, libDir string) (map[string]*entry, []string, error) {
	entries := make(map[string]*entry)
	var unexpected []string
	err := filepath.WalkDir(libDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Ext(path) != ".dart" {
			rel := filepath.ToSlash(relPath(root, path))
			unexpected = append(unexpected, rel)
			return nil
		}
		contentBytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		content := string(contentBytes)
		relative := filepath.ToSlash(relPath(root, path))
		entry := &entry{}
		entry.Types = append(entry.Types, collectSymbols(content, classPattern)...)
		entry.Types = append(entry.Types, collectSymbols(content, mixinPattern)...)
		entry.Types = append(entry.Types, collectSymbols(content, enumPattern)...)
		entry.Types = append(entry.Types, collectSymbols(content, typedefPattern)...)
		entry.Types = append(entry.Types, collectExtensionSymbols(content, extensionPattern, true)...)
		entry.Types = append(entry.Types, collectExtensionSymbols(content, extensionTypePattern, false)...)
		entry.ExportedFuncs, entry.UnexportedFuncs = collectFunctionSymbols(content, relative)
		entry.HasContent = hasMeaningfulContent(content)
		for _, group := range [][]symbol{entry.Types, entry.ExportedFuncs, entry.UnexportedFuncs} {
			for _, sym := range group {
				if sym.Deprecated {
					entry.HasDeprecated = true
					break
				}
			}
			if entry.HasDeprecated {
				break
			}
		}
		entries[relative] = entry
		return nil
	})
	sort.Strings(unexpected)
	return entries, unexpected, err
}

func gatherUsage(root, libDir, testDir string) (map[string]bool, error) {
	usage := make(map[string]bool)
	usage["lib/main.dart"] = true
	process := func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if filepath.Ext(path) != ".dart" {
			return nil
		}
		contentBytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		content := string(contentBytes)
		matches := importPattern.FindAllStringSubmatch(content, -1)
		for _, m := range matches {
			uri := m[1]
			target, err := resolveURI(root, path, uri)
			if err != nil {
				return err
			}
			if target != "" {
				usage[target] = true
			}
		}
		parts := partPattern.FindAllStringSubmatch(content, -1)
		for _, m := range parts {
			target, err := resolveURI(root, path, m[1])
			if err != nil {
				return err
			}
			if target != "" {
				usage[target] = true
			}
		}
		partOfs := partOfPattern.FindAllStringSubmatch(content, -1)
		for _, m := range partOfs {
			if strings.HasPrefix(m[1], "package:pulse/") {
				rel := filepath.ToSlash(filepath.Join("lib", strings.TrimPrefix(m[1], "package:pulse/")))
				usage[rel] = true
				continue
			}
			target, err := resolveURI(root, path, m[1])
			if err != nil {
				return err
			}
			if target != "" {
				usage[target] = true
			}
		}
		return nil
	}
	if err := filepath.WalkDir(libDir, process); err != nil {
		return nil, err
	}
	if err := filepath.WalkDir(testDir, process); err != nil && !errors.Is(err, fs.ErrNotExist) {
		return nil, err
	}
	return usage, nil
}

func gatherTestMappings(root, testDir string) (map[string][]string, []string, []string, error) {
	mapping := make(map[string][]string)
	var stray []string
	var missing []string
	err := filepath.WalkDir(testDir, func(path string, d fs.DirEntry, err error) error {
		if errors.Is(err, fs.ErrNotExist) {
			return nil
		}
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}
		if !strings.HasSuffix(path, "_test.dart") {
			return nil
		}
		contentBytes, err := os.ReadFile(path)
		if err != nil {
			return err
		}
		content := string(contentBytes)
		relTest := filepath.ToSlash(relPath(root, path))
		missingLines := findTestsMissingIntentCommentLines(content)
		if len(missingLines) > 0 {
			for _, line := range missingLines {
				missing = append(missing, fmt.Sprintf("%s:%d", relTest, line))
			}
		}
		hasLibImport := false
		matchedDedicated := false
		imports := importPattern.FindAllStringSubmatch(content, -1)
		for _, m := range imports {
			target, err := resolveURI(root, path, m[1])
			if err != nil {
				return err
			}
			if target == "" {
				continue
			}
			if !strings.HasPrefix(target, "lib/") {
				continue
			}
			mapping[target] = append(mapping[target], relTest)
			hasLibImport = true
			if dedicated := dedicatedTestFor(target); dedicated != "" && relTest == dedicated {
				matchedDedicated = true
			}
		}
		if !hasLibImport || !matchedDedicated {
			stray = append(stray, relTest)
		}
		return nil
	})
	return mapping, stray, missing, err
}

func gatherDuplicateFunctionSignatures(root string, anchors []string) (map[string][]string, error) {
	signatures := make(map[string][]string)
	for _, anchor := range anchors {
		base := filepath.Join(root, anchor)
		err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
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
			contentBytes, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			content := string(contentBytes)
			matches := functionPattern.FindAllStringSubmatchIndex(content, -1)
			if len(matches) == 0 {
				return nil
			}
			rel := filepath.ToSlash(relPath(root, path))
			for _, m := range matches {
				returnSegment := strings.TrimSpace(content[m[2]:m[3]])
				if shouldSkipFunction(returnSegment) {
					continue
				}
				signature := strings.TrimSpace(content[m[0]:m[1]])
				signature = strings.TrimSuffix(signature, "{")
				signature = strings.TrimSpace(signature)
				signature = strings.TrimSuffix(signature, "=>")
				signature = strings.TrimSpace(signature)
				signature = normalizeWhitespace(signature)
				if signature == "" {
					continue
				}
				line := 1 + strings.Count(content[:m[0]], "\n")
				location := fmt.Sprintf("%s:%d", rel, line)
				signatures[signature] = append(signatures[signature], location)
			}
			return nil
		})
		if err != nil {
			if errors.Is(err, fs.ErrNotExist) {
				continue
			}
			return nil, err
		}
	}

	duplicates := make(map[string][]string)
	for signature, locations := range signatures {
		if len(locations) > 1 {
			duplicates[signature] = locations
		}
	}

	return duplicates, nil
}

func findTestsMissingIntentCommentLines(content string) []int {
	lines := strings.Split(content, "\n")
	var missing []int
	for idx, line := range lines {
		if !testInvocationPattern.MatchString(strings.TrimSpace(line)) {
			continue
		}
		if hasIntentComment(lines, idx) {
			continue
		}
		missing = append(missing, idx+1)
	}
	return missing
}

func hasIntentComment(lines []string, index int) bool {
	for i := index - 1; i >= 0; i-- {
		trimmed := strings.TrimSpace(lines[i])
		if trimmed == "" {
			continue
		}
		if strings.HasPrefix(trimmed, "//") || strings.HasPrefix(trimmed, "///") {
			return true
		}
		if strings.HasPrefix(trimmed, "/*") || strings.HasPrefix(trimmed, "*") || strings.HasSuffix(trimmed, "*/") {
			return true
		}
		return false
	}
	return false
}

func splitPathAndLine(entry string) (string, int) {
	idx := strings.LastIndex(entry, ":")
	if idx == -1 {
		return entry, 0
	}
	path := entry[:idx]
	line, err := strconv.Atoi(entry[idx+1:])
	if err != nil {
		return path, 0
	}
	return path, line
}

func normalizeWhitespace(s string) string {
	if s == "" {
		return s
	}
	return strings.Join(strings.Fields(s), " ")
}

func findEmptyDirs(root string, anchors []string) ([]string, error) {
	emptySet := make(map[string]struct{})
	for _, anchor := range anchors {
		base := filepath.Join(root, anchor)
		err := filepath.WalkDir(base, func(path string, d fs.DirEntry, err error) error {
			if errors.Is(err, fs.ErrNotExist) {
				return nil
			}
			if err != nil {
				return err
			}
			if !d.IsDir() {
				return nil
			}
			entries, err := os.ReadDir(path)
			if err != nil {
				return err
			}
			if len(entries) == 0 {
				emptySet[filepath.ToSlash(relPath(root, path))] = struct{}{}
			}
			return nil
		})
		if err != nil {
			return nil, err
		}
	}
	return toSortedSlice(emptySet), nil
}

func collectSymbols(content string, pattern *regexp.Regexp) []symbol {
	matches := pattern.FindAllStringSubmatchIndex(content, -1)
	var symbols []symbol
	for _, m := range matches {
		label := fmt.Sprintf("%s %s", strings.TrimSpace(content[m[2]:m[3]]), strings.TrimSpace(content[m[4]:m[5]]))
		sym := symbol{Label: label, Deprecated: isDeprecated(content, m[0])}
		symbols = append(symbols, sym)
	}
	return symbols
}

func collectExtensionSymbols(content string, pattern *regexp.Regexp, includeOn bool) []symbol {
	submatches := pattern.FindAllStringSubmatchIndex(content, -1)
	var symbols []symbol
	for _, m := range submatches {
		name := ""
		if len(m) > 2 && m[2] >= 0 && m[3] >= 0 {
			name = strings.TrimSpace(content[m[2]:m[3]])
		}
		target := ""
		if len(m) > 4 && m[4] >= 0 && m[5] >= 0 {
			target = strings.TrimSpace(content[m[4]:m[5]])
		}
		var label string
		if includeOn {
			if name == "" {
				label = fmt.Sprintf("extension on %s", target)
			} else {
				label = fmt.Sprintf("extension %s on %s", name, target)
			}
		} else {
			label = fmt.Sprintf("extension type %s = %s", name, target)
		}
		symbols = append(symbols, symbol{Label: label, Deprecated: isDeprecated(content, m[0])})
	}
	return symbols
}

func collectFunctionSymbols(content, path string) ([]symbol, []symbol) {
	matches := functionPattern.FindAllStringSubmatchIndex(content, -1)
	var exported []symbol
	var unexported []symbol
	for _, m := range matches {
		returnSegment := strings.TrimSpace(content[m[2]:m[3]])
		if shouldSkipFunction(returnSegment) {
			continue
		}
		name := strings.TrimSpace(content[m[4]:m[5]])
		if name == "" {
			continue
		}
		line := 1 + strings.Count(content[:m[0]], "\n")
		label := deriveFunctionLabel(content, m[0], name)
		sym := symbol{
			Label:      label,
			Deprecated: isDeprecated(content, m[0]),
			Path:       path,
			Line:       line,
		}
		if strings.HasPrefix(name, "_") {
			unexported = append(unexported, sym)
			continue
		}
		exported = append(exported, sym)
	}
	return exported, unexported
}

func shouldSkipFunction(prefix string) bool {
	if prefix == "" {
		return false
	}
	fields := strings.Fields(prefix)
	if len(fields) == 0 {
		return false
	}
	first := strings.TrimSpace(fields[0])
	first = strings.Trim(first, "*:&")
	first = strings.TrimSuffix(first, ":")
	first = strings.ToLower(first)
	_, skip := controlKeywords[first]
	return skip
}

func deriveFunctionLabel(content string, start int, name string) string {
	context := findEnclosingTypeName(content, start)
	label := name + "()"
	if context == "" {
		return label
	}
	return context + "." + label
}

type typeMatcher struct {
	pattern       *regexp.Regexp
	nameExtractor func(content string, match []int) string
}

var typeMatchers = []typeMatcher{
	{classPattern, func(content string, match []int) string {
		return strings.TrimSpace(content[match[4]:match[5]])
	}},
	{mixinPattern, func(content string, match []int) string {
		return strings.TrimSpace(content[match[4]:match[5]])
	}},
	{enumPattern, func(content string, match []int) string {
		return strings.TrimSpace(content[match[4]:match[5]])
	}},
	{extensionPattern, func(content string, match []int) string {
		name := ""
		if len(match) > 4 && match[4] >= 0 && match[5] >= 0 {
			name = strings.TrimSpace(content[match[4]:match[5]])
		}
		if name != "" {
			return name
		}
		target := ""
		if len(match) > 6 && match[6] >= 0 && match[7] >= 0 {
			target = strings.TrimSpace(content[match[6]:match[7]])
		}
		if target != "" {
			return "extension on " + target
		}
		return "extension"
	}},
	{extensionTypePattern, func(content string, match []int) string {
		return strings.TrimSpace(content[match[2]:match[3]])
	}},
}

func findEnclosingTypeName(content string, index int) string {
	bestName := ""
	bestStart := -1
	for _, matcher := range typeMatchers {
		matches := matcher.pattern.FindAllStringSubmatchIndex(content[:index], -1)
		for _, m := range matches {
			name := matcher.nameExtractor(content, m)
			if name == "" {
				continue
			}
			openIdx := findBraceAfter(content, m[1], index)
			if openIdx == -1 {
				continue
			}
			if !isInsideBlock(content, openIdx, index) {
				continue
			}
			if m[0] > bestStart {
				bestStart = m[0]
				bestName = name
			}
		}
	}
	return bestName
}

func findBraceAfter(content string, start, limit int) int {
	for i := start; i < limit; i++ {
		ch := content[i]
		if ch == '{' {
			return i
		}
		if ch == ';' {
			break
		}
	}
	return -1
}

func isInsideBlock(content string, openIdx, target int) bool {
	depth := 1
	for i := openIdx + 1; i < target; i++ {
		if i >= len(content) {
			break
		}
		switch content[i] {
		case '{':
			depth++
		case '}':
			depth--
			if depth == 0 {
				return false
			}
		case '\'':
			i = skipString(content, i)
		case '"':
			i = skipString(content, i)
		case '/':
			if i+1 < len(content) {
				next := content[i+1]
				if next == '/' {
					i = skipLineComment(content, i)
					continue
				}
				if next == '*' {
					i = skipBlockComment(content, i)
					continue
				}
			}
		}
	}
	return depth > 0
}

func skipString(content string, start int) int {
	quote := content[start]
	triple := false
	if start+2 < len(content) && content[start+1] == quote && content[start+2] == quote {
		triple = true
	}
	i := start + 1
	if triple {
		i = start + 3
	}
	for i < len(content) {
		if triple {
			if content[i] == quote && i+2 < len(content) && content[i+1] == quote && content[i+2] == quote {
				return i + 2
			}
			if content[i] == '\\' {
				i += 2
				continue
			}
			i++
			continue
		}
		if content[i] == '\\' {
			i += 2
			continue
		}
		if content[i] == quote {
			return i
		}
		i++
	}
	return len(content) - 1
}

func skipLineComment(content string, start int) int {
	i := start + 2
	for i < len(content) && content[i] != '\n' {
		i++
	}
	return i
}

func skipBlockComment(content string, start int) int {
	i := start + 2
	for i+1 < len(content) {
		if content[i] == '*' && content[i+1] == '/' {
			return i + 1
		}
		i++
	}
	return len(content) - 1
}

func isDeprecated(content string, start int) bool {
	before := content[:start]
	lines := strings.Split(before, "\n")
	inBlock := false
	for i := len(lines) - 1; i >= 0; i-- {
		line := strings.TrimSpace(lines[i])
		if inBlock {
			if strings.HasPrefix(line, "/*") {
				inBlock = false
			}
			continue
		}
		if line == "" {
			continue
		}
		if strings.HasSuffix(line, "*/") {
			inBlock = true
			continue
		}
		if strings.HasPrefix(line, "//") {
			continue
		}
		if strings.HasPrefix(line, "@") {
			if strings.HasPrefix(line, "@Deprecated") {
				return true
			}
			continue
		}
		break
	}
	return false
}

func hasMeaningfulContent(content string) bool {
	withoutBlocks := blockCommentPattern.ReplaceAllString(content, "")
	withoutLines := lineCommentPattern.ReplaceAllString(withoutBlocks, "")
	return strings.TrimSpace(withoutLines) != ""
}

func formatSymbols(symbols []symbol) string {
	if len(symbols) == 0 {
		return "—"
	}
	sort.Slice(symbols, func(i, j int) bool { return symbols[i].Label < symbols[j].Label })
	parts := make([]string, len(symbols))
	for i, sym := range symbols {
		prefix := ""
		if sym.Deprecated {
			prefix = "⚠️ "
		}
		label := sym.Label
		if sym.Path != "" && sym.Line > 0 {
			label = fmt.Sprintf("[`%s`](../%s#L%d)", sym.Label, sym.Path, sym.Line)
		}
		parts[i] = prefix + label
	}
	return strings.Join(parts, "<br>")
}

func formatFileTest(path string, exists bool) string {
	if !exists || path == "" {
		return "—"
	}
	return fmt.Sprintf("[`%s`](../%s)", path, path)
}

func formatTests(tests []string) string {
	if len(tests) == 0 {
		return "—"
	}
	sort.Strings(tests)
	links := make([]string, len(tests))
	for i, test := range tests {
		links[i] = fmt.Sprintf("[`%s`](../%s)", test, test)
	}
	return strings.Join(links, "<br>")
}

func dedicatedTestFor(libPath string) string {
	if !strings.HasPrefix(libPath, "lib/") {
		return ""
	}
	if !strings.HasSuffix(libPath, ".dart") {
		return ""
	}
	rel := strings.TrimSuffix(strings.TrimPrefix(libPath, "lib/"), ".dart")
	if rel == "" {
		return ""
	}
	return fmt.Sprintf("test/%s_test.dart", rel)
}

func hasFile(root, relPath string) bool {
	if relPath == "" {
		return false
	}
	abs := filepath.Join(root, filepath.FromSlash(relPath))
	info, err := os.Stat(abs)
	if err != nil {
		return false
	}
	return !info.IsDir()
}

func filterRelatedTests(tests []string, dedicated string) []string {
	if len(tests) == 0 {
		return nil
	}
	filtered := make([]string, 0, len(tests))
	seen := make(map[string]struct{}, len(tests))
	for _, test := range tests {
		if test == dedicated {
			continue
		}
		if _, ok := seen[test]; ok {
			continue
		}
		seen[test] = struct{}{}
		filtered = append(filtered, test)
	}
	if len(filtered) == 0 {
		return nil
	}
	return filtered
}

func resolveURI(root, fromPath, uri string) (string, error) {
	if strings.HasPrefix(uri, "dart:") {
		return "", nil
	}
	if strings.HasPrefix(uri, "package:pulse/") {
		target := filepath.Join(root, "lib", filepath.FromSlash(strings.TrimPrefix(uri, "package:pulse/")))
		return ensureRel(root, target)
	}
	if strings.HasPrefix(uri, "package:") {
		return "", nil
	}
	target := filepath.Join(filepath.Dir(fromPath), filepath.FromSlash(uri))
	return ensureRel(root, target)
}

func ensureRel(root, target string) (string, error) {
	clean := filepath.Clean(target)
	if !strings.HasPrefix(clean, root) {
		return "", nil
	}
	info, err := os.Stat(clean)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return "", nil
		}
		return "", err
	}
	if info.IsDir() {
		return "", nil
	}
	if filepath.Ext(clean) != ".dart" {
		return "", nil
	}
	rel := filepath.ToSlash(relPath(root, clean))
	return rel, nil
}

func relPath(root, target string) string {
	rel, err := filepath.Rel(root, target)
	if err != nil {
		return target
	}
	return rel
}

func dumpList(items []string) {
	sort.Strings(items)
	for _, item := range items {
		fmt.Printf("  - %s\n", item)
	}
}

func toSortedSlice(set map[string]struct{}) []string {
	if len(set) == 0 {
		return nil
	}
	slice := make([]string, 0, len(set))
	for item := range set {
		slice = append(slice, item)
	}
	sort.Strings(slice)
	return slice
}
