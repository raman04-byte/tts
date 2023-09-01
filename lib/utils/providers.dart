import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
class ChangeLines with ChangeNotifier{
TextBlock? _textblock;
TextBlock? get textBlock{
    return _textblock;
}
set textblock(TextBlock? newblock){
    _textblock=newblock;
    notifyListeners();
}
}