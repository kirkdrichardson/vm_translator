enum CommandType {
  cArithmetic,
  cPush,
  cPop,
  cLabel,
  cGoto,
  cIf,
  cFunction,
  cReturn,
  cCall
}

extension CommandTypeStringUtil on CommandType {
  String toBaseCommand() =>
      toString().replaceFirst('CommandType.c', '').toLowerCase();
}

// enum Segment {
//   LCL,
//   ARG,
//   THIS,
//   THAT,
//   TEMP,
// }
//
// /// Keys are segment names as referenced in the VM language.
// /// Values are segment names as referred to in the Hack assembly language.
// const SegmentDecoder = {
//   'local': 'LCL',
//   '
// }