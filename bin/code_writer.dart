import 'dart:io';

import 'constants.dart';

class CodeWriter {
  File file;
  RandomAccessFile sink;

  CodeWriter(this.file) : sink = file.openSync(mode: FileMode.write);

  /// Write to the output file the assembly code that implements the given cArithmetic-logical command.
  void writecArithmetic(String command) {
    final translatedCode = stringBufferWithComment(command);

    switch (command) {
      case 'add':
        translatedCode
          ..writeln()
          ..write([_pop(), 'D=M', _pop(), 'D=D+M', _push()].join('\n'));
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

    writeBufferContentsToOutput(translatedCode);
  }

  /// Write to the output file the assembly code that implements the given push/pop command
  void writePushPop(CommandType command, String segment, int index) {
    final originalCommand = '${command.toBaseCommand()} $segment $index';
    final translatedCode = stringBufferWithComment(originalCommand);

    switch (command) {
      // todo support segments other than "constant"
      case CommandType.cPush:
        translatedCode.write('\n@$index\nD=A\n${_push()}');
        break;
      case CommandType.cPop:
        translatedCode.write('\n@SP\nM=M-1\nA=M');
        break;
      default:
        throw UnimplementedError(
            'CommandType of $command not recognized. Could not translate "$originalCommand"');
    }

    writeBufferContentsToOutput(translatedCode);
  }

  // Pushes the value in D to the stack. Equivalent to "push D"
  static String _push() => ['@SP', 'A=M', 'M=D', '@SP', 'M=M+1'].join('\n');

  // Pops the value from the top of the stack and puts it in D. Equivalent to "pop D"
  static String _pop() => ['@SP', 'M=M-1', 'A=M'].join('\n');

  // Returns a StringBuffer with the passed comment.
  static StringBuffer stringBufferWithComment(String comment) {
    final assemblySnippet = StringBuffer();
    assemblySnippet.write('// $comment');
    return assemblySnippet;
  }

  void writeBufferContentsToOutput(StringBuffer buffer) {
    buffer.writeln();
    sink.writeStringSync(buffer.toString());
  }

  /// Finish the program with and infinite loopo and close the output file/stream
  void close() {
    sink.writeStringSync('\n(INFINITE)\n@INFINITE\n0;JMP');

    sink.closeSync();
  }
}
