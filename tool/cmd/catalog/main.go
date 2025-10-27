package main

import (
	"errors"
	"fmt"
	"html"
	"io/fs"
	"math"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"
)

type symbol struct {
	Label      string
	Name       string
	Deprecated bool
	Path       string
	Line       int
}

type entry struct {
	PublicTypes   []symbol
	PrivateTypes  []symbol
	PublicFuncs   []symbol
	PrivateFuncs  []symbol
	Tests         []string
	HasContent    bool
	HasDeprecated bool
}

type catalogRow struct {
	Path            string
	Status          string
	Entry           *entry
	DedicatedPath   string
	DedicatedExists bool
	RelatedTests    []string
}

type typeMatcher struct {
	pattern       *regexp.Regexp
	nameExtractor func(content string, match []int) string
}

var (
	mainColumnClasses = []string{
		"col-status",
		"col-file",
		"col-public-types",
		"col-private-types",
		"col-public-funcs",
		"col-private-funcs",
		"col-file-test",
		"col-related-tests",
	}
	mainColumnHeaders = []string{
		" 📋 ",
		"File",
		"Public types",
		"Private types",
		"Public functions",
		"Private functions",
		"File test",
		"Related tests",
	}
	qualityColumnClasses = []string{
		"col-quality-intent",
		"col-quality-stray",
		"col-quality-todo",
		"col-quality-duplicate",
	}
	qualityColumnHeaders = []string{
		"Intent",
		"Stray",
		"TODO",
		"Duplicate",
	}
	qualityDescriptions = []string{
		"Add a brief intent comment to each test or testWidgets block so future readers know what it covers.",
		"Mirror the lib/ path (e.g., lib/foo/bar.dart → test/foo/bar_test.dart) and import the target file to keep tests discoverable.",
		"Only uppercase 'TODO' in block comments or leading '//' comment lines are recognized; inline comments are ignored.",
		"Consider consolidating helpers that share a signature or renaming them to highlight their intent.",
	}
)

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

func main() {
	root, err := os.Getwd()
	if err != nil {
		fatal(err)
	}

	catalog, unused, deprecated, emptyDirs, unexpected, missingComments, err := buildLibraryCatalog(root)
	if err != nil {
		fatal(err)
	}
	catalog = ensureTrailingNewline(catalog)

	docPath := filepath.Join(root, "docs", "catalog.md")
	if err := os.WriteFile(docPath, []byte(catalog), 0o600); err != nil {
		fatal(err)
	}
	fmt.Printf("catalog written to %s\n", docPath)

	if len(unused) > 0 || len(deprecated) > 0 || len(emptyDirs) > 0 || len(unexpected) > 0 || len(missingComments) > 0 {
		if len(unused) > 0 {
			fmt.Printf("unused files (%d):\n", len(unused))
			printList(unused)
		}
		if len(deprecated) > 0 {
			fmt.Printf("files with deprecated symbols (%d):\n", len(deprecated))
			printList(deprecated)
		}
		if len(emptyDirs) > 0 {
			fmt.Printf("empty directories (%d):\n", len(emptyDirs))
			printList(emptyDirs)
		}
		if len(unexpected) > 0 {
			fmt.Printf("unexpected files (%d):\n", len(unexpected))
			printList(unexpected)
		}
		if len(missingComments) > 0 {
			fmt.Printf("tests missing intent comments (%d):\n", len(missingComments))
			printList(missingComments)
		}
		os.Exit(1)
	}
}

func fatal(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(2)
}

func buildLibraryCatalog(root string) (string, []string, []string, []string, []string, []string, error) {
	// perform a single-pass scan over lib/ and test/ to gather all needed data
	entries, usage, libTests, strayTests, missingComments, duplicateFunctions, todos, emptyDirs, unexpectedFiles, err := scanProjectDirectories(root, []string{"lib", "test"})
	if err != nil {
		return "", nil, nil, nil, nil, nil, err
	}

	paths := make([]string, 0, len(entries))
	for path := range entries {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	rows := make([]catalogRow, 0, len(paths))
	mainMaxLines := make([]float64, len(mainColumnClasses))
	unusedSet := make(map[string]struct{})
	deprecatedSet := make(map[string]struct{})

	for _, path := range paths {
		entry := entries[path]
		dedicatedPath := deriveDedicatedTestPath(path)
		dedicatedExists := fileExists(root, dedicatedPath)
		tests := excludeDedicatedTest(libTests[path], dedicatedPath)
		testsCopy := append([]string(nil), tests...)
		statuses := make([]string, 0, 3)

		if !usage[path] || !entry.HasContent {
			statuses = append(statuses, "🪦")
			unusedSet[path] = struct{}{}
		}
		if entry.HasDeprecated {
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

		rows = append(rows, catalogRow{
			Path:            path,
			Status:          statusCell,
			Entry:           entry,
			DedicatedPath:   dedicatedPath,
			DedicatedExists: dedicatedExists,
			RelatedTests:    testsCopy,
		})

		updateMaxWidth(mainMaxLines, 1, []string{path})
		updateMaxWidth(mainMaxLines, 2, symbolLines(entry.PublicTypes))
		updateMaxWidth(mainMaxLines, 3, symbolLines(entry.PrivateTypes))
		updateMaxWidth(mainMaxLines, 4, symbolLines(entry.PublicFuncs))
		updateMaxWidth(mainMaxLines, 5, symbolLines(entry.PrivateFuncs))
		if dedicatedExists {
			updateMaxWidth(mainMaxLines, 6, []string{dedicatedPath})
		} else {
			updateMaxWidth(mainMaxLines, 6, nil)
		}
		updateMaxWidth(mainMaxLines, 7, linesFromStrings(testsCopy))
	}

	mainMaxLines[0] = float64(utf8.RuneCountInString(mainColumnHeaders[0]))

	mainPercents := computeMainColumnPercents(mainMaxLines)
	qualityPercents := computeQualityColumnPercents(missingComments, strayTests, todos, duplicateFunctions)

	var builder strings.Builder
	builder.WriteString("<div style=\"font-size:2em;font-weight:bold;margin-bottom:0.5em;\">Library Catalog</div>\n\n")
	builder.WriteString(
		fmt.Sprintf("Generated on %s by `go run ./tool/cmd/catalog`.\n\n", time.Now().UTC().Format("2006-01-02 15:04 UTC")),
	)

	startOuterTableWrapper(&builder)
	startInnerTable(&builder, "catalog-table")
	writeTableColumns(&builder, mainColumnClasses, mainPercents)
	writeCatalogHeader(&builder)

	for _, row := range rows {
		entry := row.Entry
		publicTypeCell := formatSymbolsAsHTML(entry.PublicTypes)
		privateTypeCell := formatSymbolsAsHTML(entry.PrivateTypes)
		publicCell := formatSymbolsAsHTML(entry.PublicFuncs)
		privateCell := formatSymbolsAsHTML(entry.PrivateFuncs)
		fileTestCell := formatDedicatedTestAsHTML(row.DedicatedPath, row.DedicatedExists)
		testCell := formatRelatedTestsAsHTML(row.RelatedTests)
		fmt.Fprintf(&builder, `        <tr>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
        </tr>
`,
			html.EscapeString(row.Status),
			formatCodeLinkHTML(row.Path, row.Path, 0),
			publicTypeCell,
			privateTypeCell,
			publicCell,
			privateCell,
			fileTestCell,
			testCell,
		)
	}
	builder.WriteString("        </tbody>\n      </table>\n")

	// place the quality table in a second row so both tables share the same outer width
	addOuterTableRow(&builder)
	writeQualityTableColumns(&builder, qualityPercents, missingComments, strayTests, todos, duplicateFunctions)
	endOuterTableWrapper(&builder)

	if len(strayTests) > 0 {
		fmt.Printf("warning: %d stray test files found\n", len(strayTests))
	}
	if len(duplicateFunctions) > 0 {
		fmt.Printf("warning: %d possible duplicate function signatures found\n", len(duplicateFunctions))
	}

	return builder.String(), sortedSliceFromSet(unusedSet), sortedSliceFromSet(deprecatedSet), emptyDirs, unexpectedFiles, missingComments, nil
}

func writeQualityTableColumns(builder *strings.Builder, percents []float64, missing, stray, todos []string, duplicates map[string][]string) {
	builder.WriteString(`      <table class="catalog-quality" style="width:100%">
        <colgroup>
`)
	for i, className := range qualityColumnClasses {
		width := 0.0
		if i < len(percents) {
			width = percents[i]
		}
		fmt.Fprintf(builder, "          <col class=\"%s\" style=\"width: %.2f%%\">\n", className, width)
	}
	builder.WriteString(`        </colgroup>
        <thead>
          <tr>
            <th scope="col">Intent</th>
            <th scope="col">Stray</th>
            <th scope="col">TODO</th>
            <th scope="col">Duplicate</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td><em>Add a brief intent comment to each <code>test</code> or <code>testWidgets</code> block so future readers know what it covers.</em></td>
            <td><em>Mirror the <code>lib/</code> path (e.g., <code>lib/foo/bar.dart</code> → <code>test/foo/bar_test.dart</code>) and import the target file to keep tests discoverable.</em></td>
            <td><em>Only uppercase 'TODO' in block comments or leading '//' comment lines are recognized; inline comments are ignored.</em></td>
            <td><em>Consider consolidating helpers that share a signature or renaming them to highlight their intent.</em></td>
          </tr>
`)

	intentDetails := formatQualityCell(formatPathWithLineLinks(missing))
	strayDetails := formatQualityCell(formatStrayTestLinks(stray))
	todoDetails := formatQualityCell(formatPathWithLineLinks(todos))
	duplicateDetails := formatQualityCell(formatDuplicateDetailsHTML(duplicates))

	fmt.Fprintf(builder, `          <tr>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
            <td>%s</td>
          </tr>
        </tbody>
      </table>
`, intentDetails, strayDetails, todoDetails, duplicateDetails)
}

func formatPathWithLineLinks(items []string) string {
	if len(items) == 0 {
		return ""
	}
	sorted := append([]string(nil), items...)
	sort.Strings(sorted)
	parts := make([]string, 0, len(sorted))
	for _, entry := range sorted {
		path, line := parsePathAndLine(entry)
		link := formatCodeLinkHTML(path, path, line)
		if line > 0 {
			parts = append(parts, fmt.Sprintf("%s — line %d", link, line))
			continue
		}
		parts = append(parts, link)
	}
	return strings.Join(parts, "<br>")
}

func formatStrayTestLinks(stray []string) string {
	if len(stray) == 0 {
		return ""
	}
	sorted := append([]string(nil), stray...)
	sort.Strings(sorted)
	parts := make([]string, 0, len(sorted))
	for _, testPath := range sorted {
		parts = append(parts, formatCodeLinkHTML(testPath, testPath, 0))
	}
	return strings.Join(parts, "<br>")
}

func formatDuplicateDetailsHTML(duplicates map[string][]string) string {
	if len(duplicates) == 0 {
		return ""
	}
	signatures := make([]string, 0, len(duplicates))
	for signature := range duplicates {
		signatures = append(signatures, signature)
	}
	sort.Strings(signatures)
	var b strings.Builder
	for i, signature := range signatures {
		if i > 0 {
			b.WriteString("<br>")
		}
		fmt.Fprintf(&b, "<code>%s</code>", html.EscapeString(signature))
		locations := append([]string(nil), duplicates[signature]...)
		sort.Strings(locations)
		for _, location := range locations {
			path, line := parsePathAndLine(location)
			b.WriteString("<br>&nbsp;&nbsp;")
			b.WriteString(formatCodeLinkHTML(path, path, line))
		}
	}
	return b.String()
}

func formatCodeLinkHTML(label, path string, line int) string {
	escapedLabel := html.EscapeString(label)
	if path == "" {
		return fmt.Sprintf("<code>%s</code>", escapedLabel)
	}
	escapedPath := html.EscapeString(path)
	if line > 0 {
		return fmt.Sprintf("<a href=\"../%s#L%d\"><code>%s</code></a>", escapedPath, line, escapedLabel)
	}
	return fmt.Sprintf("<a href=\"../%s\"><code>%s</code></a>", escapedPath, escapedLabel)
}

func formatQualityCell(content string) string {
	if strings.TrimSpace(content) == "" {
		return `<span aria-hidden="true">&nbsp;</span>`
	}
	return content
}

func scanProjectDirectories(root string, anchors []string) (map[string]*entry, map[string]bool, map[string][]string, []string, []string, map[string][]string, []string, []string, []string, error) {
	entries := make(map[string]*entry)
	usage := make(map[string]bool)
	// seeds for usage
	usage["lib/main.dart"] = true
	usage["lib/development/main.dart"] = true
	libTests := make(map[string][]string)
	signatures := make(map[string][]string)
	var stray []string
	var missing []string
	todosSeen := make(map[string]struct{})
	var unexpected []string
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
			if d.IsDir() {
				entries, err := os.ReadDir(path)
				if err != nil {
					return err
				}
				if len(entries) == 0 {
					emptySet[filepath.ToSlash(relativePath(root, path))] = struct{}{}
				}
				return nil
			}
			rel := filepath.ToSlash(relativePath(root, path))
			if filepath.Ext(path) != ".dart" {
				if anchor == "lib" {
					unexpected = append(unexpected, rel)
				}
				return nil
			}
			contentBytes, err := os.ReadFile(path)
			if err != nil {
				return err
			}
			content := string(contentBytes)

			// imports / parts / part of
			matches := importPattern.FindAllStringSubmatch(content, -1)
			for _, m := range matches {
				uri := m[1]
				target, err := resolveImportURI(root, path, uri)
				if err != nil {
					return err
				}
				if target != "" {
					usage[target] = true
				}
			}
			parts := partPattern.FindAllStringSubmatch(content, -1)
			for _, m := range parts {
				target, err := resolveImportURI(root, path, m[1])
				if err != nil {
					return err
				}
				if target != "" {
					usage[target] = true
				}
			}
			partOfs := partOfPattern.FindAllStringSubmatch(content, -1)
			for _, m := range partOfs {
				if trimmed, ok := strings.CutPrefix(m[1], "package:pulse/"); ok {
					relt := filepath.ToSlash(filepath.Join("lib", trimmed))
					usage[relt] = true
					continue
				}
				target, err := resolveImportURI(root, path, m[1])
				if err != nil {
					return err
				}
				if target != "" {
					usage[target] = true
				}
			}

			// collect duplicate function signatures
			matchesIdx := functionPattern.FindAllStringSubmatchIndex(content, -1)
			if len(matchesIdx) > 0 {
				for _, m := range matchesIdx {
					returnSegment := strings.TrimSpace(content[m[2]:m[3]])
					if skipFunctionByKeyword(returnSegment) {
						continue
					}
					signature := strings.TrimSpace(content[m[0]:m[1]])
					signature = strings.TrimSuffix(signature, "{")
					signature = strings.TrimSpace(signature)
					signature = strings.TrimSuffix(signature, "=>")
					signature = strings.TrimSpace(signature)
					signature = collapseWhitespace(signature)
					if signature == "" {
						continue
					}
					line := 1 + strings.Count(content[:m[0]], "\n")
					location := fmt.Sprintf("%s:%d", rel, line)
					signatures[signature] = append(signatures[signature], location)
				}
			}

			// collect library symbols
			if anchor == "lib" {
				e := &entry{}
				if pub, priv := collectSymbols(content, rel, classPattern); len(pub) > 0 || len(priv) > 0 {
					e.PublicTypes = append(e.PublicTypes, pub...)
					e.PrivateTypes = append(e.PrivateTypes, priv...)
				}
				if pub, priv := collectSymbols(content, rel, mixinPattern); len(pub) > 0 || len(priv) > 0 {
					e.PublicTypes = append(e.PublicTypes, pub...)
					e.PrivateTypes = append(e.PrivateTypes, priv...)
				}
				if pub, priv := collectSymbols(content, rel, enumPattern); len(pub) > 0 || len(priv) > 0 {
					e.PublicTypes = append(e.PublicTypes, pub...)
					e.PrivateTypes = append(e.PrivateTypes, priv...)
				}
				if pub, priv := collectSymbols(content, rel, typedefPattern); len(pub) > 0 || len(priv) > 0 {
					e.PublicTypes = append(e.PublicTypes, pub...)
					e.PrivateTypes = append(e.PrivateTypes, priv...)
				}
				if pub, priv := collectExtensionSymbols(content, rel, extensionPattern, true); len(pub) > 0 || len(priv) > 0 {
					e.PublicTypes = append(e.PublicTypes, pub...)
					e.PrivateTypes = append(e.PrivateTypes, priv...)
				}
				if pub, priv := collectExtensionSymbols(content, rel, extensionTypePattern, false); len(pub) > 0 || len(priv) > 0 {
					e.PublicTypes = append(e.PublicTypes, pub...)
					e.PrivateTypes = append(e.PrivateTypes, priv...)
				}
				e.PublicFuncs, e.PrivateFuncs = collectFunctionSymbols(content, rel)
				e.HasContent = hasNonCommentContent(content)
				for _, group := range [][]symbol{e.PublicTypes, e.PrivateTypes, e.PublicFuncs, e.PrivateFuncs} {
					for _, sym := range group {
						if sym.Deprecated {
							e.HasDeprecated = true
							break
						}
					}
					if e.HasDeprecated {
						break
					}
				}
				entries[rel] = e
			}

			// test mappings and missing intent comments
			if anchor == "test" && strings.HasSuffix(path, "_test.dart") {
				relTest := rel
				missingLines := findTestsMissingIntentLines(content)
				if len(missingLines) > 0 {
					for _, line := range missingLines {
						missing = append(missing, fmt.Sprintf("%s:%d", relTest, line))
					}
				}
				hasLibImport := false
				matchedDedicated := false
				imports := importPattern.FindAllStringSubmatch(content, -1)
				for _, m := range imports {
					target, err := resolveImportURI(root, path, m[1])
					if err != nil {
						return err
					}
					if target == "" {
						continue
					}
					if !strings.HasPrefix(target, "lib/") {
						continue
					}
					libTests[target] = append(libTests[target], relTest)
					hasLibImport = true
					if dedicated := deriveDedicatedTestPath(target); dedicated != "" && relTest == dedicated {
						matchedDedicated = true
					}
				}
				if !hasLibImport || !matchedDedicated {
					stray = append(stray, relTest)
				}
			}

			// todos in comments
			for _, idx := range blockCommentPattern.FindAllStringIndex(content, -1) {
				start := idx[0]
				block := content[idx[0]:idx[1]]
				off := 0
				for {
					pos := strings.Index(block[off:], "TODO")
					if pos == -1 {
						break
					}
					abs := start + off + pos
					line := 1 + strings.Count(content[:abs], "\n")
					entry := fmt.Sprintf("%s:%d", rel, line)
					todosSeen[entry] = struct{}{}
					off += pos + 4
				}
			}
			for _, idx := range lineCommentPattern.FindAllStringIndex(content, -1) {
				comment := content[idx[0]:idx[1]]
				if strings.Contains(comment, "TODO") {
					line := 1 + strings.Count(content[:idx[0]], "\n")
					entry := fmt.Sprintf("%s:%d", rel, line)
					todosSeen[entry] = struct{}{}
				}
			}

			return nil
		})
		if err != nil {
			if errors.Is(err, fs.ErrNotExist) {
				continue
			}
			return nil, nil, nil, nil, nil, nil, nil, nil, nil, err
		}
	}

	// build duplicates map
	duplicates := make(map[string][]string)
	for sig, locs := range signatures {
		if len(locs) > 1 {
			duplicates[sig] = locs
		}
	}

	// collect todos into a sorted slice
	todos := make([]string, 0, len(todosSeen))
	for t := range todosSeen {
		todos = append(todos, t)
	}
	sort.Strings(todos)

	sort.Strings(unexpected)

	// build empty directories slice
	emptyDirs := make([]string, 0, len(emptySet))
	for e := range emptySet {
		emptyDirs = append(emptyDirs, e)
	}
	sort.Strings(emptyDirs)

	return entries, usage, libTests, stray, missing, duplicates, todos, emptyDirs, unexpected, nil
}

func findTestsMissingIntentLines(content string) []int {
	lines := strings.Split(content, "\n")
	var missing []int
	for idx, line := range lines {
		if !testInvocationPattern.MatchString(strings.TrimSpace(line)) {
			continue
		}
		if hasPrecedingIntentComment(lines, idx) {
			continue
		}
		missing = append(missing, idx+1)
	}
	return missing
}

func hasPrecedingIntentComment(lines []string, index int) bool {
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

func parsePathAndLine(entry string) (string, int) {
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

func collapseWhitespace(s string) string {
	if s == "" {
		return s
	}
	return strings.Join(strings.Fields(s), " ")
}

func collectSymbols(content, path string, pattern *regexp.Regexp) ([]symbol, []symbol) {
	matches := pattern.FindAllStringSubmatchIndex(content, -1)
	var public []symbol
	var private []symbol
	for _, m := range matches {
		keyword := strings.TrimSpace(content[m[2]:m[3]])
		name := strings.TrimSpace(content[m[4]:m[5]])
		label := fmt.Sprintf("%s %s", keyword, name)
		line := 1 + strings.Count(content[:m[0]], "\n")
		sym := symbol{
			Label:      label,
			Name:       name,
			Deprecated: isSymbolDeprecated(content, m[0]),
			Path:       path,
			Line:       line,
		}
		if strings.HasPrefix(name, "_") {
			private = append(private, sym)
			continue
		}
		public = append(public, sym)
	}
	return public, private
}

func collectExtensionSymbols(content, path string, pattern *regexp.Regexp, includeOn bool) ([]symbol, []symbol) {
	submatches := pattern.FindAllStringSubmatchIndex(content, -1)
	var public []symbol
	var private []symbol
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
		line := 1 + strings.Count(content[:m[0]], "\n")
		sym := symbol{
			Label:      label,
			Name:       name,
			Deprecated: isSymbolDeprecated(content, m[0]),
			Path:       path,
			Line:       line,
		}
		if name != "" && strings.HasPrefix(name, "_") {
			private = append(private, sym)
			continue
		}
		public = append(public, sym)
	}
	return public, private
}

func collectFunctionSymbols(content, path string) ([]symbol, []symbol) {
	matches := functionPattern.FindAllStringSubmatchIndex(content, -1)
	var public []symbol
	var private []symbol
	for _, m := range matches {
		returnSegment := strings.TrimSpace(content[m[2]:m[3]])
		if skipFunctionByKeyword(returnSegment) {
			continue
		}
		name := strings.TrimSpace(content[m[4]:m[5]])
		if name == "" {
			continue
		}
		line := 1 + strings.Count(content[:m[0]], "\n")
		context := findEnclosingTypeContext(content, m[0])
		label := formatFunctionLabel(context, name)
		sym := symbol{
			Label:      label,
			Name:       name,
			Deprecated: isSymbolDeprecated(content, m[0]),
			Path:       path,
			Line:       line,
		}
		isPrivate := isFunctionPrivate(context, name, content, m[0])
		if isPrivate {
			private = append(private, sym)
			continue
		}
		public = append(public, sym)
	}
	return public, private
}

func skipFunctionByKeyword(prefix string) bool {
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

func formatFunctionLabel(context, name string) string {
	label := name + "()"
	if context == "" {
		return label
	}
	return context + "." + label
}

func isFunctionPrivate(context, name, content string, start int) bool {
	if strings.HasPrefix(name, "_") {
		return true
	}
	if context != "" {
		base := context
		if idx := strings.IndexAny(base, " <"); idx >= 0 {
			base = base[:idx]
		}
		base = strings.TrimSpace(base)
		if strings.HasPrefix(base, "_") {
			return true
		}
	}
	if context == "" && isFunctionLocal(content, start) {
		return true
	}
	return false
}

func isFunctionLocal(content string, start int) bool {
	idx := start
	for idx < len(content) {
		ch := content[idx]
		if ch == '\r' || ch == '\n' {
			idx++
			continue
		}
		return ch == ' ' || ch == '\t'
	}
	return false
}

func findEnclosingTypeContext(content string, index int) string {
	bestName := ""
	bestStart := -1
	for _, matcher := range typeMatchers {
		matches := matcher.pattern.FindAllStringSubmatchIndex(content[:index], -1)
		for _, m := range matches {
			name := matcher.nameExtractor(content, m)
			if name == "" {
				continue
			}
			openIdx := findOpeningBrace(content, m[1], index)
			if openIdx == -1 {
				continue
			}
			if !isWithinBlock(content, openIdx, index) {
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

func findOpeningBrace(content string, start, limit int) int {
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

func isWithinBlock(content string, openIdx, target int) bool {
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
			i = skipStringLiteral(content, i)
		case '"':
			i = skipStringLiteral(content, i)
		case '/':
			if i+1 < len(content) {
				next := content[i+1]
				if next == '/' {
					i = skipSingleLineComment(content, i)
					continue
				}
				if next == '*' {
					i = skipMultiLineComment(content, i)
					continue
				}
			}
		}
	}
	return depth > 0
}

func skipStringLiteral(content string, start int) int {
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

func skipSingleLineComment(content string, start int) int {
	i := start + 2
	for i < len(content) && content[i] != '\n' {
		i++
	}
	return i
}

func skipMultiLineComment(content string, start int) int {
	i := start + 2
	for i+1 < len(content) {
		if content[i] == '*' && content[i+1] == '/' {
			return i + 1
		}
		i++
	}
	return len(content) - 1
}

func isSymbolDeprecated(content string, start int) bool {
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

func hasNonCommentContent(content string) bool {
	withoutBlocks := blockCommentPattern.ReplaceAllString(content, "")
	withoutLines := lineCommentPattern.ReplaceAllString(withoutBlocks, "")
	return strings.TrimSpace(withoutLines) != ""
}

func updateMaxWidth(maxLines []float64, idx int, lines []string) {
	if idx < 0 || idx >= len(maxLines) {
		return
	}
	if len(lines) == 0 {
		lines = []string{"—"}
	}
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		length := float64(utf8.RuneCountInString(trimmed))
		if length > maxLines[idx] {
			maxLines[idx] = length
		}
	}
}

func computeMainColumnPercents(maxLines []float64) []float64 {
	headerLens := headerWidths(mainColumnHeaders)
	base := make([]float64, len(maxLines))
	for i := range base {
		content := maxLines[i]
		if content == 0 {
			content = 1
		}
		if i == 0 {
			base[i] = headerLens[i]
			continue
		}
		base[i] = math.Max(headerLens[i], content)
	}
	return normalizeToPercentages(base, 2, true)
}

func headerWidths(headers []string) []float64 {
	lengths := make([]float64, len(headers))
	for i, header := range headers {
		lengths[i] = float64(utf8.RuneCountInString(header))
	}
	return lengths
}

func normalizeToPercentages(weights []float64, decimals int, excludeFirst bool) []float64 {
	if len(weights) == 0 {
		return nil
	}
	total := 0.0
	for _, weight := range weights {
		total += weight
	}
	if total == 0 {
		equal := 100.0 / float64(len(weights))
		percents := make([]float64, len(weights))
		for i := range percents {
			percents[i] = equal
		}
		return percents
	}
	multiplier := int(math.Pow10(decimals))
	targetUnits := 100 * multiplier
	units := make([]int, len(weights))
	fractions := make([]float64, len(weights))
	for i, weight := range weights {
		scaled := weight / total * float64(targetUnits)
		units[i] = int(math.Floor(scaled))
		fractions[i] = scaled - float64(units[i])
	}
	assigned := 0
	for _, unit := range units {
		assigned += unit
	}
	remainder := targetUnits - assigned
	indices := make([]int, 0, len(weights))
	start := 0
	if excludeFirst {
		start = 1
	}
	for i := start; i < len(weights); i++ {
		indices = append(indices, i)
	}
	if len(indices) == 0 {
		indices = append(indices, 0)
	}
	sort.SliceStable(indices, func(i, j int) bool {
		fi := fractions[indices[i]]
		fj := fractions[indices[j]]
		if fi == fj {
			return indices[i] < indices[j]
		}
		return fi > fj
	})
	idx := 0
	for remainder > 0 {
		current := indices[idx]
		units[current]++
		remainder--
		idx++
		if idx >= len(indices) {
			idx = 0
		}
	}
	percents := make([]float64, len(weights))
	sum := 0.0
	for i, unit := range units {
		percents[i] = float64(unit) / float64(multiplier)
		sum += percents[i]
	}
	// adjust the last column so the total is exactly 100.00%
	if len(percents) > 0 {
		diff := 100.0 - sum
		percents[len(percents)-1] += diff
	}
	return percents
}

func symbolLines(symbols []symbol) []string {
	if len(symbols) == 0 {
		return nil
	}
	lines := make([]string, len(symbols))
	for i, sym := range symbols {
		label := sym.Label
		if sym.Deprecated {
			label = "⚠️ " + label
		}
		lines[i] = label
	}
	return lines
}

func linesFromStrings(items []string) []string {
	if len(items) == 0 {
		return nil
	}
	return append([]string(nil), items...)
}

func computeQualityColumnPercents(missing, stray, todos []string, duplicates map[string][]string) []float64 {
	maxLines := make([]float64, len(qualityColumnClasses))
	detailGroups := [][]string{
		append([]string{qualityDescriptions[0]}, formatPathLineEntries(missing)...),
		append([]string{qualityDescriptions[1]}, formatStrayTestPaths(stray)...),
		append([]string{qualityDescriptions[2]}, formatPathLineEntries(todos)...),
		append([]string{qualityDescriptions[3]}, formatDuplicateEntries(duplicates)...),
	}
	for i, lines := range detailGroups {
		updateMaxWidth(maxLines, i, lines)
	}
	headerLens := headerWidths(qualityColumnHeaders)
	base := make([]float64, len(maxLines))
	for i := range base {
		content := maxLines[i]
		if content == 0 {
			content = 1
		}
		base[i] = math.Max(headerLens[i], content)
	}
	return normalizeToPercentages(base, 2, false)
}

func formatPathLineEntries(entries []string) []string {
	if len(entries) == 0 {
		return nil
	}
	sorted := append([]string(nil), entries...)
	sort.Strings(sorted)
	lines := make([]string, 0, len(sorted))
	for _, entry := range sorted {
		path, line := parsePathAndLine(entry)
		if line > 0 {
			lines = append(lines, fmt.Sprintf("%s — line %d", path, line))
			continue
		}
		lines = append(lines, path)
	}
	return lines
}

func formatStrayTestPaths(stray []string) []string {
	if len(stray) == 0 {
		return nil
	}
	sorted := append([]string(nil), stray...)
	sort.Strings(sorted)
	return sorted
}

func formatDuplicateEntries(duplicates map[string][]string) []string {
	if len(duplicates) == 0 {
		return nil
	}
	signatures := make([]string, 0, len(duplicates))
	for signature := range duplicates {
		signatures = append(signatures, signature)
	}
	sort.Strings(signatures)
	lines := make([]string, 0, len(duplicates))
	for _, signature := range signatures {
		lines = append(lines, signature)
		locations := append([]string(nil), duplicates[signature]...)
		sort.Strings(locations)
		for _, location := range locations {
			path, line := parsePathAndLine(location)
			if line > 0 {
				lines = append(lines, fmt.Sprintf("  %s:%d", path, line))
				continue
			}
			lines = append(lines, "  "+path)
		}
	}
	return lines
}

func formatSymbolsAsHTML(symbols []symbol) string {
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
		parts[i] = prefix + formatCodeLinkHTML(sym.Label, sym.Path, sym.Line)
	}
	return strings.Join(parts, "<br>")
}

func formatDedicatedTestAsHTML(path string, exists bool) string {
	if !exists || path == "" {
		return "—"
	}
	return formatCodeLinkHTML(path, path, 0)
}

func formatRelatedTestsAsHTML(tests []string) string {
	if len(tests) == 0 {
		return "—"
	}
	sort.Strings(tests)
	links := make([]string, len(tests))
	for i, test := range tests {
		links[i] = formatCodeLinkHTML(test, test, 0)
	}
	return strings.Join(links, "<br>")
}

func deriveDedicatedTestPath(libPath string) string {
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

func fileExists(root, relPath string) bool {
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

func excludeDedicatedTest(tests []string, dedicated string) []string {
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

func resolveImportURI(root, fromPath, uri string) (string, error) {
	if strings.HasPrefix(uri, "dart:") {
		return "", nil
	}
	if trimmed, ok := strings.CutPrefix(uri, "package:pulse/"); ok {
		target := filepath.Join(root, "lib", filepath.FromSlash(trimmed))
		return ensureRelativePath(root, target)
	}
	if strings.HasPrefix(uri, "package:") {
		return "", nil
	}
	target := filepath.Join(filepath.Dir(fromPath), filepath.FromSlash(uri))
	return ensureRelativePath(root, target)
}

func ensureRelativePath(root, target string) (string, error) {
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
	rel := filepath.ToSlash(relativePath(root, clean))
	return rel, nil
}

func relativePath(root, target string) string {
	rel, err := filepath.Rel(root, target)
	if err != nil {
		return target
	}
	return rel
}

func printList(items []string) {
	sort.Strings(items)
	for _, item := range items {
		fmt.Printf("  - %s\n", item)
	}
}

func sortedSliceFromSet(set map[string]struct{}) []string {
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

func startOuterTableWrapper(b *strings.Builder) {
	b.WriteString("<table width=\"100%\" cellpadding=\"0\" cellspacing=\"0\" style=\"border-collapse:collapse;\">\n  <tr>\n    <td>\n")
}

func addOuterTableRow(b *strings.Builder) {
	b.WriteString("    </td>\n  </tr>\n  <tr>\n    <td>\n")
}

func endOuterTableWrapper(b *strings.Builder) {
	b.WriteString("    </td>\n  </tr>\n</table>\n")
}

func startInnerTable(b *strings.Builder, class string) {
	fmt.Fprintf(b, "      <table class=\"%s\" style=\"width:100%%\">\n", class)
}

func writeTableColumns(b *strings.Builder, classes []string, percents []float64) {
	b.WriteString("        <colgroup>\n")
	for i, className := range classes {
		width := 0.0
		if i < len(percents) {
			width = percents[i]
		}
		fmt.Fprintf(b, "          <col class=\"%s\" style=\"width: %.2f%%\">\n", className, width)
	}
	b.WriteString("        </colgroup>\n")
}

func writeCatalogHeader(b *strings.Builder) {
	b.WriteString("        <thead>\n          <tr>\n")
	b.WriteString("            <th scope=\"col\"> 📋 </th>\n")
	b.WriteString("            <th scope=\"col\">File</th>\n")
	b.WriteString("            <th scope=\"col\">Public types</th>\n")
	b.WriteString("            <th scope=\"col\">Private types</th>\n")
	b.WriteString("            <th scope=\"col\">Public functions</th>\n")
	b.WriteString("            <th scope=\"col\">Private functions</th>\n")
	b.WriteString("            <th scope=\"col\">File test</th>\n")
	b.WriteString("            <th scope=\"col\">Related tests</th>\n")
	b.WriteString("          </tr>\n        </thead>\n        <tbody>\n")
}

func ensureTrailingNewline(s string) string {
	trimmed := strings.TrimRight(s, "\n")
	if trimmed == "" {
		return "\n"
	}
	return trimmed + "\n"
}
