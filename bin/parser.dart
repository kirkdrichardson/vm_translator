import 'dart:io';
import 'dart:convert';

import 'constants.dart';

class Parser {
  final File _file;

  // The contents of the file passed to the constructor as a stream of string units where each unit corresponds to a line of the file.
  final Stream<String> _stream;
  final List<String> _commands = [];
  int _currentCommandIndex = 0;

  Parser(this._file)
      : _stream =
            utf8.decoder.bind(_file.openRead()).transform(LineSplitter()) {
    // _init();
  }

  /// Read the stream of file lines, remove comments, and create list of commands.
  Future<void> init() async {
    try {
      await for (final line in _stream) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) {
          continue;
        }

        _commands.add(line);
      }
    } catch (_) {
      await _handleError(_file.path);
    }
  }

  /// Are there more lines in the input?
  bool get hasMoreLines => _currentCommandIndex < _commands.length;

  String get currentCommand => _commands[_currentCommandIndex];

  List<String> get commands => _commands.toList();

  /// Read the next command from the input and make it the current command.
  /// Should only be called if hasMoreLines is true.
  /// Initially there is no current command.
  void advance() {
    if (hasMoreLines) {
      _currentCommandIndex++;
    }
  }

  /// Return the type of current command.
  CommandType commandType() {
    final command = currentCommand.split(' ')[0];

    switch (command) {
      case 'push':
        return CommandType.cPush;
      case 'pop':
        return CommandType.cPop;
      case 'add':
      case 'sub':
      case 'neg':
      case 'eq':
      case 'gt':
      case 'lt':
      case 'and':
      case 'or':
      case 'not':
        return CommandType.cArithmetic;
      default:
        throw UnimplementedError('Received unrecognized command "$command"');
    }
  }

  /// Return the first argument of the current command.
  /// In the case of cArithmetic, the command itself (add, sub, etc.) is returned.
  /// Should not be called if the current command is C_RETURN
  String arg1() {
    final segments = currentCommand.split(' ');
    return segments.length == 1 ? segments[0] : segments[1];
  }

  /// Return the second argument of the current command.
  /// Should  be called only if the current command is push, pop, C_FUNCTION, or C_CALL.
  int arg2() => int.parse(currentCommand.split(' ').last);

  Future<void> _handleError(String path) async {
    if (await FileSystemEntity.isDirectory(path)) {
      stderr.writeln('error: $path is a directory');
    } else {
      exitCode = 2;
    }
  }
}
