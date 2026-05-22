import 'dart:io';

void main(List<String> args) {
  final threshold = double.parse(args.first);
  final lines = File('coverage/lcov.info').readAsLinesSync();
  var hit = 0, total = 0;
  for (final l in lines) {
    if (l.startsWith('DA:')) {
      total++;
      final count = int.parse(l.split(',')[1]);
      if (count > 0) hit++;
    }
  }
  final pct = total == 0 ? 0 : (hit / total) * 100;
  // ignore: avoid_print
  print('Coverage: ${pct.toStringAsFixed(2)}% ($hit/$total)');
  if (pct < threshold) {
    exitCode = 1;
  }
}
