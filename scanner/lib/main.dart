import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:scanner/button_widgets.dart';
import 'package:scanner/error_widget.dart';
import 'package:scanner/text_display.dart';
import 'package:url_launcher/url_launcher.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';


// Initialize and defines the c++ functions that will be used
class FFIBridge {
  static bool initialize() {
    nativeApiLib = (DynamicLibrary.open('libapi.so')); // android and linux
    final _add = nativeApiLib // define add function natively
        .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('add');
    add = _add.asFunction<int Function(int, int)>(); // define add function for flutter
    final _cap = nativeApiLib.lookup< // define captitalize function natively
        NativeFunction<Pointer<Utf8> Function(Pointer<Utf8>)>>('capitalize');
    _capitalize = _cap.asFunction<Pointer<Utf8> Function(Pointer<Utf8>)>(); // define capitalize function 
    return true;
  }

  // declares all of the abovementioned variables 
  static late DynamicLibrary nativeApiLib;
  static late Function add;
  static late Function _capitalize;
  static String capitalize(String str) {
    final _str = str.toNativeUtf8();
    Pointer<Utf8> res = _capitalize(_str);
    calloc.free(_str);
    return res.toDartString();
  }
}

void main() {
  FFIBridge.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QR Code Scanner',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scanner(title: "QR Code Scanner"),
    );
  }
}

// Scanner Widget
class Scanner extends StatefulWidget {
  const Scanner({super.key, required this.title});
  final String title;

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController( // Creates the camera controller
    autoStart: false,
    torchEnabled: false,
    useNewCameraSelector: true,
  );

  Barcode? _barcode; // Data immediately captured from the qr-code scanner will be transferred here
  Barcode? _currentBarcode; // Used to prevent constant function calls if the barcode remains the same
  StreamSubscription<Object?>? _subscription;

  FutureOr goBack(dynamic value) { // Going back from text menu (restarts camera and _currentBarcode
    startScanner();
    setState(() {
      _currentBarcode = null;
    });
  }

  Future<void> _launchUrl(value) async { // takes an inputted barcode and launches a webpage based on it
    Uri url = Uri.parse(value.displayValue!);
    try { // tries to launch url using the launchUrl function. If url is text and not a link to a webpage, then push to a new flutter page
      await launchUrl(url);
      setState(() {
        _currentBarcode = null;
      });
    } on PlatformException {
      stopScanner();

      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => TextDisplay(text: value.displayValue)))
          .then(goBack);
    }
  }

  Widget _buildPopup(BuildContext context) { // Creates the popup menu to confirm link open. Will give preview of content/link
    return AlertDialog(
        title: const Text('Open Link?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentBarcode!.displayValue!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              _launchUrl(_currentBarcode);
              Navigator.of(context).pop();
            },
            child: const Text('Open'),
          ),
        ]);
  }

  Widget _buildBarcode(Barcode? value) { // caption at the bottom that displays the currently scanned value/placeholder text
    if (value == null) {
      return const Text(
        'Scan something!',
        overflow: TextOverflow.fade,
        style: TextStyle(color: Colors.white),
      );
    }

    return Text(
      value.displayValue ?? 'No display value.',
      overflow: TextOverflow.fade,
      style: const TextStyle(color: Colors.white),
    );
  }

  void _handleBarcode(BarcodeCapture barcodes) { // Function called after detecting a barcode. Saves barcode values and prompts popup
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
        if ((_barcode != null) &&
            (_barcode?.displayValue != _currentBarcode?.displayValue)) {
          setState(() {
            _currentBarcode = _barcode;
          });
          print(_currentBarcode!.displayValue);
          showDialog(
              context: context,
              builder: (BuildContext context) => _buildPopup(context)).then(
            (value) => setState(() {
              _currentBarcode = null;
            }),
          );
          // _launchUrl(_currentBarcode!);
        }
      });
    }
  }

  void startScanner() { // Starts qr code scanner
    _subscription = controller.barcodes.listen(_handleBarcode);
    unawaited(controller.start());
  }

  void stopScanner() { // Stops qr code scanner
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(controller.stop());
  }

  @override
  void initState() { // runs when the app initially starts
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _subscription = controller.barcodes.listen(_handleBarcode);

    unawaited(controller.start());
  }

  @override // turns the camera on/off depending on the state of the app (in focus or not)
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!controller.value.isInitialized) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        stopScanner();
      case AppLifecycleState.resumed:
        startScanner();
      case AppLifecycleState.inactive:
        stopScanner();
    }
  }

  @override
  Widget build(BuildContext context) { // Creates UI for application
    return Scaffold(
      appBar: AppBar(title: const Text('With controller')),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(children: [
            Text('capitalize flutter=${FFIBridge.capitalize('flutter')}'),
            Text('1+2=${FFIBridge.add(1, 2)}'),
          ]),
          MobileScanner( // Camera interface
            controller: controller,
            errorBuilder: (context, error, child) {
              return ScannerErrorWidget(error: error);
            },
            fit: BoxFit.contain,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [ // Options menu at the bottom
                  ToggleFlashlightButton(controller: controller),
                  StartStopMobileScannerButton(controller: controller),
                  Expanded(
                      child: Center(child: _buildBarcode(_currentBarcode))),
                  SwitchCameraButton(controller: controller),
                  AnalyzeImageFromGalleryButton(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Future<void> dispose() async { // Clears at the end of the app use
    // Stop listening to lifecycle changes.
    WidgetsBinding.instance.removeObserver(this);
    // Stop listening to the barcode events.
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Dispose the widget itself.
    super.dispose();
    // Finally, dispose of the controller.
    await controller.dispose();
  }
}
