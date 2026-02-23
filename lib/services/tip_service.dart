import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

const _kTipProductId = 'tip_0.99';

class TipService extends ChangeNotifier {
  TipService._();
  static final TipService instance = TipService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;

  bool _available = false;
  bool get available => _available;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  bool _purchasing = false;
  bool get purchasing => _purchasing;

  String? _error;
  String? get error => _error;

  bool _purchased = false;
  bool get purchased => _purchased;

  bool _loading = false;
  bool get loading => _loading;

  String _debugInfo = '';
  String get debugInfo => _debugInfo;

  Future<void> init() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    _loading = true;
    notifyListeners();

    try {
      _available = await _iap.isAvailable();
      _debugInfo = 'store available: $_available';
      if (!_available) {
        _loading = false;
        notifyListeners();
        return;
      }

      _sub = _iap.purchaseStream.listen(
        _onPurchaseUpdate,
        onDone: () => _sub?.cancel(),
        onError: (_) {},
      );

      await _queryProduct();
    } catch (e) {
      _debugInfo = 'init error: $e';
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _queryProduct() async {
    final response = await _iap.queryProductDetails({_kTipProductId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
      _debugInfo = 'product loaded: ${_product!.id} ${_product!.price}';
    } else {
      final ids = response.notFoundIDs;
      _debugInfo = 'product not found, notFoundIDs: $ids';
    }
  }

  Future<void> buy() async {
    if (_purchasing) return;

    if (_product == null) {
      _loading = true;
      notifyListeners();
      try {
        if (!_available) {
          _available = await _iap.isAvailable();
        }
        if (_available) {
          _sub ??= _iap.purchaseStream.listen(
            _onPurchaseUpdate,
            onDone: () => _sub?.cancel(),
            onError: (_) {},
          );
          await _queryProduct();
        }
      } catch (e) {
        _debugInfo = 'retry error: $e';
      }
      _loading = false;
      notifyListeners();
      if (_product == null) return;
    }

    _purchasing = true;
    _error = null;
    _purchaseHandled = false;
    notifyListeners();

    final param = PurchaseParam(productDetails: _product!);
    try {
      final launched = await _iap.buyConsumable(purchaseParam: param);
      if (!launched) {
        _purchasing = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      _purchasing = false;
      _error = e.toString();
      notifyListeners();
      return;
    }

    // 超时保护：如果 purchaseStream 在 60 秒内没有回调，自动重置状态
    Future.delayed(const Duration(seconds: 60), () {
      if (_purchasing && !_purchaseHandled) {
        _purchasing = false;
        notifyListeners();
      }
    });
  }

  bool _purchaseHandled = false;

  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final details in purchaseDetailsList) {
      if (details.productID != _kTipProductId) continue;

      _purchaseHandled = true;

      switch (details.status) {
        case PurchaseStatus.pending:
          _purchasing = true;
          _error = null;
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _purchasing = false;
          _purchased = true;
          _error = null;
          break;
        case PurchaseStatus.error:
          _purchasing = false;
          _error = details.error?.message;
          break;
        case PurchaseStatus.canceled:
          _purchasing = false;
          _error = null;
          break;
      }

      if (details.pendingCompletePurchase) {
        _iap.completePurchase(details);
      }
    }
    notifyListeners();
  }

  /// 应用回到前台时调用：如果购买弹窗已关闭但 stream 没回调，重置状态
  void resetIfStuck() {
    if (_purchasing && !_purchaseHandled) {
      _purchasing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
