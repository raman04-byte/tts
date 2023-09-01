import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

Future<List<TextBlock>> textRecognizer(String path) async {
  final InputImage inputImage = InputImage.fromFilePath(path);
  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.devanagiri);
  final RecognizedText recognizedText =
      await textRecognizer.processImage(inputImage);
  final textblocks=recognizedText.blocks;
  return textblocks;
  }
