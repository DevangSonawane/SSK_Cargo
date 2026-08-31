import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PaymentMethodTypeOption {
  const PaymentMethodTypeOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class PaymentWalletOption {
  const PaymentWalletOption({
    required this.id,
    required this.label,
    required this.logoBuilder,
  });

  final String id;
  final String label;
  final WidgetBuilder logoBuilder;
}

class PaymentBankOption {
  const PaymentBankOption({
    required this.name,
    required this.ifsc,
    required this.assetPath,
  });

  final String name;
  final String ifsc;
  final String assetPath;
}

class SavedPaymentMethod {
  const SavedPaymentMethod({
    required this.id,
    required this.methodType,
    required this.label,
    required this.details,
    required this.isDefault,
  });

  final String id;
  final String methodType;
  final String label;
  final Map<String, dynamic> details;
  final bool isDefault;

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    return SavedPaymentMethod(
      id: readString(json, const ['id']),
      methodType: readString(json, const ['methodType', 'method_type']),
      label: readString(json, const ['label']),
      details: details is Map<String, dynamic>
          ? details
          : const <String, dynamic>{},
      isDefault: readBool(json, const ['isDefault', 'is_default']),
    );
  }

  SavedPaymentMethod copyWith({
    String? methodType,
    String? label,
    Map<String, dynamic>? details,
    bool? isDefault,
  }) {
    return SavedPaymentMethod(
      id: id,
      methodType: methodType ?? this.methodType,
      label: label ?? this.label,
      details: details ?? this.details,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  String get secondaryLabel {
    switch (methodType) {
      case 'upi':
        final upiId = readString(details, const ['upi_id']);
        return upiId.isNotEmpty ? upiId : 'UPI';
      case 'card':
        final brand = readString(details, const ['brand']);
        final last4 = readString(details, const ['last4']);
        if (brand.isNotEmpty && last4.isNotEmpty) {
          return '$brand •••• $last4';
        }
        return 'Card';
      case 'netbanking':
        final bank = readString(details, const ['bank']);
        final last4 = readString(details, const ['account_last4']);
        final ifsc = readString(details, const ['ifsc']);
        if (bank.isNotEmpty && last4.isNotEmpty) {
          final suffix = ifsc.isNotEmpty ? ' · $ifsc' : '';
          return '$bank •••• $last4$suffix';
        }
        return bank.isNotEmpty ? bank : 'Netbanking';
      case 'wallet':
        final wallet = readString(details, const ['wallet']);
        return wallet.isNotEmpty ? wallet : 'Wallet';
      default:
        return methodType.isNotEmpty ? methodType : 'Payment method';
    }
  }
}

class PaymentMethodDraft {
  const PaymentMethodDraft({
    required this.methodType,
    required this.label,
    required this.details,
  });

  final String methodType;
  final String label;
  final Map<String, dynamic> details;
}

const paymentMethodTypeOptions = <PaymentMethodTypeOption>[
  PaymentMethodTypeOption(
    id: 'upi',
    label: 'UPI',
    icon: Icons.smartphone_rounded,
  ),
  PaymentMethodTypeOption(
    id: 'card',
    label: 'Card',
    icon: Icons.credit_card_rounded,
  ),
  PaymentMethodTypeOption(
    id: 'netbanking',
    label: 'Bank',
    icon: Icons.account_balance_rounded,
  ),
  PaymentMethodTypeOption(
    id: 'wallet',
    label: 'Wallet',
    icon: Icons.account_balance_wallet_rounded,
  ),
];

const paymentWalletOptions = <PaymentWalletOption>[
  PaymentWalletOption(
    id: 'paytm',
    label: 'Paytm',
    logoBuilder: _paytmLogo,
  ),
  PaymentWalletOption(
    id: 'amazonpay',
    label: 'Amazon Pay',
    logoBuilder: _amazonPayLogo,
  ),
  PaymentWalletOption(
    id: 'mobikwik',
    label: 'Mobikwik',
    logoBuilder: _mobikwikLogo,
  ),
  PaymentWalletOption(
    id: 'freecharge',
    label: 'Freecharge',
    logoBuilder: _freechargeLogo,
  ),
  PaymentWalletOption(
    id: 'paypal',
    label: 'PayPal',
    logoBuilder: _paypalLogo,
  ),
];

const paymentBankOptions = <PaymentBankOption>[
  PaymentBankOption(
    name: 'Axis Bank',
    ifsc: 'UTIB',
    assetPath: 'assets/banks/bi_axisbank.png',
  ),
  PaymentBankOption(
    name: 'Bandhan Bank',
    ifsc: 'BDBL',
    assetPath: 'assets/banks/bi_bandhanbank.png',
  ),
  PaymentBankOption(
    name: 'Bank of Baroda',
    ifsc: 'BARB',
    assetPath: 'assets/banks/bi_bankofbaroda.png',
  ),
  PaymentBankOption(
    name: 'Bank of India',
    ifsc: 'BKID',
    assetPath: 'assets/banks/bi_bankofindia.png',
  ),
  PaymentBankOption(
    name: 'Bank of Maharashtra',
    ifsc: 'MAHB',
    assetPath: 'assets/banks/bi_bankofmaharashtra.png',
  ),
  PaymentBankOption(
    name: 'Canara Bank',
    ifsc: 'CNRB',
    assetPath: 'assets/banks/bi_canarabank.png',
  ),
  PaymentBankOption(
    name: 'Central Bank of India',
    ifsc: 'CBIN',
    assetPath: 'assets/banks/bi_centralbankofindia.png',
  ),
  PaymentBankOption(
    name: 'City Union Bank',
    ifsc: 'CIUB',
    assetPath: 'assets/banks/bi_cityunionbank.png',
  ),
  PaymentBankOption(
    name: 'CSB Bank',
    ifsc: 'CSBK',
    assetPath: 'assets/banks/bi_csb.png',
  ),
  PaymentBankOption(
    name: 'DCB Bank',
    ifsc: 'DCBL',
    assetPath: 'assets/banks/bi_dcbbank.png',
  ),
  PaymentBankOption(
    name: 'Dhanlaxmi Bank',
    ifsc: 'DLXB',
    assetPath: 'assets/banks/bi_dhanbank.png',
  ),
  PaymentBankOption(
    name: 'Federal Bank',
    ifsc: 'FDRL',
    assetPath: 'assets/banks/bi_federalbank.png',
  ),
  PaymentBankOption(
    name: 'HDFC Bank',
    ifsc: 'HDFC',
    assetPath: 'assets/banks/bi_hdfcbank.png',
  ),
  PaymentBankOption(
    name: 'ICICI Bank',
    ifsc: 'ICIC',
    assetPath: 'assets/banks/bi_icicibank.png',
  ),
  PaymentBankOption(
    name: 'IDBI Bank',
    ifsc: 'IBKL',
    assetPath: 'assets/banks/bi_idbi.png',
  ),
  PaymentBankOption(
    name: 'IDFC FIRST Bank',
    ifsc: 'IDFB',
    assetPath: 'assets/banks/bi_idfcbank.png',
  ),
  PaymentBankOption(
    name: 'Indian Bank',
    ifsc: 'IDIB',
    assetPath: 'assets/banks/bi_indianbank.png',
  ),
  PaymentBankOption(
    name: 'Indian Overseas Bank',
    ifsc: 'IOBA',
    assetPath: 'assets/banks/bi_iob.png',
  ),
  PaymentBankOption(
    name: 'IndusInd Bank',
    ifsc: 'INDB',
    assetPath: 'assets/banks/bi_indusind.png',
  ),
  PaymentBankOption(
    name: 'Jammu & Kashmir Bank',
    ifsc: 'JAKA',
    assetPath: 'assets/banks/bi_jkbank.png',
  ),
  PaymentBankOption(
    name: 'Karnataka Bank',
    ifsc: 'KARB',
    assetPath: 'assets/banks/bi_karnatakabank.png',
  ),
  PaymentBankOption(
    name: 'Karur Vysya Bank',
    ifsc: 'KVBL',
    assetPath: 'assets/banks/bi_kvb.png',
  ),
  PaymentBankOption(
    name: 'Kotak Mahindra Bank',
    ifsc: 'KKBK',
    assetPath: 'assets/banks/bi_kotak.png',
  ),
  PaymentBankOption(
    name: 'Nainital Bank',
    ifsc: 'NTBL',
    assetPath: 'assets/banks/bi_nainitalbank.png',
  ),
  PaymentBankOption(
    name: 'Punjab & Sind Bank',
    ifsc: 'PSIB',
    assetPath: 'assets/banks/bi_punjabandsindbank.png',
  ),
  PaymentBankOption(
    name: 'Punjab National Bank',
    ifsc: 'PUNB',
    assetPath: 'assets/banks/bi_pnbindia.png',
  ),
  PaymentBankOption(
    name: 'RBL Bank',
    ifsc: 'RATN',
    assetPath: 'assets/banks/bi_rblbank.png',
  ),
  PaymentBankOption(
    name: 'South Indian Bank',
    ifsc: 'SIBL',
    assetPath: 'assets/banks/bi_southindianbank.png',
  ),
  PaymentBankOption(
    name: 'State Bank of India',
    ifsc: 'SBIN',
    assetPath: 'assets/banks/bi_sbi.png',
  ),
  PaymentBankOption(
    name: 'Tamilnad Mercantile Bank',
    ifsc: 'TMBL',
    assetPath: 'assets/banks/bi_tmb.png',
  ),
  PaymentBankOption(
    name: 'UCO Bank',
    ifsc: 'UCBA',
    assetPath: 'assets/banks/bi_ucobank.png',
  ),
  PaymentBankOption(
    name: 'Union Bank of India',
    ifsc: 'UBIN',
    assetPath: 'assets/banks/bi_unionbankonline.png',
  ),
  PaymentBankOption(
    name: 'YES Bank',
    ifsc: 'YESB',
    assetPath: 'assets/banks/bi_yesbank.png',
  ),
];

const _bankAssetByName = <String, String>{
  'Axis Bank': 'assets/banks/bi_axisbank.png',
  'Bandhan Bank': 'assets/banks/bi_bandhanbank.png',
  'Bank of Baroda': 'assets/banks/bi_bankofbaroda.png',
  'Bank of India': 'assets/banks/bi_bankofindia.png',
  'Bank of Maharashtra': 'assets/banks/bi_bankofmaharashtra.png',
  'Canara Bank': 'assets/banks/bi_canarabank.png',
  'Central Bank of India': 'assets/banks/bi_centralbankofindia.png',
  'City Union Bank': 'assets/banks/bi_cityunionbank.png',
  'CSB Bank': 'assets/banks/bi_csb.png',
  'DCB Bank': 'assets/banks/bi_dcbbank.png',
  'Dhanlaxmi Bank': 'assets/banks/bi_dhanbank.png',
  'Federal Bank': 'assets/banks/bi_federalbank.png',
  'HDFC Bank': 'assets/banks/bi_hdfcbank.png',
  'ICICI Bank': 'assets/banks/bi_icicibank.png',
  'IDBI Bank': 'assets/banks/bi_idbi.png',
  'IDFC FIRST Bank': 'assets/banks/bi_idfcbank.png',
  'Indian Bank': 'assets/banks/bi_indianbank.png',
  'Indian Overseas Bank': 'assets/banks/bi_iob.png',
  'IndusInd Bank': 'assets/banks/bi_indusind.png',
  'Jammu & Kashmir Bank': 'assets/banks/bi_jkbank.png',
  'Karnataka Bank': 'assets/banks/bi_karnatakabank.png',
  'Karur Vysya Bank': 'assets/banks/bi_kvb.png',
  'Kotak Mahindra Bank': 'assets/banks/bi_kotak.png',
  'Nainital Bank': 'assets/banks/bi_nainitalbank.png',
  'Punjab & Sind Bank': 'assets/banks/bi_punjabandsindbank.png',
  'Punjab National Bank': 'assets/banks/bi_pnbindia.png',
  'RBL Bank': 'assets/banks/bi_rblbank.png',
  'South Indian Bank': 'assets/banks/bi_southindianbank.png',
  'State Bank of India': 'assets/banks/bi_sbi.png',
  'Tamilnad Mercantile Bank': 'assets/banks/bi_tmb.png',
  'UCO Bank': 'assets/banks/bi_ucobank.png',
  'Union Bank of India': 'assets/banks/bi_unionbankonline.png',
  'YES Bank': 'assets/banks/bi_yesbank.png',
};

Widget paymentBrandLogo(String brand) {
  final key = brand.trim().toLowerCase();
  if (key.contains('visa')) {
    return SvgPicture.string(_visaSvg, fit: BoxFit.contain);
  }
  if (key.contains('mastercard')) {
    return SvgPicture.string(_mastercardSvg, fit: BoxFit.contain);
  }
  if (key.contains('american') || key.contains('amex')) {
    return SvgPicture.string(_amexSvg, fit: BoxFit.contain);
  }
  if (key.contains('discover')) {
    return SvgPicture.string(_discoverSvg, fit: BoxFit.contain);
  }
  if (key.contains('jcb')) {
    return SvgPicture.string(_jcbSvg, fit: BoxFit.contain);
  }
  if (key.contains('rupay')) {
    return SvgPicture.string(_rupaySvg, fit: BoxFit.contain);
  }
  return SvgPicture.string(_genericCardSvg, fit: BoxFit.contain);
}

Widget paymentMethodIcon(SavedPaymentMethod method) {
    switch (method.methodType) {
    case 'card':
      return paymentBrandLogo(readString(method.details, const ['brand']));
    case 'netbanking':
      return bankLogo(method.label);
    case 'wallet':
      final wallet = readString(method.details, const ['wallet']);
      return walletLogo(wallet.isNotEmpty ? wallet : method.label);
    case 'upi':
      return const Icon(Icons.smartphone_rounded, color: Color(0xFF2FA56E));
    default:
      return const Icon(Icons.payment_rounded, color: Color(0xFF2FA56E));
  }
}

Widget bankLogo(String bankName) {
  final assetPath = _bankAssetByName[bankName];
  if (assetPath != null) {
    return Image.asset(assetPath, fit: BoxFit.contain);
  }
  return SvgPicture.string(_bankFallbackSvg, fit: BoxFit.contain);
}

Widget walletLogo(String walletName) {
  final normalized = walletName.trim().toLowerCase();
  if (normalized.contains('paytm')) {
    return SvgPicture.asset('assets/svgs/icons8-paytm.svg', fit: BoxFit.contain);
  }
  if (normalized.contains('google')) {
    return SvgPicture.asset('assets/svgs/icons8-google-pay.svg', fit: BoxFit.contain);
  }
  if (normalized.contains('phonepe') || normalized.contains('phone pe')) {
    return SvgPicture.asset('assets/svgs/icons8-phone-pe.svg', fit: BoxFit.contain);
  }
  if (normalized.contains('amazon')) {
    return SvgPicture.string(_amazonPayLogoSvg, fit: BoxFit.contain);
  }
  if (normalized.contains('mobikwik')) {
    return SvgPicture.string(_mobikwikLogoSvg, fit: BoxFit.contain);
  }
  if (normalized.contains('freecharge')) {
    return SvgPicture.string(_freechargeLogoSvg, fit: BoxFit.contain);
  }
  if (normalized.contains('paypal')) {
    return SvgPicture.string(_paypalLogoSvg, fit: BoxFit.contain);
  }
  return SvgPicture.string(_genericWalletSvg, fit: BoxFit.contain);
}

List<SavedPaymentMethod> parseSavedPaymentMethods(Map<String, dynamic> response) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final raw = data['paymentMethods'] ??
      data['items'] ??
      data['results'] ??
      data['rows'] ??
      data['data'];
  final list = raw is List ? raw : const <dynamic>[];
  return list
      .whereType<Map<String, dynamic>>()
      .map(SavedPaymentMethod.fromJson)
      .where((method) => method.id.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> pickResponseItem(Map<String, dynamic> response, String key) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final item = data[key];
  if (item is Map<String, dynamic>) {
    return item;
  }
  return const <String, dynamic>{};
}

String readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

bool readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
  }
  return false;
}

Widget _paytmLogo(BuildContext context) =>
    SvgPicture.asset('assets/svgs/icons8-paytm.svg', fit: BoxFit.contain);

Widget _amazonPayLogo(BuildContext context) =>
    SvgPicture.string(_amazonPayLogoSvg, fit: BoxFit.contain);

Widget _mobikwikLogo(BuildContext context) =>
    SvgPicture.string(_mobikwikLogoSvg, fit: BoxFit.contain);

Widget _freechargeLogo(BuildContext context) =>
    SvgPicture.string(_freechargeLogoSvg, fit: BoxFit.contain);

Widget _paypalLogo(BuildContext context) =>
    SvgPicture.string(_paypalLogoSvg, fit: BoxFit.contain);

const _visaSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 16"><text x="0" y="13" font-size="14" font-weight="800" font-style="italic" fill="#1A1F71" font-family="Arial, sans-serif">VISA</text></svg>';

const _mastercardSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 24"><circle cx="15" cy="12" r="10" fill="#EB001B"/><circle cx="25" cy="12" r="10" fill="#F79E1B"/><path d="M20 4.5a10 10 0 0 1 0 15 10 10 0 0 1 0-15z" fill="#FF5F00"/></svg>';

const _amexSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 16"><rect width="48" height="16" rx="2" fill="#006FCF"/><text x="24" y="11.5" text-anchor="middle" font-size="7" font-weight="800" fill="#fff" font-family="Arial, sans-serif">AMEX</text></svg>';

const _discoverSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 16"><rect width="48" height="16" rx="2" fill="#1A1A1A"/><circle cx="40" cy="8" r="7" fill="#FF6000"/><text x="19" y="11.5" text-anchor="middle" font-size="6.5" font-weight="700" fill="#fff" font-family="Arial, sans-serif">DISCOVER</text></svg>';

const _jcbSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 16"><rect width="15" height="16" rx="2" fill="#0E4C96"/><rect x="16.5" width="15" height="16" rx="2" fill="#C6161C"/><rect x="33" width="15" height="16" rx="2" fill="#009A57"/><text x="24" y="11.5" text-anchor="middle" font-size="7.5" font-weight="800" fill="#fff" font-family="Arial, sans-serif">JCB</text></svg>';

const _rupaySvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 16"><rect width="48" height="16" rx="2" fill="#fff" stroke="#E2E8F0"/><path d="M0 8h24v8H2a2 2 0 0 1-2-2V8z" fill="#F58220"/><path d="M24 0h22a2 2 0 0 1 2 2v6H24V0z" fill="#00A651"/><text x="24" y="11" text-anchor="middle" font-size="6.5" font-weight="800" fill="#1A1A1A" font-family="Arial, sans-serif">RuPay</text></svg>';

const _genericCardSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 16"><rect width="24" height="16" rx="2.5" fill="#94A3B8"/><rect y="4" width="24" height="2.5" fill="#64748B"/></svg>';

const _bankFallbackSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="6" fill="#F1F5F9"/><path d="M6 10l6-3.5L18 10v1H6v-1z" fill="#64748B"/><path d="M7 11.5v5.5H6V19h12v-1h-1v-5.5h-1V19h-2.5v-5.5h-1V19h-2v-5.5h-1V19H9v-5.5H7z" fill="#64748B"/></svg>';

const _genericWalletSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="6" fill="#E2E8F0"/><path d="M6 9.5h12a1.5 1.5 0 0 1 1.5 1.5v5A1.5 1.5 0 0 1 18 17.5H6A1.5 1.5 0 0 1 4.5 16v-5A1.5 1.5 0 0 1 6 9.5zm0-2h9V6H6a3 3 0 0 0-3 3v7a3 3 0 0 0 3 3h12a3 3 0 0 0 3-3v-1h-5a2.5 2.5 0 0 1 0-5h5V9a3 3 0 0 0-3-3H6zm10 5a1.5 1.5 0 1 0 0 3h4v-3h-4z" fill="#64748B"/></svg>';

const _amazonPayLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="6" fill="#F8FAFC"/><path d="M6.5 14.3c1.7 1.1 4.7 1.5 6.8.9 1.3-.4 2.7-1.1 3.8-2.2.2-.2.4-.1.3.2-.4 1.2-1.2 2.6-2.4 3.4-2.3 1.5-5.4 1.3-8 .2-.5-.2-.6-.8-.5-1.1.1-.2.3-.2.5-.1z" fill="#FF9900"/><path d="M16.9 13.5c-.1.2-.3.3-.6.2-.7-.3-1.5-.4-2.4-.3l-.2.1c-.2 0-.3-.2-.1-.3.9-.6 2.3-.9 3.2-.6.3.1.3.6.1.9z" fill="#232F3E"/><circle cx="12" cy="10" r="4.2" fill="#232F3E"/><path d="M10 10.9c.4.7 1 1.1 1.8 1.1.8 0 1.4-.4 1.8-1 .1-.1.2-.1.2 0-.2 1.3-1.2 2.4-2.5 2.4s-2.3-1-2.4-2.3c0-.1.1-.2.2-.2z" fill="#fff"/></svg>';

const _mobikwikLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="6" fill="#E7384D"/><text x="12" y="16" text-anchor="middle" font-size="10" font-weight="700" fill="#fff" font-family="Arial, sans-serif">M</text></svg>';

const _freechargeLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="6" fill="#5A2D82"/><path d="M13 5l-5 8h3.5l-1.5 6 6-9h-3.5z" fill="#fff"/></svg>';

const _paypalLogoSvg =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><rect width="24" height="24" rx="6" fill="#F8FAFC"/><path d="M8.2 17.5h2l.7-4.4h2.1c2.2 0 3.7-1.3 4-3.3.1-.9 0-1.7-.5-2.4-.5-.8-1.5-1.2-2.8-1.2H8.8c-.4 0-.7.3-.8.6L6.1 18c0 .2.1.4.3.4h2c.2 0 .4-.1.4-.4l.4-2.5h-.2z" fill="#003087"/><path d="M16 8.2c-.1-.6-.4-1-1-1.2-.4-.1-.8-.2-1.3-.2h-3.5l-.6 3.9h2.3c1.7 0 2.7-.8 2.8-2.5 0 0 .1-.1 1.3 0z" fill="#009CDE"/></svg>';
