String formatRupee(double value) {
  final s = value.toStringAsFixed(0);
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  final rest = s.substring(0, s.length - 3);
  final withCommas = rest.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
    (m) => '${m[1]},',
  );
  return '₹$withCommas,$last3';
}

int discountPercent(double regular, double special) {
  if (regular <= 0 || special >= regular) return 0;
  return (((regular - special) / regular) * 100).round();
}
