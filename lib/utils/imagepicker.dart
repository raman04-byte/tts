import 'package:image_picker/image_picker.dart';
import 'package:tts_f/utils/imagecropper.dart';
Future<String> imagePickers(context,ImageSource source)async{
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source:source);
  String path=await croppedfile(context,image!.path);
  return path;
}