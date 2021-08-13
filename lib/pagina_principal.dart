import 'dart:io';
import 'dart:typed_data';

import 'package:boletim_covid/utils.dart';
import 'package:boletim_covid/widget_to_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:flutter_tesseract_ocr/android_ios.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
//import 'package:flutter_tesseract_ocr/web.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf_merger/pdf_merger.dart';
import 'package:screenshot/screenshot.dart';

//var imagem = new Uint8List(0);

class PaginaPrincipal extends StatefulWidget {
  const PaginaPrincipal({Key? key}) : super(key: key);

  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  String textoOcr = '';

  String localidade = '';

  int txt1 = 0, txt2 = 0, txt3 = 0, txt4 = 0, txt5 = 0;
  //Create an instance of ScreenshotController

  ScreenshotController screenshotController = ScreenshotController();
  final textDetector = GoogleMlKit.vision.textDetector();
  GlobalKey key1 = new GlobalKey();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          Container(
            child: Column(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        File file = File(result.files.single.path.toString());

                        Directory tempDir = await getTemporaryDirectory();
                        String tempPath = tempDir.path;
                        await saveImageWithMask(file, tempPath);
                      } else {
                        // User canceled the picker
                      }
                    },
                    child: Text('Abrir Pdf Boletim')),
                Container(
                  child: localidade != ''
                      ? Stack(
                          children: [
                            Image.file(File(localidade)),
                            Image.asset('assets/mask.png')
                          ],
                        )
                      : Container(),
                ),
                Text(txt1.toString()),
                Text(txt2.toString()),
                Text(txt3.toString()),
                Text(txt4.toString()),
                Text(txt5.toString()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  saveImageWithMask(File file, String tempPath) async {
    CreateImageFromPDFResponse response = await PdfMerger.createImageFromPDF(
        maxHeight: 3508,
        maxWidth: 2480,
        path: file.path,
        outputDirPath: '$tempPath/image.jpg');

    if (response.status == "success") {
      //response.response for output path in List<String>
      //response.message for success message  in String

      localidade = '$tempPath/image.jpg';
      print(localidade);

      screenshotController
          .captureFromWidget(Container(
              padding: const EdgeInsets.all(30.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent, width: 5.0),
                color: Colors.redAccent,
              ),
              child: Stack(
                children: [
                  Image.file(File(localidade)),
                  Image.asset('assets/mask.png')
                ],
              )))
          .then((capturedImage) async {
        // Handle captured image
        File image =
            await File('/storage/emulated/0/Download/image.jpg').create();
        await image.writeAsBytes(capturedImage);
      });

      final inputImage =
          InputImage.fromFilePath('/storage/emulated/0/Download/image.jpg');
      final RecognisedText recognisedText =
          await textDetector.processImage(inputImage);

      String text = recognisedText.text;

      textoOcr = text;
      print(textoOcr);
      //while (textoOcr == '') {}

      txt1 = int.tryParse(textoOcr.split("\n")[0])!;

      txt2 = int.tryParse(textoOcr.split("\n")[1])!;

      txt3 = int.tryParse(textoOcr.split("\n")[2])!;

      txt4 = txt2 + txt3;

      textDetector.close();
      setState(() {});
    }
  }
}
