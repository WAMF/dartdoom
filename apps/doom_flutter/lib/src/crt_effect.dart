enum CrtEffect {
  none(0, 'Off'),
  scanlines(1, 'Scanlines'),
  full(2, 'Full CRT'),
  flat(3, 'Flat CRT');

  const CrtEffect(this.mode, this.label);

  final int mode;
  final String label;

  CrtEffect next() {
    final nextIndex = (index + 1) % CrtEffect.values.length;
    return CrtEffect.values[nextIndex];
  }
}
