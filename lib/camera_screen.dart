import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:google_mlkit_language_id/google_mlkit_language_id.dart';
import 'package:url_launcher/url_launcher.dart';

import 'product_result_screen.dart';
import 'ai_service.dart';
import 'analysis_card.dart';
import 'ai_result.dart';
import 'language_model.dart';

enum CameraMode { photo, textScan, sceneExplorer, qrScan, productSearch }

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  final MobileScannerController _qrController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late CameraDescription _selectedCamera;

  final AIService _aiService = AIService();

  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final LanguageIdentifier _languageIdentifier = LanguageIdentifier(confidenceThreshold: 0.5);

  CameraMode _currentMode = CameraMode.photo;
  FlashMode _flashMode = FlashMode.off;
  double _currentZoom = 1.0, _minZoom = 1.0, _maxZoom = 1.0, _baseZoom = 1.0;
  bool _isCameraInitialized = false;

  bool _showShutterEffect = false;
  bool _isQrDialogShowing = false;
  bool _isActivelyScanningQr = false;

  Map<String, dynamic>? _analysisData;
  bool _isProcessing = false;
  XFile? _lastCapturedImage;

  @override
  void initState() {
    super.initState();
    _selectedCamera = widget.cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first);
    _initializeCamera(_selectedCamera);
  }

  @override
  void dispose() {
    _controller?.dispose();
    _qrController.dispose();
    _textRecognizer.close();
    _languageIdentifier.close();
    super.dispose();
  }

  Future<void> _initializeCamera(CameraDescription cameraDescription) async {
    await _qrController.stop();
    if (_controller != null) {
      await _controller!.dispose();
    }
    _controller = CameraController(cameraDescription, ResolutionPreset.high, enableAudio: false);
    try {
      await _controller!.initialize();
      _minZoom = await _controller!.getMinZoomLevel();
      _maxZoom = await _controller!.getMaxZoomLevel();
      await _controller!.setFlashMode(FlashMode.off);
      _flashMode = FlashMode.off;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
        }
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
      _currentZoom = _minZoom;
    });
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open link: $e')),
        );
      }
    }
  }

  void _flipCamera() {
    if (widget.cameras.length < 2) return;
    final currentCameraIndex = widget.cameras.indexOf(_selectedCamera);
    final newCameraIndex = (currentCameraIndex + 1) % widget.cameras.length;
    final newCamera = widget.cameras[newCameraIndex];
    setState(() {
      _isCameraInitialized = false;
      _selectedCamera = newCamera;
    });
    _initializeCamera(newCamera);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentMode == CameraMode.qrScan) {
      return Scaffold(backgroundColor: Colors.black, body: _buildQrScannerView());
    }
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onScaleStart: (details) { _baseZoom = _currentZoom; },
        onScaleUpdate: (details) async {
          final double newZoom = (_baseZoom * details.scale).clamp(_minZoom, _maxZoom);
          await _controller!.setZoomLevel(newZoom);
          setState(() => _currentZoom = newZoom);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_analysisData != null && _lastCapturedImage != null)
              Image.file(File(_lastCapturedImage!.path), fit: BoxFit.cover, width: double.infinity, height: double.infinity)
            else
              Center(child: CameraPreview(_controller!)),
            _buildTopControls(),
            _buildBottomControls(),
            if (_showShutterEffect)
              Container(color: Colors.black.withOpacity(0.6)),
            if (_analysisData != null)
              AnalysisCard(
                title: _analysisData!['title'],
                analysisData: _analysisData!['data'],
                actionButton: _analysisData!['action'],
                onClose: () => setState(() {
                  _analysisData = null;
                  _lastCapturedImage = null;
                }),
              ),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQrScannerView() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _qrController,
          onDetect: (capture) {
            if (_isActivelyScanningQr && capture.barcodes.isNotEmpty && !_isQrDialogShowing) {
              setState(() {
                _isActivelyScanningQr = false;
                _isQrDialogShowing = true;
              });
              final barcode = capture.barcodes.first;
              final String qrValue = barcode.rawValue ?? 'No data';
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => AlertDialog(
                  title: const Text('QR Code Found!'),
                  content: Text(qrValue),
                  actions: [
                    if (qrValue.startsWith('http'))
                      TextButton(
                        child: const Text('Open Link'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _launchUrl(qrValue);
                          setState(() { _isQrDialogShowing = false; });
                        },
                      ),
                    TextButton(
                      child: const Text('Copy'),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: qrValue));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                    TextButton(
                      child: const Text('Close'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() { _isQrDialogShowing = false; });
                      },
                    ),
                  ],
                ),
              );
            }
          },
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _isActivelyScanningQr ? "Scanning for QR Code..." : "Tap the shutter button to scan",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 40,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : _flashMode == FlashMode.auto ? Icons.flash_auto : Icons.flash_on,
                color: Colors.white,
                size: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildModeButton(CameraMode.qrScan, "Scan"),
                  _buildModeButton(CameraMode.sceneExplorer, "Describe"),
                  _buildModeButton(CameraMode.photo, "Photo"),
                  _buildModeButton(CameraMode.textScan, "Translate"),
                  _buildModeButton(CameraMode.productSearch, "Shopping"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 64, height: 64),
                GestureDetector(
                  onTap: _isProcessing ? null : () {
                    if (_currentMode == CameraMode.qrScan) {
                      setState(() { _isActivelyScanningQr = true; });
                    } else {
                      _onCapturePressed();
                    }
                  },
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? Colors.grey : Colors.white,
                      border: Border.all(color: Colors.grey, width: 4),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _flipCamera,
                  icon: const Icon(Icons.flip_camera_ios_outlined,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(CameraMode mode, String text) {
    bool isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () async {
        if (_currentMode == mode) return;
        if (mode == CameraMode.qrScan) {
          await _controller?.dispose();
          _controller = null;
        } else if (_currentMode == CameraMode.qrScan && _controller == null) {
          await _initializeCamera(_selectedCamera);
        }
        setState(() {
          _currentMode = mode;
          _analysisData = null;
          _lastCapturedImage = null;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.deepPurpleAccent : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _toggleFlash() async {
  if (_currentMode == CameraMode.qrScan) {
    await _qrController.toggleTorch();
    final bool isTorchOn = _qrController.torchEnabled; 
    setState(() {
      _flashMode = isTorchOn ? FlashMode.torch : FlashMode.off;
    });
  } else if (_controller != null) {
    FlashMode newMode;
    if (_flashMode == FlashMode.off) newMode = FlashMode.auto;
    else if (_flashMode == FlashMode.auto) newMode = FlashMode.torch;
    else newMode = FlashMode.off;
    
    try {
      await _controller!.setFlashMode(newMode);
      setState(() { _flashMode = newMode; });
    } on CameraException catch (e) {
      print("Error setting flash mode: $e");
    }
  }
}
  Future<void> _onCapturePressed() async {
    if ((_currentMode != CameraMode.photo && _controller == null) || (_controller != null && !_controller!.value.isInitialized) || _isProcessing) return;
    try {
      setState(() {
        _isProcessing = true;
        _analysisData = null;
        _lastCapturedImage = null;
      });
      final image = await _controller!.takePicture();
      if (!mounted) return;
      setState(() {
        _lastCapturedImage = image;
      });
      if (_flashMode == FlashMode.torch) {
        await _controller!.setFlashMode(FlashMode.off);
        setState(() { _flashMode = FlashMode.off; });
      }
      if (_currentMode == CameraMode.photo) {
        setState(() { _showShutterEffect = true; });
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() { _showShutterEffect = false; });
        await Gal.putImage(image.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Image saved to gallery!')));
        }
        setState(() { _lastCapturedImage = null; });
      } else if (_currentMode == CameraMode.textScan) {
        final recognizedText = await _textRecognizer.processImage(InputImage.fromFilePath(image.path));
        final originalText = recognizedText.text.trim();
        if (originalText.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No text found.')));
          setState(() { _lastCapturedImage = null; });
          return;
        }
        
        final detectedLanguageCode = await _languageIdentifier.identifyLanguage(originalText);
        final detectedLanguage = supportedLanguages.firstWhere((lang) => lang.code == detectedLanguageCode, orElse: () => supportedLanguages.first).name;

        AIResult translationResult = await _aiService.translateText(originalText, from: detectedLanguage, to: 'English');
        
        if (translationResult.isQuotaError) {
          if (!mounted) return;
          final wantsToSwitch = await _showQuotaDialog();
          if (wantsToSwitch == true) {
            translationResult = await _aiService.translateTextWithBackup(originalText, from: detectedLanguage, to: 'English');
          } else {
            setState(() { _lastCapturedImage = null; });
            return;
          }
        }
        setState(() {
          _analysisData = {
            'title': 'Text Translation',
            'data': {
              'Detected Language': detectedLanguage.trim(),
              'Original Text': originalText,
              'Translation': translationResult.text?.trim() ?? translationResult.errorMessage ?? 'Translation failed',
            },
            'action': null,
          };
        });
      } else if (_currentMode == CameraMode.sceneExplorer) {
        const prompt = "Concisely describe this scene in one sentence.";
        AIResult result = await _aiService.analyzeImageWithGemini(image.path, prompt);
        if (result.isQuotaError) {
          if(!mounted) return;
          final wantsToSwitch = await _showQuotaDialog();
          if (wantsToSwitch == true) {
            result = await _aiService.analyzeImageWithBackup(image.path);
          } else {
            setState(() { _lastCapturedImage = null; });
            return;
          }
        }
        setState(() {
          _analysisData = {
            'title': 'Visual Details',
            'data': {'Description': result.text?.trim() ?? result.errorMessage ?? "Analysis failed"},
            'action': null,
          };
        });
      } else if (_currentMode == CameraMode.productSearch) {
        const prompt = "Identify the product in this image. Respond with only the brand and name.";
        AIResult result = await _aiService.analyzeImageWithGemini(image.path, prompt);
        if (result.isQuotaError) {
          if(!mounted) return;
          final wantsToSwitch = await _showQuotaDialog();
          if (wantsToSwitch == true) {
            result = await _aiService.analyzeImageWithBackup(image.path);
          } else {
            setState(() { _lastCapturedImage = null; });
            return;
          }
        }
        final productName = result.text ?? 'Unknown Product';
        setState(() {
          _analysisData = {
            'title': 'Product Identified',
            'data': {'Product': productName.trim()},
            'action': ActionButtonData(
              label: 'Search Online',
              icon: Icons.search,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductResultScreen(productName: productName.trim()),
                  ),
                );
              },
            ),
          };
        });
      }
    } catch (e) {
      print("Error capturing or processing image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred.')));
      setState(() { _lastCapturedImage = null; });
    } finally {
      if (mounted) {
        setState(() { _isProcessing = false; });
      }
    }
  }

  Future<bool?> _showQuotaDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Primary AI Unavailable"),
        content: const Text("The daily quota for the primary AI may have been reached. Would you like to switch to the backup model for this request?"),
        actions: [
          TextButton(child: const Text("Cancel"), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text("Use Backup"), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );
  }
}