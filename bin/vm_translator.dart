import 'dart:io';
import 'code_writer.dart';
import 'constants.dart';
import 'parser.dart';

void main(List<String> arguments) async {
  exitCode = 0; // presume success

  // The root directory to operate on.
  Directory? _directory;

  String _outputFilepath = 'Out.asm';

  final _filesToTranslate = <File>[];

  void _invalidPath(String path) {
    exitCode = 2;
    print('💩 Invalid file or directory path: "$path"');
  }

  // If initiated without arguments, operate on the current directory.
  if (arguments.isEmpty) {
    print('No filepath argument, operating on current directory');
    _directory = Directory.current;
  } else {
    // We have an argument, but still need to figure out if it is a file or directory.
    final entityPath = arguments.first;
    final pathSegments = entityPath.split('/');
    // If we have a file...
    if (pathSegments.last.contains('.vm')) {
      // Ensure file exists.
      final file = File(entityPath);
      if (!(await file.exists())) {
        return _invalidPath(entityPath);
      }

      // Assign output path.
      final lastPathSegment = pathSegments.removeLast();
      pathSegments.add(lastPathSegment.replaceFirst(
          '.vm', '.asm', lastPathSegment.length - 4));
      _outputFilepath = pathSegments.join('/');

      _filesToTranslate.add(file);
    } else {
      _directory = Directory(entityPath);
    }
  }

  // Collect files if operating on directory.
  if (_directory != null) {
    // Ensure directory is valid
    if (!(await _directory.exists())) {
      return _invalidPath(_directory.path);
    }

    print('✅ Gathering *.vm files for the directory: "${_directory.path}"');
    _outputFilepath =
        '${_directory.path}/${_directory.path.split("/").last}.asm';

    final files = _directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((element) => element.path.contains('.vm'));

    void addFile(File file) => _filesToTranslate.add(file);
    files.forEach(addFile);
  }

  // Final check to ensure we gathered files.
  if (_filesToTranslate.isEmpty) {
    print('💩 No *.vm files found to translate.');
    exitCode = 2;
    return;
  }

  // We will output all .asm code to a single file
  final codeWriter = CodeWriter(File(_outputFilepath));
  print('Outputing to file at "$_outputFilepath"');

  for (final file in _filesToTranslate) {
    print('Translating ${file.path}');
    final filename = file.path.split('/').last.replaceAll('.vm', '');
    codeWriter.setFilename(filename);
    final parser = Parser(file);

    while (parser.hasMoreCommands) {
      final commandType = parser.commandType();
      // print('command type is $commandType');

      switch (commandType) {
        case CommandType.cPush:
        case CommandType.cPop:
          codeWriter.writePushPop(commandType, parser.arg1(), parser.arg2());
          break;
        case CommandType.cArithmetic:
          codeWriter.writeArithmetic(parser.arg1());
          break;
        case CommandType.cLabel:
          codeWriter.writeLabel(parser.arg1());
          break;
        case CommandType.cGoto:
          codeWriter.writeGoto(parser.arg1());
          break;
        case CommandType.cIf:
          codeWriter.writeIf(parser.arg1());
          break;
        default:
          throw UnimplementedError('Unrecognized command type of $commandType');
      }

      parser.advance();
    }
  }

  codeWriter.close();
}
