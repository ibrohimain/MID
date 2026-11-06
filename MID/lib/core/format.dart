String money(int value) {
  final s = value.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final fromEnd = s.length - i;
    buf.write(s[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(' ');
  }
  final body = buf.toString();
  return value < 0 ? '-$body' : body;
}

String moneySum(int value) => '${money(value)} so‘m';

String shortDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
