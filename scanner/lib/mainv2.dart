import 'dart:ffi';
import 'dart:io';
import 'package:flutter/material.dart';

// Define the path to the native library
final DynamicLibrary nativeLib = Platform.isWindows
    ? DynamicLibrary.open('api_gmp.dll') // Adjust the path as needed
    : Platform.isLinux
        ? DynamicLibrary.open('libapi_gmp.so')
        : Platform.isMacOS
            ? DynamicLibrary.open('libapi_gmp.dylib')
            : throw UnsupportedError('This platform is not supported.');

// Define the native function signature
typedef NativeFunctionType = Int32 Function(Int32);
typedef DartFunctionType = int Function(int);

// Lookup the native function from the library
final DartFunctionType myFunction = nativeLib
    .lookupFunction<NativeFunctionType, DartFunctionType>('myFunction');

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Native FFI Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Native FFI Example'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _callNativeFunction,
          child: Text('Call Native Function'),
        ),
      ),
    );
  }

  void _callNativeFunction() {
    try {
      final int result = myFunction(42);
      print('Result from native function: $result');
    } catch (e) {
      print('Error calling native function: $e');
    }
  }
}
