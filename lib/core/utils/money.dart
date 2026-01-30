import 'package:intl/intl.dart';

import '../constants/app_constants.dart';

class Money {
  Money._();

  static final _fmt = NumberFormat.currency(
    locale: 'en_GH',
    symbol: AppConstants.currencySymbol,
    decimalDigits: 2,
  );

  static String format(num value) => _fmt.format(value);
}

