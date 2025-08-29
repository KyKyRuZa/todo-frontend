// // lib/services/yookassa_service.dart
//
// import 'dart:async';
// import 'dart:convert';
// import '../package/:http/http.dart' as http;
// import 'package:flutter/material.dart';
//
// /// Сервис для работы с платежной системой ЮKassa
// /// [ВАЖНО] Реальную логику платежей нужно реализовывать на вашем сервере!
// class YooKassaService {
//   // Конфигурация (замените на реальные данные)
//   static const String _apiUrl = 'https://api.yookassa.ru/v3/';
//   static const String _shopId = 'YOUR_SHOP_ID';
//   static const String _secretKey = 'YOUR_SECRET_KEY';
//   static const String _returnUrl = 'yourapp://payment_result'; // Ваш deep link
//
//   /// Создает платеж (заглушка для будущей реализации)
//   /// В реальном приложении этот метод должен вызывать ваш сервер
//   Future<Map<String, dynamic>> createPayment({
//     required double amount,
//     required String description,
//   }) async {
//     // TODO: Заменить на реальный вызов вашего сервера
//     debugPrint('[YooKassa] Создание платежа: $amount RUB');
//
//     // Заглушка с примером ответа (реальный ответ должен приходить с вашего сервера)
//     return {
//       'id': 'test_payment_${DateTime.now().millisecondsSinceEpoch}',
//       'status': 'pending',
//       'confirmation_url': 'https://yookassa.ru/payment-mock',
//       'amount': {'value': amount, 'currency': 'RUB'},
//       'description': description,
//     };
//   }
//
//   /// Открывает экран оплаты (заглушка)
//   Future<void> openPaymentScreen(
//       BuildContext context, {
//         required String paymentUrl,
//       }) async {
//     // TODO: Реализовать открытие WebView с платежной формой
//     debugPrint('[YooKassa] Открытие платежной формы: $paymentUrl');
//
//     // Заглушка для демонстрации
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Платежный шлюз'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Text('Здесь будет WebView с платежной формой ЮKassa'),
//             const SizedBox(height: 20),
//             Text('URL: $paymentUrl', style: const TextStyle(fontSize: 12)),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Закрыть'),
//           ),
//           TextButton(
//             onPressed: () {
//               // Эмуляция успешного платежа
//               _handlePaymentResult(context, success: true);
//               Navigator.pop(context);
//             },
//             child: const Text('Тест оплаты'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Обрабатывает результат платежа (заглушка)
//   void _handlePaymentResult(
//       BuildContext context, {
//         required bool success,
//         String? errorMessage,
//       }) {
//     // TODO: Реализовать обработку реального результата
//     debugPrint('[YooKassa] Результат платежа: ${success ? 'Успех' : 'Ошибка'}');
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(success ? 'Оплата прошла!' : 'Ошибка оплаты'),
//         content: Text(success
//             ? 'Ваш платеж успешно обработан'
//             : errorMessage ?? 'Произошла ошибка при оплате'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // --------------------------------------------------
//   // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ ДЛЯ БУДУЩЕЙ РЕАЛИЗАЦИИ
//   // --------------------------------------------------
//
//   /// Реальный метод для создания платежа (для реализации)
//   Future<Map<String, dynamic>> _realCreatePayment({
//     required double amount,
//     required String description,
//   }) async {
//     final response = await http.post(
//       Uri.parse('${_apiUrl}payments'),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
//         'Idempotence-Key': 'unique_key_${DateTime.now().millisecondsSinceEpoch}',
//       },
//       body: jsonEncode({
//         'amount': {'value': amount.toStringAsFixed(2), 'currency': 'RUB'},
//         'confirmation': {
//           'type': 'redirect',
//           'return_url': _returnUrl,
//         },
//         'description': description,
//         'capture': true,
//       }),
//     );
//
//     return jsonDecode(response.body);
//   }
//
//   /// Реальный метод для проверки статуса платежа (для реализации)
//   Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
//     // TODO: Реализовать проверку статуса через ваш сервер
//     final response = await http.get(
//       Uri.parse('${_apiUrl}payments/$paymentId'),
//       headers: {
//         'Authorization': 'Basic ${base64Encode(utf8.encode('$_shopId:$_secretKey'))}',
//       },
//     );
//
//     return jsonDecode(response.body);
//   }
// }