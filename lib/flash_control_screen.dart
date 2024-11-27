import 'dart:async';

import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';

enum FlashMode { off, on, constant, rapid, sos, wave }

class TorchController extends StatefulWidget {
  const TorchController({super.key});

  @override
  State<TorchController> createState() => _TorchControllerState();
}

class _TorchControllerState extends State<TorchController> {
  FlashMode _currentMode = FlashMode.off;
  Timer? _flashTimer;
  double _waveIntensity = 0.0;
  bool _increasing = true;
  int _waveStep = 0;
  final int _waveTotalSteps = 10;

  @override
  void dispose() {
    _stopFlashTimer();
    super.dispose();
  }

  void _stopFlashTimer() {
    _flashTimer?.cancel();
    _flashTimer = null;
  }

  Future<void> _toggleFlash(FlashMode mode) async {
    try {
      // Dừng timer hiện tại nếu có
      _stopFlashTimer();
      await TorchLight.disableTorch();

      if (_currentMode == mode) {
        setState(() {
          _currentMode = FlashMode.off;
          _waveStep = 0;
          _waveIntensity = 0.0;
        });
        return;
      }

      setState(() {
        _currentMode = mode;
        _waveStep = 0;
        _waveIntensity = 0.0;
      });

      switch (mode) {
        case FlashMode.on:
          await TorchLight.enableTorch();
          break;
        case FlashMode.constant:
          _startConstantFlash();
          break;
        case FlashMode.rapid:
          _startRapidFlash();
          break;
        case FlashMode.sos:
          _startSOSFlash();
          break;
        case FlashMode.wave:
          _startWaveFlash();
          break;
        case FlashMode.off:
          break;
      }
    } on Exception catch (e) {
      _showErrorDialog('Không thể điều khiển đèn flash: ${e.toString()}');
    }
  }

  void _startConstantFlash() {
    _flashTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        if (timer.tick % 2 == 0) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
      } catch (e) {
        _stopFlashTimer();
        _showErrorDialog('Lỗi khi nháy đèn: ${e.toString()}');
      }
    });
  }

  void _startRapidFlash() {
    _flashTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      try {
        if (timer.tick % 2 == 0) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }
      } catch (e) {
        _stopFlashTimer();
        _showErrorDialog('Lỗi khi nháy đèn: ${e.toString()}');
      }
    });
  }

  void _startSOSFlash() {
    int step = 0;
    List<int> pattern = [
      200, 200, 200, // 3 nháy ngắn
      500, 500, 500, // 3 nháy dài
      200, 200, 200 // 3 nháy ngắn
    ];

    _flashTimer =
        Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      try {
        if (step >= pattern.length * 2) {
          step = 0;
          await TorchLight.disableTorch();
          await Future.delayed(const Duration(milliseconds: 1000));
        } else {
          if (step % 2 == 0) {
            await TorchLight.enableTorch();
            await Future.delayed(Duration(milliseconds: pattern[step ~/ 2]));
          } else {
            await TorchLight.disableTorch();
            await Future.delayed(const Duration(milliseconds: 200));
          }
          step++;
        }
      } catch (e) {
        _stopFlashTimer();
        _showErrorDialog('Lỗi khi nháy đèn SOS: ${e.toString()}');
      }
    });
  }

  void _startWaveFlash() {
    _flashTimer =
        Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (!mounted) return;

      try {
        if (_increasing) {
          _waveStep++;
          if (_waveStep >= _waveTotalSteps) {
            _increasing = false;
          }
        } else {
          _waveStep--;
          if (_waveStep <= 0) {
            _increasing = true;
          }
        }

        // Tính toán intensity dựa trên bước hiện tại
        _waveIntensity = _waveStep / _waveTotalSteps;

        // Chỉ bật đèn flash khi intensity > 0.5
        if (_waveIntensity > 0.5) {
          await TorchLight.enableTorch();
        } else {
          await TorchLight.disableTorch();
        }

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        _stopFlashTimer();
        if (mounted) {
          _showErrorDialog('Lỗi khi tạo hiệu ứng sóng: ${e.toString()}');
        }
      }
    });
  }

  Future<void> _showErrorDialog(String message) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          _currentMode != FlashMode.off ? Icons.flash_on : Icons.flash_off,
          size: 50,
          color: _getIconColor(),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            _buildModeButton('Bật/Tắt', FlashMode.on),
            _buildModeButton('Nháy Liên Tục', FlashMode.constant),
            _buildModeButton('Nháy Nhanh', FlashMode.rapid),
            _buildModeButton('SOS', FlashMode.sos),
            _buildModeButton('Sóng', FlashMode.wave),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton(String label, FlashMode mode) {
    bool isActive = _currentMode == mode;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? Colors.blue : null,
        foregroundColor: isActive ? Colors.white : null,
      ),
      onPressed: () => _toggleFlash(mode),
      child: Text(label),
    );
  }

  Color _getIconColor() {
    switch (_currentMode) {
      case FlashMode.off:
        return Colors.grey;
      case FlashMode.wave:
        // Đảm bảo opacity luôn nằm trong khoảng [0.0, 1.0]
        double opacity = _waveIntensity.clamp(0.0, 1.0);
        return Colors.blue.withOpacity(opacity);
      default:
        return Colors.yellow;
    }
  }
}
