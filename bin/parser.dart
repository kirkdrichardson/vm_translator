import 'dart:io';

import 'constants.dart';

class Parser {
  final List<String> _commands;
  int _currentCommandIndex = 0;

  Parser(File _file)
      : _commands = (_file.readAsLinesSync()
              ..retainWhere(_lineIsNotBlankOrComment))
            .map((line) {
          return line.replaceAll(RegExp(r'\/\/.*'), '').trim();
        }).toList(); // Replace in-line comments

  static bool _lineIsNotBlankOrComment(String line) {
    final trimmedLine = line.trim();
    if (line.isEmpty) {
      return false;
    }

    return !trimmedLine.startsWith('//');
  }

  /// Are there more commands in the input file?
  bool get hasMoreCommands => _currentCommandIndex < _commands.length;

  String get currentCommand => _commands[_currentCommandIndex];

  List<String> get commands => _commands.toList();

  /// Read the next command from the input and make it the current command.
  /// Should only be called if hasMoreLines is true.
  /// Initially there is no current command.
  void advance() {
    if (hasMoreCommands) {
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
      case 'sub': // Intentional fall-through
      case 'neg': // Intentional fall-through
      case 'eq': // Intentional fall-through
      case 'gt': // Intentional fall-through
      case 'lt': // Intentional fall-through
      case 'and': // Intentional fall-through
      case 'or': // Intentional fall-through
      case 'not': // Intentional fall-through
        return CommandType.cArithmetic;
      case 'label':
        return CommandType.cLabel;
      case 'if-goto':
        return CommandType.cIf;
      case 'goto':
        return CommandType.cGoto;
      default:
        throw UnimplementedError('Received unrecognized command "$command"');
    }
  }

  /// Return the first argument of the current command.
  /// In the case of cArithmetic, the command itself (add, sub, etc.) is returned.
  /// Should not be called if the current command is C_RETURN
  String arg1() {
    final segments = currentCommand.trim().split(' ');
    return segments.length == 1 ? segments[0] : segments[1];
  }

  /// Return the second argument of the current command.
  /// Should  be called only if the current command is push, pop, C_FUNCTION, or C_CALL.
  int arg2() => int.parse(currentCommand.trim().split(' ').last);

  // Future<void> _handleError(String path) async {
  //   if (await FileSystemEntity.isDirectory(path)) {
  //     stderr.writeln('error: $path is a directory');
  //   } else {
  //     exitCode = 2;
  //   }
  // }
}
