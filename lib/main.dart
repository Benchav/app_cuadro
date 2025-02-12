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

  @override
  void initState() {
    super.initState();
    _requestPermission();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();
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
        List<FileSystemEntity> files = dir.listSync(recursive: true);
        List<File> foundImages = files.whereType<File>().where((file) {
          return file.path.toLowerCase().endsWith(".jpg") || file.path.toLowerCase().endsWith(".png");
        }).toList();
        tempImages.addAll(foundImages);
      }
    }

    if (tempImages.isNotEmpty) {
      setState(() {
        images = tempImages;
      });
      _startSlideshow();
    }
  }

  void _startSlideshow() {
    if (images.isNotEmpty) {
      _timer?.cancel();
      _timer = Timer.periodic(Duration(seconds: 10), (timer) {
        _nextImage();
      });
    }
  }

  void _nextImage() {
    setState(() {
      currentIndex = (currentIndex + 1) % images.length;
    });
  }

  void _previousImage() {
    setState(() {
      currentIndex = (currentIndex - 1 + images.length) % images.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! < 0) {
            _nextImage();
          } else if (details.primaryVelocity! > 0) {
            _previousImage();
          }
        },
        child: Column(
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
                    : AnimatedSwitcher(
                        duration: Duration(seconds: 3),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0.2, 0.0),
                                end: Offset(0.0, 0.0),
                              ).animate(animation),
                              child: child,
                            ),
                          );
                        },
                        child: Image.file(
                          images[currentIndex],
                          key: ValueKey<int>(currentIndex),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}