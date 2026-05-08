import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/utils/logger.dart';

const String kPremiumMonthlyProductId = 'com.unscripted.premium.monat';
const String kPremiumEntitlementId = 'premium';

class PremiumBillingService {
  final SupabaseClient _supabaseClient;
  final Logger _logger = getLogger('PremiumBillingService');

  static bool _configured = false;

  PremiumBillingService(this._supabaseClient);

  bool get _androidEnabled {
    const raw = String.fromEnvironment(
      'REVENUECAT_ANDROID_ENABLED',
      defaultValue: 'false',
    );
    return raw.toLowerCase() == 'true';
  }

  String _apiKeyForPlatform() {
    if (kIsWeb) return '';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return const String.fromEnvironment('REVENUECAT_IOS_API_KEY');
      case TargetPlatform.android:
        if (!_androidEnabled) return '';
        return const String.fromEnvironment('REVENUECAT_ANDROID_API_KEY');
      default:
        return '';
    }
  }

  Future<void> initialize(String userId) async {
    if (kIsWeb) {
      throw StateError('In-App-Kaeufe werden im Web nicht unterstuetzt.');
    }

    if (defaultTargetPlatform == TargetPlatform.android && !_androidEnabled) {
      throw StateError('Android In-App-Kaeufe sind noch nicht aktiviert.');
    }

    final apiKey = _apiKeyForPlatform();
    if (apiKey.isEmpty) {
      throw StateError(
        'RevenueCat API Key fehlt. Bitte per --dart-define setzen.',
      );
    }

    if (!_configured) {
      await Purchases.setLogLevel(LogLevel.debug);
      final configuration = PurchasesConfiguration(apiKey)..appUserID = userId;
      await Purchases.configure(configuration);
      _configured = true;
      _logger.i('RevenueCat configured for platform: $defaultTargetPlatform');
    }

    await Purchases.logIn(userId);
  }

  Future<void> purchaseMonthlySubscription(String userId) async {
    await initialize(userId);

    final offerings = await Purchases.getOfferings();
    final packageToBuy = _findPackage(offerings);

    if (packageToBuy == null) {
      throw StateError(
        'Kein monatliches Premium-Paket gefunden. Produkt-ID: $kPremiumMonthlyProductId',
      );
    }

    final purchaseResult = await Purchases.purchase(
      PurchaseParams.package(packageToBuy),
    );
    _assertHasPremiumEntitlement(purchaseResult.customerInfo);
  }

  Future<void> restorePurchases(String userId) async {
    await initialize(userId);
    final customerInfo = await Purchases.restorePurchases();
    _assertHasPremiumEntitlement(customerInfo);
  }

  Future<bool> refreshPremiumStatus(
    String userId, {
    int retries = 1,
    Duration retryDelay = const Duration(milliseconds: 1200),
  }) async {
    var lastStatus = false;

    for (var attempt = 0; attempt < retries; attempt++) {
      final rpcResult = await _supabaseClient.rpc(
        'fn_check_premium_status',
        params: {'p_user_id': userId},
      );

      lastStatus = rpcResult == true;
      if (lastStatus) {
        return true;
      }

      if (attempt < retries - 1) {
        await Future<void>.delayed(retryDelay);
      }
    }

    return lastStatus;
  }

  Package? _findPackage(Offerings offerings) {
    final current = offerings.current;
    if (current == null) return null;

    final monthly = current.monthly;
    if (monthly != null &&
        monthly.storeProduct.identifier == kPremiumMonthlyProductId) {
      return monthly;
    }

    for (final package in current.availablePackages) {
      if (package.storeProduct.identifier == kPremiumMonthlyProductId) {
        return package;
      }
    }

    return monthly ??
        (current.availablePackages.isNotEmpty
            ? current.availablePackages.first
            : null);
  }

  void _assertHasPremiumEntitlement(CustomerInfo customerInfo) {
    if (!customerInfo.entitlements.active.containsKey(kPremiumEntitlementId)) {
      throw StateError(
        'Kauf erfolgreich, aber Entitlement "$kPremiumEntitlementId" ist nicht aktiv.',
      );
    }
  }
}
