package main

import "testing"

func TestFindTestsMissingIntentCommentLinesHonorsComments(t *testing.T) {
	content := `// Ensures the widget uses theme defaults.

testWidgets('applies theme', (tester) async {});
`
	if got := findTestsMissingIntentCommentLines(content); len(got) != 0 {
		t.Fatalf("expected no missing comments, got %v", got)
	}
}

func TestFindTestsMissingIntentCommentLinesDetectsMissing(t *testing.T) {
	content := `test('first scenario', () {});
// Explains why the widget test matters.
testWidgets('second scenario', (tester) async {});
`
	got := findTestsMissingIntentCommentLines(content)
	if len(got) != 1 {
		t.Fatalf("expected 1 missing comment, got %v", got)
	}
	if got[0] != 1 {
		t.Fatalf("expected missing comment on line 1, got %d", got[0])
	}
}

func TestFindTestsMissingIntentCommentLinesHandlesBlockComments(t *testing.T) {
	content := `/*
	Multi-line context for the test.
	*/

test('uses block comment', () {});
`
	if got := findTestsMissingIntentCommentLines(content); len(got) != 0 {
		t.Fatalf("expected no missing comments, got %v", got)
	}
}

func TestFindTestsMissingIntentCommentLinesSupportsGenerics(t *testing.T) {
	content := `// Generic widget intent.

testWidgets<MyHarness>('generic widget scenario', (tester) async {});

test('lacks explanation', () {});
`
	got := findTestsMissingIntentCommentLines(content)
	if len(got) != 1 {
		t.Fatalf("expected 1 missing comment, got %v", got)
	}
	if got[0] != 5 {
		t.Fatalf("expected missing comment on line 5, got %d", got[0])
	}
}
