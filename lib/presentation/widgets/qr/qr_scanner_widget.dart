import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';

/// QRスキャナーウィジェット
class QrScannerWidget extends StatefulWidget {
  final Function(String) onCodeScanned;
  final VoidCallback? onClose;

  const QrScannerWidget({
    super.key,
    required this.onCodeScanned,
    this.onClose,
  });

  @override
  State<QrScannerWidget> createState() => _QrScannerWidgetState();
}

class _QrScannerWidgetState extends State<QrScannerWidget> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    // Android の場合、ホットリロード後にカメラを再初期化
    if (Platform.isAndroid) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          controller?.pauseCamera();
          controller?.resumeCamera();
        }
      });
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('QRコードをスキャン'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.flash_off : Icons.flash_on),
            onPressed: () async {
              await controller?.toggleFlash();
              setState(() {
                _isScanning = !_isScanning;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // QRスキャナービュー
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.white,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: MediaQuery.of(context).size.width * 0.8,
            ),
          ),
          
          // 説明テキスト
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'QRコードをカメラの中央に合わせてください',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && _isScanning) {
        // スキャンを一時停止
        controller.pauseCamera();
        _isScanning = false;
        
        // 結果を処理
        widget.onCodeScanned(scanData.code!);
        
        // 画面を閉じる
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }
}