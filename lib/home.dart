import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pigeon.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _imageFile;
  late ModelObjectDetection _objectModel;
  String? _imagePrediction;
  List? _prediction;
  File? _image;
  ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];

  Future loadModel() async {
    // String pathImageModel = "assets/models/model_classification.pt";
    //String pathCustomModel = "assets/models/custom_model.ptl";
    String pathObjectDetectionModel = "assets/best_cavity.torchscript";
    try {
      // _imageModel = await PytorchLite.loadClassificationModel(
      //     pathImageModel, 224, 224,
      //     labelPath: "assets/labels/label_classification_imageNet.txt");
      //_customModel = await PytorchLite.loadCustomModel(pathCustomModel);
      _objectModel = await PytorchLite.loadObjectDetectionModel(
          pathObjectDetectionModel, 1, 640, 640,
          labelPath: "assets/cavity.txt");
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadModel();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cat Dog Identifier")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Container(
                height: 150,
                width: 300,
                child: objDetect.isNotEmpty
                  ? _image == null
                      ? Text('No image selected.')
                      : _objectModel.renderBoxesOnImage(_image!, objDetect)
                  : _image == null
                      ? Text('No image selected.')
                      : Image.file(_image!),
              ),
            ),
            Center(
              child: Visibility(
                visible: _imagePrediction != null,
                child: Text("$_imagePrediction"),
              ),
            ),
            ElevatedButton(
                onPressed: () {
                  runObjectDetection();
                },
                child: Icon(Icons.camera)),
          ],
        ),
      ),
    );
  }

  // Future detection(File image) async {
  //   // final api = Uri.parse("http://192.168.100.12//v1/object-detection/yolov7");
  //   print("attempting to connect to server……");
  //   var stream = new http.ByteStream(DelegatingStream.typed(image.openRead()));
  //   var length = await image.length();
  //   print(length);
  //   var uri = Uri.parse("http://192.168.100.12//v1/object-detection/yolov7");
  //   print("connection established.");
  //   var request = new http.MultipartRequest(“POST”, uri);
  //   var multipartFile = new http.MultipartFile('file', stream, length, filename: basename(image.path));
  //   //contentType: new MediaType(‘image’, ‘png’));
  //   request.files.add(multipartFile);
  //   var response = await request.send();
  //   print(response.statusCode);
  // }
  // uploadImageToServer(File imageFile) async {
  //   final url = Uri.parse('http://192.168.100.12:5000//v1/object-detection/yolov7');
  //   http.post(url, body: {
  //     "image": base64UrlEncode(await imageFile.readAsBytesSync())
  //   }).then((Response response) {
  //     print("Response body: ${response.body}");
  //   });
  // }

  Future runObjectDetection() async {
    //pick a random image
    final XFile? image = await _picker.pickImage(source: ImageSource.camera, maxWidth: 200, maxHeight: 200);
    objDetect = await _objectModel.getImagePrediction(
        await File(image!.path).readAsBytes(),
        minimumScore: 0.1,
        IOUThershold: 0.3);
    objDetect.forEach((element) {
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    });
    setState(() {
      //this.objDetect = objDetect;
      _image = File(image.path);
    });
  }
}
