import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  static final _currency = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  static final _date = DateFormat('dd/MM/yyyy');

  static String currency(num value) => _currency.format(value);
  static String date(DateTime value) => _date.format(value);
  static String dateString(String iso) {
    try {
      return _date.format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static String timeString(String value) {
    if (value.length >= 5) return value.substring(0, 5);
    return value;
  }
}
