import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(PhotoFrameApp());
}

class PhotoFrameApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PhotoSlideshow(),
    );
  }
}

class PhotoSlideshow extends StatefulWidget {
  @override
  _PhotoSlideshowState createState() => _PhotoSlideshowState();
}

class _PhotoSlideshowState extends State<PhotoSlideshow> {
  List<File> images = [];
  int currentIndex = 0;
  Timer? _timer;
  double _opacity = 1.0;

  @override
  void initState() {
    super.initState();
    _requestPermission();
    WakelockPlus.enable(); // Evita que la pantalla se apague
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable(); // Permite que la pantalla se apague cuando se cierra la app
    super.dispose();
  }

  Future<void> _requestPermission() async {
    var status = await Permission.storage.request();
    if (status.isGranted) {
      _loadImages();
    } else {
      print("🚫 Permiso denegado");
    }
  }

  Future<void> _loadImages() async {
    setState(() {
      images = [];
    });

    List<String> possibleDirs = [
      '/storage/emulated/0/DCIM/',
      '/storage/emulated/0/Pictures/',
      '/storage/emulated/0/Download/',
      '/storage/sdcard1/DCIM/',
    ];
    List<File> tempImages = [];

    for (String dirPath in possibleDirs) {
      Directory dir = Directory(dirPath);
      if (await dir.exists()) {
        print("📂 Directorio encontrado: $dirPath");
        List<FileSystemEntity> files = dir.listSync(recursive: true);
        List<File> foundImages = files.whereType<File>().where((file) {
          return file.path.toLowerCase().endsWith(".jpg") || file.path.toLowerCase().endsWith(".png");
        }).toList();
        tempImages.addAll(foundImages);
      } else {
        print("❌ No se encontró: $dirPath");
      }
    }

    if (tempImages.isNotEmpty) {
      setState(() {
        images = tempImages;
      });
      _startSlideshow();
    } else {
      print("⚠️ No se encontraron imágenes.");
    }
  }

  void _startSlideshow() {
    if (images.isNotEmpty) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 10), (timer) {
        setState(() {
          _opacity = 0.0;
        });
        Future.delayed(Duration(seconds: 1), () {
          setState(() {
            currentIndex = (currentIndex + 1) % images.length;
            _opacity = 1.0;
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: images.isEmpty
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text("Cargando imágenes...", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    )
                  : AnimatedOpacity(
                      duration: Duration(seconds: 1),
                      opacity: _opacity,
                      child: Image.file(
                        images[currentIndex],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
            ),
          ),
          if (images.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: _loadImages,
                child: Text("🔄 Recargar imágenes"),
              ),
            ),
        ],
      ),
    );
  }
}