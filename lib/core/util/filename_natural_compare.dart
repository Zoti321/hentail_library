/// Compares two file name strings using natural (alphanumeric) order.
///
/// Contiguous ASCII digit runs are parsed as integers and compared numerically;
/// other runs are compared with [String.compareTo] (Unicode code unit order).
int compareFilenameNatural(String a, String b) {
  final List<Object> ta = _tokenizeNatural(a);
  final List<Object> tb = _tokenizeNatural(b);
  final int n = ta.length < tb.length ? ta.length : tb.length;
  for (int i = 0; i < n; i++) {
    final Object ca = ta[i];
    final Object cb = tb[i];
    if (ca is int && cb is int) {
      if (ca != cb) {
        return ca.compareTo(cb);
      }
    } else if (ca is String && cb is String) {
      final int c = ca.compareTo(cb);
      if (c != 0) {
        return c;
      }
    } else if (ca is int && cb is String) {
      final int c = ca.toString().compareTo(cb);
      if (c != 0) {
        return c;
      }
    } else if (ca is String && cb is int) {
      final int c = ca.compareTo(cb.toString());
      if (c != 0) {
        return c;
      }
    }
  }
  return ta.length.compareTo(tb.length);
}

List<Object> _tokenizeNatural(String s) {
  final List<Object> out = <Object>[];
  int i = 0;
  while (i < s.length) {
    if (_isAsciiDigit(s, i)) {
      final int start = i;
      while (i < s.length && _isAsciiDigit(s, i)) {
        i++;
      }
      out.add(int.parse(s.substring(start, i)));
    } else {
      final int start = i;
      while (i < s.length && !_isAsciiDigit(s, i)) {
        i++;
      }
      out.add(s.substring(start, i));
    }
  }
  return out;
}

bool _isAsciiDigit(String s, int i) {
  final int u = s.codeUnitAt(i);
  return u >= 0x30 && u <= 0x39;
}
