import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';

ArgResults argResults;

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('file', abbr: 'f')
    ..addOption('directory', abbr: 'd')
    ..addFlag('reverse', abbr: 'r')
    ..addFlag('hidden', abbr: 'h');

  argResults = parser.parse(arguments);

  stdout.writeln('keys file: ' + argResults['file']);
  stdout.writeln('directory: ' + argResults['directory']);

  var reversed = argResults['reverse'] as bool;
  var includeHidden = argResults['hidden'] as bool;

  var keysFilePath = argResults['file'];

  var keysMap = <String, String>{};

  var exp = RegExp(r'(\w*)=(.*)');

  final lines = utf8.decoder
      .bind(File(keysFilePath).openRead())
      .transform(const LineSplitter());
  try {
    await for (var line in lines) {
      var match = exp.firstMatch(line);
      stdout.writeln(match.group(1) + '=' + match.group(2));
      keysMap[match.group(1)] = match.group(2);
    }
  } catch (e) {
    stderr.writeln('error: $e');
  }

  var options = ReplacerOptions(keysMap, reversed, includeHidden);
  var replacer = KeysReplacer(options);

  await replacer.traverse(argResults['directory']);

  exitCode = 0;
}

class KeysReplacer {
  final ReplacerOptions options;

  KeysReplacer(this.options);

  void traverse(String path) async {
    var directory = Directory(path);

    if (await directory.exists()) {
      var entities =
          await directory.list(recursive: true, followLinks: false).toList();

      for (var entity in entities) {
        if (!options.includeHidden && entity.path.contains('/.')) {
          continue;
        }

        var stat = await entity.stat();

        if (stat.type == FileSystemEntityType.file) {
          processFile(entity);
        }
      }
    }
  }

  void processFile(FileSystemEntity entity) async {
    var file = File(entity.path);

    if (await file.exists()) {
      String contents;

      try {
        contents = await file.readAsString();
      } catch (e) {
        return;
      }

      var overwritten = false;

      for (var pair in options.keys.entries) {
        var key = options.reversedReplacement ? pair.value : pair.key;
        var value = options.reversedReplacement ? pair.key : pair.value;

        if (contents.contains(key)) {
          var question = 'Update $key to $value in ${entity.path}?';
          if (ask(question)) {
            overwritten = true;
            contents = contents.replaceAll(key, value);
          }
        }
      }

      if (overwritten) {
        stdout.writeln('Updating: ' + entity.path);
        await file.writeAsString(contents);
        stdout.writeln();
      }
    }
  }

  bool ask(String question) {
    bool answered;

    while (answered == null) {
      stdout.writeln(question + ' Y/n');
      var answer = stdin.readLineSync();

      if (answer == 'Y') {
        answered = true;
      } else if (answer == 'n') {
        answered = false;
      }
    }

    return answered;
  }
}

class ReplacerOptions {
  final Map<String, String> keys;
  final bool reversedReplacement;
  final bool includeHidden;

  ReplacerOptions(this.keys, this.reversedReplacement, this.includeHidden);
}
