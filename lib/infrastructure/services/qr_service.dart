import 'dart:convert';
import 'dart:typed_data';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';

/// QRコードサービス
/// QRコードの生成と処理を担当
class QrService {
  static QrService? _instance;

  QrService._();

  /// シングルトンインスタンスを取得
  static QrService get instance {
    _instance ??= QrService._();
    return _instance!;
  }

  /// 家族連携用QRコードデータを生成
  String generateFamilyLinkData({
    required String familyId,
    required String inviteCode,
  }) {
    try {
      final data = {
        'type': 'family_link',
        'family_id': familyId,
        'invite_code': inviteCode,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expires_at': DateTime.now()
            .add(AppConstants.qrCodeExpiration)
            .millisecondsSinceEpoch,
      };

      final jsonString = jsonEncode(data);
      final base64String = base64Encode(utf8.encode(jsonString));
      
      return '${AppConstants.qrCodePrefix}$base64String';
    } catch (e) {
      throw DataFormatException(
        message: 'QRコードデータの生成に失敗しました: $e',
      );
    }
  }

  /// QRコードデータを解析
  Map<String, dynamic>? parseFamilyLinkData(String qrData) {
    try {
      // プレフィックスを確認
      if (!qrData.startsWith(AppConstants.qrCodePrefix)) {
        return null;
      }

      // プレフィックスを除去してデコード
      final base64String = qrData.substring(AppConstants.qrCodePrefix.length);
      final jsonString = utf8.decode(base64.decode(base64String));
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // 必要なフィールドの存在確認
      if (!_validateQrData(data)) {
        return null;
      }

      // 有効期限の確認
      final expiresAt = data['expires_at'] as int;
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return null; // 期限切れ
      }

      return data;
    } catch (e) {
      return null; // 無効なQRコード
    }
  }

  /// QRコードデータの妥当性を検証
  bool _validateQrData(Map<String, dynamic> data) {
    return data.containsKey('type') &&
        data.containsKey('family_id') &&
        data.containsKey('invite_code') &&
        data.containsKey('timestamp') &&
        data.containsKey('expires_at') &&
        data['type'] == 'family_link';
  }

  /// QRコードウィジェットを生成
  Widget generateQrWidget({
    required String data,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(10),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor ?? Colors.black,
      ),
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor ?? Colors.black,
      ),
    );
  }

  /// QRコードを画像として生成
  Future<Uint8List> generateQrImage({
    required String data,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
  }) async {
    try {
      final qrValidationResult = QrValidator.validate(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
      );

      if (!qrValidationResult.isValid) {
        throw DataFormatException(
          message: 'QRコードデータが無効です',
        );
      }

      final painter = QrPainter(
        data: data,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        dataModuleStyle: QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: foregroundColor ?? Colors.black,
        ),
        eyeStyle: QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: foregroundColor ?? Colors.black,
        ),
      );

      final picRecorder = ui.PictureRecorder();
      final canvas = Canvas(picRecorder);
      painter.paint(canvas, Size(size, size));

      final picture = picRecorder.endRecording();
      final image = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      return byteData!.buffer.asUint8List();
    } catch (e) {
      throw DataFormatException(
        message: 'QRコード画像の生成に失敗しました: $e',
      );
    }
  }

  /// QRコードの有効期限を確認
  bool isQrCodeValid(String qrData) {
    final parsedData = parseFamilyLinkData(qrData);
    return parsedData != null;
  }

  /// QRコードの残り有効時間を取得
  Duration? getQrCodeRemainingTime(String qrData) {
    final parsedData = parseFamilyLinkData(qrData);
    if (parsedData == null) return null;

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      parsedData['expires_at'] as int,
    );
    final now = DateTime.now();

    if (now.isAfter(expiresAt)) {
      return Duration.zero;
    }

    return expiresAt.difference(now);
  }

  /// QRコードから家族IDを取得
  String? getFamilyIdFromQrCode(String qrData) {
    final parsedData = parseFamilyLinkData(qrData);
    return parsedData?['family_id'] as String?;
  }

  /// QRコードから招待コードを取得
  String? getInviteCodeFromQrCode(String qrData) {
    final parsedData = parseFamilyLinkData(qrData);
    return parsedData?['invite_code'] as String?;
  }

  /// 短縮招待コードを生成（人間が読める形式）
  String generateShortInviteCode() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return (random % 1000000).toString().padLeft(6, '0');
  }

  /// ランダムな招待コードを生成
  String generateInviteCode() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp * 31) % 1000000;
    return random.toString().padLeft(6, '0');
  }

  /// サービスを破棄
  void dispose() {
    _instance = null;
  }
}