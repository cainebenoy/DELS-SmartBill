import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
  );

  static String format(num value) => _inr.format(value);
}
