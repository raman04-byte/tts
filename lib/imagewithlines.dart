import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class TextBlockPainters extends CustomPainter {
  final List<TextBlock> textBlocks;
  final Size imageSize;
  final List<String> convertedBlocks;

  TextBlockPainters({
    required this.textBlocks,
    required this.imageSize,
    required this.convertedBlocks,
  });
  @override
  void paint(Canvas canvas, Size size) {
    mypaint(canvas, size);
  }

  void _renderText(Canvas canvas, Rect rect, final text, final right,
      final left, final paddedLeft, final top, TextBlock textBlock) {
    double minFontSize = 1;
    double maxFontSize = rect.height;
    double fontSize =
        _findOptimalFontSize(minFontSize, maxFontSize, rect, text, right, left);

    TextStyle textStyle = TextStyle(fontSize: fontSize, color: Colors.black);
    TextSpan textSpan = TextSpan(text: text, style: textStyle);
    TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
    );

    textPainter.layout(maxWidth: right - left);

    final textX = paddedLeft - 4;
    final textY = top;
    textPainter.paint(canvas, Offset(textX, textY));
  }

  double _findOptimalFontSize(double minFontSize, double maxFontSize, Rect rect,
      final text, final right, final left) {
    double epsilon = 0.1;

    while ((maxFontSize - minFontSize) > epsilon) {
      double midFontSize = (minFontSize + maxFontSize) / 2;
      if (_isOverflowing(midFontSize, rect, text, right, left)) {
        maxFontSize = midFontSize;
      } else {
        minFontSize = midFontSize;
      }
    }

    return minFontSize;
  }

  bool _isOverflowing(
      double fontSize, Rect rect, final text, final right, final left) {
    TextStyle textStyle = TextStyle(fontSize: fontSize);
    TextSpan textSpan = TextSpan(text: text, style: textStyle);

    TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.justify,
      maxLines: (rect.height / fontSize).floor(),
    );

    textPainter.layout(maxWidth: right - left);

    return textPainter.didExceedMaxLines ||
        textPainter.size.height > rect.height;
  }

  void mypaint(Canvas canvas, Size size) async {
    double padding = 4.0;
    final bgcolor = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    for (var textBlock in textBlocks) {
      final rect = Rect.fromLTRB(
        textBlock.boundingBox.left,
        textBlock.boundingBox.top,
        textBlock.boundingBox.right,
        textBlock.boundingBox.bottom,
      );

      final left = rect.left * size.width / imageSize.width;
      final top = rect.top * size.height / imageSize.height;
      final right = rect.right * size.width / imageSize.width;
      final bottom = rect.bottom * size.height / imageSize.height;

      final paddedLeft = left + padding;
      canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), bgcolor);

      _renderText(
          canvas,
          Rect.fromLTRB(left, top, right, bottom),
          convertedBlocks[textBlocks.indexOf(textBlock)],
          right,
          left,
          paddedLeft,
          top,
          textBlock);
    }
  }

  @override
  bool shouldRepaint(TextBlockPainters oldDelegate) {
    return oldDelegate.textBlocks != textBlocks ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.convertedBlocks != convertedBlocks;
  }
}

class TextBlockPainter extends CustomPainter {
  final TextBlock textBlock;
  final Size imageSize;
  final List<String> completeString;
  final String wordToBeSpoken;
  TextBlockPainter(
      {required this.textBlock,
      required this.imageSize,
      required this.completeString,
      required this.wordToBeSpoken});
  @override
  void paint(Canvas canvas, Size size) {
    mypaint(canvas, size);
  }

  void mypaint(Canvas canvas, Size size) async {
    final bgcolor = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTRB(
      textBlock.boundingBox.left,
      textBlock.boundingBox.top,
      textBlock.boundingBox.right,
      textBlock.boundingBox.bottom,
    );

    final left = rect.left * size.width / imageSize.width;
    final top = rect.top * size.height / imageSize.height;
    final right = rect.right * size.width / imageSize.width;
    final bottom = rect.bottom * size.height / imageSize.height;
    canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), bgcolor);
    final highlightText = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    for (String element in completeString) {
      if (wordToBeSpoken == element) {
        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), highlightText);
      }
    }
  }

  @override
  bool shouldRepaint(TextBlockPainter oldDelegate) {
    return oldDelegate.textBlock != textBlock ||
        oldDelegate.imageSize != imageSize;
  }
}

class ImageWithTextLines extends StatefulWidget {
  final String imagePath;
  final List<TextBlock> textBlock;
  List<TextLine> textLines = [];
  ImageWithTextLines(
      {super.key, required this.imagePath, required this.textBlock});
  @override
  State<ImageWithTextLines> createState() => _ImageWithTextLinesState();
}

class _ImageWithTextLinesState extends State<ImageWithTextLines> {
  List<String> convertedLanguageBlockList = [];
  List<TextLine> textLines = [];
  TextLine? _textLine;
  bool isSpeaking = false;
  FlutterTts flutterTts = FlutterTts();
  List<TextBlock> convertedLanguageTextBlock = [];
  TextBlock? currentBlock;
  List<String> completeString = [];
  String wordToBeSpoken = '';
  @override
  void initState() {
    super.initState();
    extractLinesFromBlocks(widget.textBlock);
    textIntoBlockConverter();
    extractLines();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();
    _setEngines();

    flutterTts.setStartHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Playing");
        }
      });
    });

    flutterTts.setInitHandler(() {
      setState(() {
        if (kDebugMode) {
          print("TTS Initialized");
        }
      });
    });
    flutterTts.setCompletionHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Complete");
        }
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Canceling");
        }
      });
    });

    flutterTts.setPauseHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Paused");
        }
      });
    });

    flutterTts.setContinueHandler(() {
      setState(() {
        if (kDebugMode) {
          print("Continued");
        }
      });
    });
    flutterTts.setErrorHandler((msg) {
      setState(() {
        if (kDebugMode) {
          print("error: $msg");
        }
      });
    });
    flutterTts.setProgressHandler((text, start, end, word) {
      completeString = text.split(' ');
      wordToBeSpoken = word;
      for (String element in completeString) {
        if (kDebugMode) {
          print("String is playing");
          print(element);
        }
      }
    });
  }

  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
    if (kDebugMode) {
      print("Await Completion");
    }
  }

  Future<dynamic> _setEngines() async {
    String engine = await flutterTts.getDefaultEngine;
    flutterTts.setEngine(engine);
  }

  void textIntoBlockConverter() async {
    for (var textBB in widget.textBlock) {
      OnDeviceTranslator onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: TranslateLanguage.english,
          targetLanguage: TranslateLanguage.hindi);
      String response = await onDeviceTranslator.translateText(textBB.text);
      convertedLanguageBlockList.add(response);
      if (kDebugMode) {
        print(response);
      }
      setState(() {});
    }
  }

  Future<void> speaklines(int currentindex) async {
    while (currentindex < widget.textBlock.length) {
      setState(() {
        if (kDebugMode) {
          print("state changes");
        }
        currentBlock = widget.textBlock[currentindex];
      });
      await flutterTts
          .speak(convertedLanguageBlockList[currentindex])
          .then((value) {
        if (isSpeaking) {
          currentindex++;
        }
      });
      if (!isSpeaking) {
        return;
      }
    }
    return;
  }

  void extractLines() {
    for (var textBB in widget.textBlock) {
      List<TextLine> lines = textBB.lines;
      for (var ll in lines) {
        widget.textLines.add(ll);
      }
    }
  }

  void extractLinesFromBlocks(List<TextBlock> textBlock) {
    textLines =
        textBlock.expand((block) => block.lines).map((line) => line).toList();
  }

  TextBlock? _findTappedTextBlock(Offset localPath, Size size, Size imageSize) {
    for (var textblock in widget.textBlock) {
      final rect = Rect.fromLTRB(
          textblock.boundingBox.left * size.width / imageSize.width,
          textblock.boundingBox.top * size.height / imageSize.height,
          textblock.boundingBox.right * size.width / imageSize.width,
          textblock.boundingBox.bottom * size.height / imageSize.height);
      if (rect.contains(localPath)) {
        return textblock;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Appbar")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          flutterTts.stop();
          isSpeaking = false;
        },
      ),
      body: FutureBuilder<Size>(
        future: _getImageSize(widget.imagePath),
        builder: (BuildContext context, AsyncSnapshot<Size> snapshot) {
          if (snapshot.hasData) {
            return SizedBox(
                child: Stack(
              fit: StackFit.expand,
              children: [
                Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.fill,
                ),
                if (convertedLanguageBlockList.length ==
                    widget.textBlock.length)
                  CustomPaint(
                    painter: TextBlockPainters(
                      textBlocks: widget.textBlock,
                      imageSize: snapshot.data!,
                      convertedBlocks: convertedLanguageBlockList,
                    ),
                  ),
                if (currentBlock != null)
                  CustomPaint(
                    painter: TextBlockPainter(
                        imageSize: snapshot.data!,
                        textBlock: currentBlock!,
                        completeString: completeString,
                        wordToBeSpoken: wordToBeSpoken),
                  ),
                GestureDetector(
                  onTapUp: (TapUpDetails details) async {
                    final RenderBox box =
                        context.findRenderObject() as RenderBox;
                    final Offset localPosition =
                        box.globalToLocal(details.globalPosition);
                    final Size size = box.size;
                    final tappedTextBlock = _findTappedTextBlock(
                        localPosition, size, snapshot.data!);
                    if (tappedTextBlock != null) {
                      if (isSpeaking) {
                        isSpeaking = false;
                        if (kDebugMode) {
                          print('stopping');
                        }
                        await flutterTts.stop().then((value) async {
                          await Future.delayed(const Duration(milliseconds: 500));
                          isSpeaking = true;
                          speaklines(widget.textBlock.indexOf(tappedTextBlock));
                        });
                      } else {
                        isSpeaking = true;
                        speaklines(widget.textBlock.indexOf(tappedTextBlock));
                      }
                    }
                  },
                ),
              ],
            ));
          } else {
            return const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 255, 238, 87),
              ),
            );
          }
        },
      ),
    );
  }

  Future<Size> _getImageSize(String imagePath) {
    final completer = Completer<Size>();
    final image = Image.file(File(imagePath));
    image.image.resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo image, bool synchronousCall) {
          final size =
              Size(image.image.width.toDouble(), image.image.height.toDouble());
          completer.complete(size);
        },
      ),
    );
    return completer.future;
  }

  Widget _textFromInput(int start, int end) => Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.only(top: 25.0, left: 25.0, right: 25.0),
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(children: <TextSpan>[]),
      ));
}
