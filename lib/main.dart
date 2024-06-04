import 'dart:convert';
import 'dart:io';

import 'package:ed_dicom_viewer/ed_dicom_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  final _dicomViewerPlugin = EdDicomViewer();

  EdDicomModel? response;
  Uint8List? decodedData;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  Future<File> _getImageFileFromAssets(String path) async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    var filePath = "$tempPath/$path";
    var file = File(filePath);
    if (file.existsSync()) {
      return file;
    } else {
      final byteData = await rootBundle.load(path);
      final buffer = byteData.buffer;
      await file.create(recursive: true);
      return file.writeAsBytes(
          buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
  }

  loadData() async {
    String filePath = "assets/CT000003.dcm";
    File file = await _getImageFileFromAssets(filePath);
    print(file.path);
    await _dicomViewerPlugin.getViewDicom(file.path).then((value) {
      response = EdDicomModel.fromJson(jsonDecode(value));
      setState(() {
        decodedData = Uint8List.fromList(response!.decodedBytes);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (decodedData != null) ...[
              SizedBox(
                width: 300,
                height: 300,
                child: Image.memory(decodedData!),
              ),
            ],
            Text("Patient Name: ${response?.patientName}"),
            Text("Patient Age: ${response?.patientAge}"),
            Text("Patient Gender: ${response?.patientGender}"),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
