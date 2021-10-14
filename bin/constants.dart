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

// For each VM logic command, define the corresponding jump operation in the Hack language.
const comparisonCommandToOperation = {
  'eq': 'JEQ',
  'gt': 'JGT',
  'lt': 'JLT',
};

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