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
const vmComparisonCommandToJumpOperation = {
  'eq': 'JEQ',
  'gt': 'JGT',
  'lt': 'JLT',
};

// For each memory segment name in the VM language, map the corresponding Hack label.
const vmSegmentToHackLabel = {
  'local': 'LCL',
  'argument': 'ARG',
  'this': 'THIS',
  'that': 'THAT',
  // TEMP is fixed and mapped directly on RAM locations 5-12
  'temp': '5',
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