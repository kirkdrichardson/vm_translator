import 'dart:io';

import 'constants.dart';

class CodeWriter {
  File file;
  RandomAccessFile sink;

  CodeWriter(this.file) : sink = file.openSync(mode: FileMode.write);

  /// Write to the output file the assembly code that implements the given cArithmetic-logical command.
  void writecArithmetic(String command) {
    // todo

    switch (command) {
      case 'add':
        sink.writeStringSync('''
${_pop()}
D=M
${_pop()}
D=D+M
${_push()}
          ''');
        break;
      // case 'sub':
      // case 'neg':
      // case 'eq':
      // case 'gt':
      // case 'lt':
      // case 'and':
      // case 'or':
      // case 'not':
      default:
        throw UnimplementedError('Unknown cArithmetic command: $command');
    }
  }

  /// Write to the output file the assembly code that implements the given push/pop command
  void writePushPop(CommandType command, String segment, int index) {
    final assemblySnippet = StringBuffer();
    // Add comment of the original vm command
    assemblySnippet.write('# ${command.toBaseCommand()} $segment $index');

    switch (command) {
      // todo support segments other than "constant"
      case CommandType.cPush:
        assemblySnippet.write('\n@$index\nD=A\n${_push()}');
        break;
      case CommandType.cPop:
        sink.writeStringSync('''
@SP
M=M-1
A=M
D=M''');
        break;
      default:
        throw UnimplementedError('');
    }

    assemblySnippet.writeln();
    sink.writeStringSync(assemblySnippet.toString());
  }

  String _push() {
    return '''
@SP
A=M
M=D
@SP
M=M+1'''
        .trim();
  }

  String _pop() {
    return '''
@SP
M=M-1
A=M
D=M'''
        .trim();
  }

  /// Close the output file/stream
  void close() {
    sink.closeSync();
  }
}
