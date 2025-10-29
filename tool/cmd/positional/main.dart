import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';

class PositionalEntry {
  PositionalEntry({
    required this.path,
    required this.line,
    required this.signature,
    required this.parameters,
  });

  final String path;
  final int line;
  final String signature;
  final List<String> parameters;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'path': path,
      'line': line,
      'signature': signature,
      'parameters': parameters,
    };
  }
}

class _Collector extends RecursiveAstVisitor<void> {
  _Collector(this.path, this.lineInfo);

  final String path;
  final LineInfo lineInfo;
  final List<PositionalEntry> entries = <PositionalEntry>[];

  void _record(
    String signature,
    FormalParameterList? parameters,
    AstNode node,
  ) {
    if (parameters == null) {
      return;
    }
    final List<String> positional = <String>[];
    for (final FormalParameter parameter in parameters.parameters) {
      if (parameter.isNamed) {
        continue;
      }
      positional.add(parameter.toSource());
    }
    if (positional.isEmpty) {
      return;
    }
    final int line = lineInfo.getLocation(node.offset).lineNumber;
    entries.add(
      PositionalEntry(
        path: path,
        line: line,
        signature: signature,
        parameters: positional,
      ),
    );
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    final String name = node.name.lexeme;
    _record(name, node.functionExpression.parameters, node);
    super.visitFunctionDeclaration(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    final ClassDeclaration? enclosingClass = node
        .thisOrAncestorOfType<ClassDeclaration>();
    final String className = enclosingClass?.name.lexeme ?? '<unknown>';
    final String methodName = node.name.lexeme;
    final String signature = '$className.$methodName';
    _record(signature, node.parameters, node);
    super.visitMethodDeclaration(node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    final ClassDeclaration? enclosingClass = node
        .thisOrAncestorOfType<ClassDeclaration>();
    if (enclosingClass == null) {
      return;
    }
    final String className = enclosingClass.name.lexeme;
    final String constructorName = node.name?.lexeme ?? '';
    final String signature = constructorName.isEmpty
        ? className
        : '$className.$constructorName';
    _record(signature, node.parameters, node);
    super.visitConstructorDeclaration(node);
  }
}

Future<void> main(List<String> args) async {
  final Directory root = Directory('lib');
  if (!root.existsSync()) {
    stderr.writeln('lib/ directory not found');
    exit(1);
  }

  String format = 'json';
  for (final String arg in args) {
    if (arg == '--markdown') {
      format = 'markdown';
    } else if (arg.startsWith('--format=')) {
      format = arg.substring('--format='.length);
    }
  }

  final List<PositionalEntry> allEntries = <PositionalEntry>[];
  final List<File> dartFiles =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((File file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((File a, File b) => a.path.compareTo(b.path));

  for (final File file in dartFiles) {
    final result = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
    );
    final _Collector collector = _Collector(file.path, result.lineInfo);
    result.unit.accept(collector);
    allEntries.addAll(collector.entries);
  }

  if (format == 'markdown') {
    final Map<String, List<PositionalEntry>> byFile =
        <String, List<PositionalEntry>>{};
    for (final PositionalEntry entry in allEntries) {
      byFile.putIfAbsent(entry.path, () => <PositionalEntry>[]).add(entry);
    }

    final StringBuffer buffer = StringBuffer();
    final int entryCount = allEntries.length;
    buffer.writeln('# Positional parameter inventory');
    buffer.writeln();
    buffer.writeln(
      '_Generated on ${DateTime.now().toUtc().toIso8601String()} using `tool/cmd/positional/main.dart`._',
    );
    buffer.writeln();
    buffer.writeln('- Total positional parameters: $entryCount');
    buffer.writeln(
      '- Files containing positional parameters: ${byFile.length}',
    );
    buffer.writeln();

    final List<String> fileOrder = byFile.keys.toList()..sort();
    for (final String path in fileOrder) {
      final List<PositionalEntry> entries = List<PositionalEntry>.from(
        byFile[path]!,
      );
      entries.sort(
        (PositionalEntry a, PositionalEntry b) => a.line.compareTo(b.line),
      );
      buffer.writeln('## $path');
      buffer.writeln();
      for (final PositionalEntry entry in entries) {
        final String params = entry.parameters
            .map((String param) => '`$param`')
            .join(', ');
        buffer.writeln('- `${entry.signature}` (line ${entry.line}): $params');
      }
      buffer.writeln();
    }
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln(
      'To regenerate this report, run `dart run tool/cmd/positional/main.dart --markdown > docs/positional.md`.',
    );
    stdout.writeln(buffer.toString());
  } else {
    final List<Map<String, Object?>> payload = allEntries
        .map((PositionalEntry entry) => entry.toJson())
        .toList();
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(payload));
  }
}
