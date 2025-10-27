package main

import (
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

func TestRebuildImportBlockGroupsAndSpacing(t *testing.T) {
	entries := []importEntry{
		{
			lines: []string{"import 'dart:math';"},
			uri:   "dart:math",
			group: groupDart,
		},
		{
			lines: []string{"// widget", "import 'package:flutter/widgets.dart';"},
			uri:   "package:flutter/widgets.dart",
			group: groupFlutter,
		},
		{
			lines: []string{"import 'package:pulse/chart/node.dart';"},
			uri:   "package:pulse/chart/node.dart",
			group: groupPulse,
		},
		{
			lines: []string{"import 'package:third_party/uuid.dart';"},
			uri:   "package:third_party/uuid.dart",
			group: groupOther,
		},
	}

	got := rebuildImportBlock(entries)
	want := []string{
		"import 'dart:math';",
		"",
		"// widget",
		"import 'package:flutter/widgets.dart';",
		"",
		"import 'package:pulse/chart/node.dart';",
		"",
		"import 'package:third_party/uuid.dart';",
	}

	if !reflect.DeepEqual(got, want) {
		t.Fatalf("rebuildImportBlock() = %v, want %v", got, want)
	}
}

func TestCanonicalizeImportRelativeToCanonical(t *testing.T) {
	root := t.TempDir()
	filePath := filepath.Join(root, "lib", "chart", "bar.dart")
	if err := ensureDir(filepath.Dir(filePath)); err != nil {
		t.Fatalf("ensureDir: %v", err)
	}

	entry := importEntry{
		lines: []string{"import '../foundation.dart';"},
		uri:   "../foundation.dart",
		group: groupOther,
	}

	changed, err := canonicalizeImport(root, filePath, &entry)
	if err != nil {
		t.Fatalf("canonicalizeImport returned error: %v", err)
	}
	if !changed {
		t.Fatalf("expected canonicalizeImport to change URI")
	}

	wantLine := "import 'package:pulse/foundation.dart';"
	if len(entry.lines) != 1 || entry.lines[0] != wantLine {
		t.Fatalf("lines = %v, want %v", entry.lines, []string{wantLine})
	}
	if entry.uri != "package:pulse/foundation.dart" {
		t.Fatalf("uri = %q, want %q", entry.uri, "package:pulse/foundation.dart")
	}
	if entry.group != groupPulse {
		t.Fatalf("group = %v, want %v", entry.group, groupPulse)
	}
}

func TestCanonicalizeImportRejectsExternalPaths(t *testing.T) {
	root := t.TempDir()
	filePath := filepath.Join(root, "tool", "cmd", "import", "main.dart")
	if err := ensureDir(filepath.Dir(filePath)); err != nil {
		t.Fatalf("ensureDir: %v", err)
	}

	entry := importEntry{
		lines: []string{"import '../shared.dart';"},
		uri:   "../shared.dart",
		group: groupOther,
	}

	changed, err := canonicalizeImport(root, filePath, &entry)
	if err == nil {
		t.Fatalf("expected canonicalizeImport to error for non-lib relative path")
	}
	if changed {
		t.Fatalf("expected canonicalizeImport to report no change when error occurs")
	}
}

func TestDetectCycles(t *testing.T) {
	graph := make(dependencyGraph)
	graph.addEdge("lib/a.dart", "lib/b.dart")
	graph.addEdge("lib/b.dart", "lib/c.dart")
	graph.addEdge("lib/c.dart", "lib/a.dart")
	graph.addEdge("lib/d.dart", "lib/e.dart")

	cycles := detectCycles(graph)
	want := [][]string{
		{"lib/a.dart", "lib/b.dart", "lib/c.dart", "lib/a.dart"},
	}

	if len(cycles) != len(want) {
		t.Fatalf("cycles len = %d, want %d", len(cycles), len(want))
	}

	if !reflect.DeepEqual(cycles[0], want[0]) {
		t.Fatalf("cycles[0] = %v, want %v", cycles[0], want[0])
	}
}

func ensureDir(path string) error {
	return os.MkdirAll(path, 0o755)
}
