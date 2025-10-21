import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import '../services/live_ovce_recognition_service.dart';

class LiveDetekceScreen extends StatefulWidget {
  final bool isSmartAddMode;
  
  const LiveDetekceScreen({
    super.key,
    this.isSmartAddMode = false,
  });

  @override
  _LiveDetekceScreenState createState() => _LiveDetekceScreenState();
}

class _LiveDetekceScreenState extends State<LiveDetekceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isDetecting = false;
  List<OvceMatch> _detectedOvce = [];
  final LiveOvceRecognitionService _recognitionService = LiveOvceRecognitionService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _recognitionService.initialize();
    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          imageFormatGroup: ImageFormatGroup.nv21,
        );

        await _cameraController!.initialize();
        
        if (mounted) {
          setState(() {});
          _startImageStream();
        }
      }
    } catch (e) {
      print('❌ Chyba při inicializaci kamery: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba při spuštění kamery: $e')),
      );
    }
  }

  void _startImageStream() {
    if (_cameraController != null) {
      _cameraController!.startImageStream((CameraImage image) {
        if (!_isDetecting) {
          _isDetecting = true;
          _processImage(image);
        }
      });
    }
  }

  Future<void> _processImage(CameraImage image) async {
    try {
      final matches = await _recognitionService.recognizeOvceInFrame(image);
      
      if (mounted) {
        setState(() {
          _detectedOvce = matches.where((match) => match.confidence > 0.3).toList();
        });
      }
    } catch (e) {
      print('❌ Chyba při zpracování obrazu: $e');
    } finally {
      _isDetecting = false;
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _recognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Detekce & Foto Analýza'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          // Přidáme tlačítko pro detekci z fotky přímo do AppBar
          IconButton(
            icon: Icon(Icons.photo_library),
            onPressed: _detectFromPhoto,
            tooltip: 'Detekce z fotky',
          ),
          IconButton(
            icon: Icon(Icons.help_outline),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: _cameraController == null || !_cameraController!.value.isInitialized
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Spouštím kameru...'),
                  SizedBox(height: 32),
                  // Přidáme tlačítko detekce z fotky i když kamera nefunguje
                  FloatingActionButton.extended(
                    heroTag: "photo_detect_fallback",
                    backgroundColor: Colors.blue,
                    icon: Icon(Icons.photo_library),
                    label: Text('Detekce z fotky'),
                    onPressed: _detectFromPhoto,
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Camera Preview
                Positioned.fill(
                  child: CameraPreview(_cameraController!),
                ),
                
                // Overlay s detekovanými ovcemi
                Positioned.fill(
                  child: CustomPaint(
                    painter: DetectionOverlayPainter(_detectedOvce),
                  ),
                ),
                
                // Info panel
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Card(
                    color: Colors.black87,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Live Detekce',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Detekováno: ${_detectedOvce.length} ovcí',
                            style: TextStyle(color: Colors.white70),
                          ),
                          if (_detectedOvce.isNotEmpty)
                            ...(_detectedOvce.take(3).map((match) => Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                '• ${match.ovce.usiCislo} (${(match.confidence * 100).toInt()}%)',
                                style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 12,
                                ),
                              ),
                            ))),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Tlačítka
                Positioned(
                  bottom: 40,
                  left: 20,
                  right: 20,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Horní řada - detekce z fotky
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          FloatingActionButton.extended(
                            heroTag: "photo_detect",
                            backgroundColor: Colors.blue,
                            icon: Icon(Icons.photo_library),
                            label: Text('Detekce z fotky'),
                            onPressed: _detectFromPhoto,
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Spodní řada - live ovládání
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          FloatingActionButton(
                            heroTag: "switch_camera",
                            backgroundColor: Colors.white,
                            child: Icon(Icons.switch_camera, color: Colors.black),
                            onPressed: _switchCamera,
                          ),
                          FloatingActionButton.extended(
                            heroTag: "capture",
                            backgroundColor: Colors.green,
                            icon: Icon(Icons.camera_alt),
                            label: Text('Zachytit'),
                            onPressed: _captureAndAnalyze,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _switchCamera() async {
    if (_cameras != null && _cameras!.length > 1) {
      final currentIndex = _cameras!.indexOf(_cameraController!.description);
      final nextIndex = (currentIndex + 1) % _cameras!.length;
      
      await _cameraController!.dispose();
      
      _cameraController = CameraController(
        _cameras![nextIndex],
        ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() {});
        _startImageStream();
      }
    }
  }

  Future<void> _captureAndAnalyze() async {
    if (widget.isSmartAddMode) {
      // V smart add mode - udělat fotku a vrátit data pro formulář
      await _smartCapture();
    } else {
      // Normální režim - ukázat detekované ovce
      if (_detectedOvce.isNotEmpty) {
        final bestMatch = _detectedOvce.reduce((a, b) => 
          a.confidence > b.confidence ? a : b);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Nejlepší shoda'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ušní číslo: ${bestMatch.ovce.usiCislo}'),
                Text('Jméno: ${bestMatch.ovce.jmeno}'),
                Text('Plemeno: ${bestMatch.ovce.plemeno}'),
                Text('Spolehlivost: ${(bestMatch.confidence * 100).toInt()}%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, bestMatch.ovce);
                },
                child: Text('Vybrat'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Žádné ovce nebyly detekovány')),
        );
      }
    }
  }

  /// Smart capture pro přidávání nové ovce
  Future<void> _smartCapture() async {
    try {
      if (_cameraController == null || !_cameraController!.value.isInitialized) {
        throw Exception('Kamera není inicializována');
      }

      // Udělat fotku
      final image = await _cameraController!.takePicture();
      
      // Pokusit se detekovat charakteristiky ovce (základní analýza)
      final detectedData = await _analyzeNewSheep(image.path);
      
      // Vrátit data pro formulář
      Navigator.pop(context, {
        'photoPath': image.path,
        'detectedData': detectedData,
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Chyba při pořizování fotky: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Analyzuje novou ovci a pokusí se detekovat základní charakteristiky
  Future<Map<String, dynamic>> _analyzeNewSheep(String imagePath) async {
    // Zde by byla pokročilá analýza - zatím vrátíme základní data
    final now = DateTime.now();
    
    return {
      'kategorie': 'OTHER', // Výchozí kategorie
      'plemeno': 'Neznámé', // Výchozí plemeno
      'datumRegistrace': now.toIso8601String(),
      'poznamky': 'Přidáno pomocí live detekce dne ${now.day}.${now.month}.${now.year}',
    };
  }

  Future<void> _detectFromPhoto() async {
    try {
      // Zobrazit dialog pro výběr zdroje
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Vyberte zdroj fotky'),
          content: Text('Odkud chcete načíst fotku pro detekci?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Zrušit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.gallery),
              child: Text('Galerie'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, ImageSource.camera),
              child: Text('Fotoaparát'),
            ),
          ],
        ),
      );

      if (source == null) return;

      // Vybrat fotku
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 100,
      );

      if (image == null) return;

      // Zobrazit loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Analyzuji fotku...'),
            ],
          ),
        ),
      );

      // Analyzovat fotku
      final matches = await _recognitionService.recognizeOvceInPhoto(image.path);

      // Zavřít loading dialog
      if (mounted) Navigator.pop(context);

      // Zobrazit výsledky
      if (matches.isNotEmpty) {
        final bestMatch = matches.reduce((a, b) => 
          a.confidence > b.confidence ? a : b);

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('🎯 Detekce z fotky'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nalezeno ${matches.length} shod:', 
                  style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                ...matches.take(3).map((match) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• ${match.ovce.usiCislo} (${(match.confidence * 100).toInt()}%)',
                    style: TextStyle(
                      color: match == bestMatch ? Colors.green : Colors.black87,
                      fontWeight: match == bestMatch ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                )),
                SizedBox(height: 16),
                Text('Nejlepší shoda:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Ušní číslo: ${bestMatch.ovce.usiCislo}'),
                Text('Plemeno: ${bestMatch.ovce.plemeno}'),
                Text('Spolehlivost: ${(bestMatch.confidence * 100).toInt()}%'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Zavřít'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, bestMatch.ovce);
                },
                child: Text('Vybrat ovci'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('❌ Žádná shoda'),
            content: Text('Na fotce nebyla rozpoznána žádná ovce z databáze.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Zavřít loading dialog při chybě
      if (mounted) Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba při analýze fotky: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('📖 Nápověda'),
        content: Text(
          '🎥 LIVE DETEKCE:\n'
          'Nasměrujte kameru na ovce a systém je automaticky rozpozná.\n\n'
          '📸 DETEKCE Z FOTKY:\n'
          'Vyberte fotku z galerie nebo pořiďte novou pro analýzu.\n\n'
          '🎯 VÝSLEDKY:\n'
          '• Zelené rámečky = rozpoznané ovce\n'
          '• Čísla = spolehlivost detekce (%)\n'
          '• Zachytit = uloží nejlepší live shodu\n'
          '• Minimální spolehlivost: 30%\n\n'
          '💡 TIP: Text na ušních značkách má nejvyšší přesnost!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Zavřít'),
          ),
        ],
      ),
    );
  }
}

class DetectionOverlayPainter extends CustomPainter {
  final List<OvceMatch> detectedOvce;

  DetectionOverlayPainter(this.detectedOvce);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 0; i < detectedOvce.length; i++) {
      final match = detectedOvce[i];
      
      // Simulujeme bounding box (v reálné aplikaci by to bylo z ML Kit)
      final rect = Rect.fromLTWH(
        50.0 + (i * 100.0),
        100.0 + (i * 50.0),
        120.0,
        80.0,
      );

      // Kreslíme rámeček
      canvas.drawRect(rect, paint);

      // Kreslíme text s informacemi
      textPainter.text = TextSpan(
        text: '${match.ovce.usiCislo}\n${(match.confidence * 100).toInt()}%',
        style: TextStyle(
          color: Colors.green,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 40));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}