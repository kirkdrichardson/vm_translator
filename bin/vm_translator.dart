import 'dart:io';
import 'code_writer.dart';
import 'constants.dart';
import 'parser.dart';

void main(List<String> arguments) async {
  exitCode = 0; // presume success

  if (arguments.isEmpty) {
    exitCode = 2;
    throw Exception('Filepath is a required argument');
  }

  final filepath = arguments.first;
  final outputPath = filepath.replaceFirst('.vm', '.asm');

  final parser = Parser(File(filepath));
  final codeWriter = CodeWriter(File(outputPath));

  // todo - rewrite to avoid having to do an init here.
  // File(filepath).readAsLinesSync().iterator.
  await parser.init();

  print('parser inited');
  while (parser.hasMoreLines) {
    final commandType = parser.commandType();
    print('command type is $commandType');

    switch (commandType) {
      case CommandType.cPush:
      case CommandType.cPop:
        codeWriter.writePushPop(commandType, parser.arg1(), parser.arg2());
        break;
      case CommandType.cArithmetic:
        codeWriter.writeArithmetic(parser.arg1());
        break;
      default:
        throw UnimplementedError('Unrecognized command type of $commandType');
    }

    parser.advance();
  }

  codeWriter.close();
}
