import 'dart:io';
import 'dart:math';

import 'constants.dart';

class CodeWriter {
  File file;
  RandomAccessFile sink;
  final Random _random;

  CodeWriter(this.file)
      : sink = file.openSync(mode: FileMode.write),
        _random = Random();

  int getNextRandom() => _random.nextInt(1000000);

  /// Write to the output file the assembly code that implements the given cArithmetic-logical command.
  void writeArithmetic(String command) {
    final translatedCode = _stringBufferWithComment(command)..writeln();

    switch (command) {
      case 'add':
        translatedCode.write([_popD(), _pop(), 'D=D+M', _push()].join('\n'));
        break;
      case 'sub':
        translatedCode.write(_sub());
        break;
      case 'neg':
        translatedCode.write([_pop(), 'D=-D', _push()].join('\n'));
        break;
      case 'eq':
      case 'gt': // Intentional fall-through
      case 'lt': // Intentional fall-through
        translatedCode.write(_generateComparisonOperation(command));
        break;
      case 'and': // Intentional fall-through
      case 'or':
        translatedCode.write(_generateLogicalOperation(command));
        break;
      case 'not':
        translatedCode.write([_popD(), 'D=!D', _push()].join('\n'));
        break;
      default:
        throw UnimplementedError('Unknown cArithmetic command: $command');
    }

    _writeBufferContentsToOutput(translatedCode);
  }

  /// Write to the output file the assembly code that implements the given push/pop command
  void writePushPop(CommandType command, String segment, int index) {
    final originalCommand = '${command.toBaseCommand()} $segment $index';
    final translatedCode = _stringBufferWithComment(originalCommand);
    translatedCode.writeln();

    if (CommandType.cPush == command) {
      switch (segment) {
        case 'constant':
          // set D=index
          translatedCode.write([
            '@$index',
            'D=A',
            _push(),
          ].join('\n'));
          break;
        case 'local': // Intentional fall-through
        case 'argument': // Intentional fall-through
        case 'this': // Intentional fall-through
        case 'that': // Intentional fall-through
        case 'temp':
          translatedCode.write(_generateSegmentPush(segment, index));
          break;

        default:
          throw UnsupportedError(
              'Segment "$segment" unsupported for CommandType of $command');
      }
    } else if (CommandType.cPop == command) {
      switch (segment) {
        case 'constant':
          translatedCode.write(_pop());
          break;
        case 'local': // Intentional fall-through
        case 'argument': // Intentional fall-through
        case 'this': // Intentional fall-through
        case 'that': // Intentional fall-through
        case 'temp': // Intentional fall-through
          translatedCode.write(_generateSegmentPop(segment, index));
          break;

        default:
          throw UnsupportedError(
              'Segment "$segment" unsupported for CommandType of $command');
      }
    } else {
      throw UnsupportedError('CommandType $command not supported');
    }

    _writeBufferContentsToOutput(translatedCode);
  }

  // Pushes the value in D to the stack. Equivalent to "push D"
  static String _push() =>
      ['@SP', 'A=M', 'M=D', '@SP', 'M=M+1 // push D'].join('\n');

  // Pops the value from the top of the stack.
  static String _pop() => ['@SP', 'M=M-1', 'A=M // pop'].join('\n');

  // Pops the value from the top of the stack and puts it in D. Equivalent to "pop D".
  static String _popD() => [_pop(), 'D=M'].join('\n');

  // Subtract function. Pops the top 2 values off teh stack, subracts them in order popped and pushes the difference.
  static String _sub() => [_popD(), _pop(), 'D=M-D', _push()].join('\n');

  // Returns the assembly code for comparison commands, i.e. "eq", "gt", and "lt"
  String _generateComparisonOperation(String command) {
    final int trueLabelId = getNextRandom();
    final setDLabelId = getNextRandom();

    // todo - optimize to avoid using labels here
    return [
      _sub(), // Compute difference of top two items on stack
      _popD(), // Get the result in the D value
      '@TRUE_$trueLabelId',
      'D;${vmComparisonCommandToJumpOperation[command]}', // e.g. for 'eq' -> 'JEQ', for 'gt' -> 'JGT'
      'D=0 // D=FALSE', // If not equal, set D to "false"
      '@SET_D_$setDLabelId',
      '0;JMP', // If not equal jump right to pushing D value
      '(TRUE_$trueLabelId)',
      'D=-1 // D=TRUE',
      '(SET_D_$setDLabelId)',
      _push(),
    ].join('\n');
  }

  // Returns the assembly code for logical commands with two implicit operations, i.e. "and" and "or"
  static String _generateLogicalOperation(String command) => [
        _popD(),
        _pop(),
        "D=${{'and': 'D&M', 'or': 'D|M'}[command]}",
        _push(),
      ].join('\n');

  static _generateSegmentPushPopHeader(String segment, int index) {
    final isVirtual = segment != 'temp';

    return [
      '@${isVirtual ? vmSegmentToHackLabel[segment] : 5}',
      // If virtual, we want to value pointed to, otherwise we want the static address value
      isVirtual ? 'D=M' : 'D=A',
    ].join(('\n'));
  }

  // Handles pushing a value from a virtual or fixed memory segment to the stack
  static String _generateSegmentPush(String segment, int index) {
    return [
      _generateSegmentPushPopHeader(segment, index),
      '@$index',
      'A=D+A',
      'D=M',
      _push(),
    ].join('\n');
  }

  static String _generateSegmentPop(String segment, int index) {
    return [
      _generateSegmentPushPopHeader(segment, index),
      '@$index',
      'D=D+A',
      '@R13',
      'M=D', // D = RAM[--SP]
      _popD(),
      '@R13',
      'A=M',
      'M=D', // RAM[R13] = D
    ].join('\n');
  }

  // Returns a StringBuffer with the passed comment.
  static StringBuffer _stringBufferWithComment(String comment) {
    final assemblySnippet = StringBuffer()
      ..writeln()
      ..write('// $comment');
    return assemblySnippet;
  }

  void _writeBufferContentsToOutput(StringBuffer buffer) {
    buffer.writeln();
    sink.writeStringSync(buffer.toString());
  }

  /// Finish the program with and infinite loopo and close the output file/stream
  void close() {
    sink.writeStringSync('\n(INFINITE)\n@INFINITE\n0;JMP\n');

    sink.closeSync();
  }

  // void _format() async {
  //   // todo - implement opt-in format method to indent non-label lines
  // }
}
