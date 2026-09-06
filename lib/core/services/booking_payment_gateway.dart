import 'dart:async';

import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../network/api_client.dart';
import '../../features/client/presentation/widgets/fake_payment_checkout.dart';

class BookingPaymentGateway {
  BookingPaymentGateway({
    required SskApiClient apiClient,
    this.merchantName = 'GadiDost Logistics',
  }) : _apiClient = apiClient;

  final SskApiClient _apiClient;
  final String merchantName;

  Future<Map<String, dynamic>> payBooking({
    required String accessToken,
    required String bookingId,
    required String payType,
    String? contact,
    String? email,
    String description = 'Booking payment',
    BuildContext? context,
  }) async {
    final orderResponse = await _apiClient.createPaymentOrder(
      accessToken: accessToken,
      bookingId: bookingId,
      payType: payType,
    );
    final order = _extractOrder(orderResponse);
    if (order.isEmpty) {
      throw const ApiException('Could not start payment.');
    }

    final orderId = _readString(order, const ['orderId', 'order_id']);
    final provider = _readString(order, const ['provider']).toLowerCase();
    if (orderId.isEmpty) {
      throw const ApiException('Payment order is missing an order id.');
    }

    if (provider != 'razorpay') {
      final checkoutContext = context;
      if (checkoutContext != null && checkoutContext.mounted) {
        final completed = await showFakePaymentCheckout(
          context: checkoutContext,
          amount: _readDouble(order, const ['amount']),
          description: description,
        );
        if (!completed) {
          throw const ApiException('Payment cancelled.');
        }
      }
      final verifyResponse = await _apiClient.verifyPayment(
        accessToken: accessToken,
        bookingId: bookingId,
        orderId: orderId,
        payType: payType,
        paymentMode: provider.isEmpty ? 'fake' : provider,
      );
      return _extractBooking(verifyResponse);
    }

    final keyId = _readString(order, const ['keyId', 'key_id']);
    final amount = _readDouble(order, const ['amount']);
    final currency = _readString(order, const ['currency']).isEmpty
        ? 'INR'
        : _readString(order, const ['currency']);
    if (keyId.isEmpty) {
      throw const ApiException('Payment gateway key is missing.');
    }
    if (amount <= 0) {
      throw const ApiException('Payment amount is invalid.');
    }

    final completer = Completer<Map<String, dynamic>>();
    final razorpay = Razorpay();

    Future<void> handleSuccess(PaymentSuccessResponse response) async {
      try {
        final verifyResponse = await _apiClient.verifyPayment(
          accessToken: accessToken,
          bookingId: bookingId,
          orderId: orderId,
          payType: payType,
          paymentMode: 'razorpay',
          gatewayPayload: {
            'razorpay_payment_id': response.paymentId,
            'razorpay_signature': response.signature,
          },
        );
        if (!completer.isCompleted) {
          completer.complete(_extractBooking(verifyResponse));
        }
      } catch (error, stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(_normalizeError(error), stackTrace);
        }
      }
    }

    void handleError(PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      final message = response.message?.trim().isEmpty == true
          ? 'Payment failed.'
          : response.message?.trim() ?? 'Payment failed.';
      completer.completeError(ApiException(message, statusCode: response.code));
    }

    void handleExternalWallet(ExternalWalletResponse response) {
      debugPrint('Razorpay external wallet selected: ${response.walletName}');
    }

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (
      PaymentSuccessResponse response,
    ) {
      unawaited(handleSuccess(response));
    });
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handleError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWallet);

    try {
      razorpay.open({
        'key': keyId,
        'amount': (amount * 100).round(),
        'currency': currency,
        'order_id': orderId,
        'name': merchantName,
        'description': description,
        if (contact != null && contact.trim().isNotEmpty)
          'prefill': {
            'contact': contact.trim(),
            if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
          },
      });
      return await completer.future;
    } catch (error, stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(_normalizeError(error), stackTrace);
      }
      rethrow;
    } finally {
      razorpay.clear();
    }
  }

  Map<String, dynamic> _extractOrder(Map<String, dynamic> response) {
    final data = _asMap(response['data']);
    final order = _asMap(data['order']);
    if (order.isNotEmpty) {
      return order;
    }
    final directOrder = _asMap(response['order']);
    if (directOrder.isNotEmpty) {
      return directOrder;
    }
    return data;
  }

  Map<String, dynamic> _extractBooking(Map<String, dynamic> response) {
    final data = _asMap(response['data']);
    final booking = _asMap(data['booking']);
    if (booking.isNotEmpty) {
      return booking;
    }
    final directBooking = _asMap(response['booking']);
    if (directBooking.isNotEmpty) {
      return directBooking;
    }
    return data;
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return <String, dynamic>{};
  }

  String _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  double _readDouble(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return 0;
  }

  Object _normalizeError(Object error) {
    if (error is ApiException) {
      return error;
    }
    return ApiException(error.toString().replaceFirst('Exception: ', ''));
  }
}
