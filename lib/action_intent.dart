import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'graph_state.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';

Future<Uint8List?> captureImage(
  GlobalKey key,
) async {
  try {
    RenderRepaintBoundary boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary;
    ui.Image image =
        await boundary.toImage(pixelRatio: 3.0); // 为了提高图像质量，可以设置更高的像素密度
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await getApplicationDocumentsDirectory();
    // 创建一个新的文件，文件名为当前时间戳
    final file = File(
        '${directory.path}/image_${DateTime.now().millisecondsSinceEpoch}.png');
    return byteData?.buffer.asUint8List();
  } catch (e) {
    print('捕获图像失败：$e');
    return null;
  }
}

void saveToDocumentsDirectory(GraphState gs, String fileName) async {
  final Directory appDocumentsDir = await getApplicationDocumentsDirectory();
  final String filePath = '${appDocumentsDir.path}/$fileName.json';
  print('save to $filePath');
  String json = jsonEncode(gs);
  File file = File(filePath);
  await file.writeAsString(json);
  return;
}

ui.Size _textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      maxLines: 20,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 50, maxWidth: 500);
  return textPainter.size;
}

Color darkenColor(Color color, [double factor = 0.3]) {
  assert(factor >= 0 && factor <= 1);

  // 将颜色的 RGB 分量乘以因子来降低亮度
  int red = (color.red * (1 - factor)).round();
  int green = (color.green * (1 - factor)).round();
  int blue = (color.blue * (1 - factor)).round();

  // 确保 RGB 分量在有效范围内
  red = red.clamp(0, 255);
  green = green.clamp(0, 255);
  blue = blue.clamp(0, 255);

  // 返回新的颜色
  return Color.fromRGBO(red, green, blue, 1);
}

Future<String> openFilePicker() async {
  try {
    // 使用FilePicker选择文件
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      // 获取所选文件的路径
      String filePath = result.files.single.path!;

      // 处理所选文件
      print('已选择文件：$filePath');
      return filePath;
    } else {
      // 用户取消了文件选择
      print('用户取消了文件选择');
    }
  } catch (e) {
    // 处理异常
    print('发生错误：$e');
  }
  return '';
}

Future<String> openSavePicker() async {
  try {
    // 使用FilePicker选择文件
    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: 'output-file.json',
    );

    if (outputFile == null) {
      // User canceled the picker
    } else {
      // 用户取消了文件选择
      print('用户保存到$outputFile');
      return outputFile;
    }
  } catch (e) {
    // 处理异常
    print('发生错误：$e');
  }
  return '';
}

Future<bool> saveToPath(String content, String path) async {
  final File file = File('$path');

  // 写入字符串到文件
  await file.writeAsString(content);
  try {
    print('文件保存成功：${file.path}');
    await file.writeAsString(content);
    return true;
    // File write successful
  } catch (e) {
    // Handle the error
    print('Error writing to file: $e');
    return false;
  }
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SaveAction extends Action<SaveIntent> {
  SaveAction(this.context, this.graphState);
  final BuildContext context;
  final GraphState? graphState;
  @override
  void invoke(SaveIntent intent) {
    if (graphState == null) {
      return;
    }
    String json = jsonEncode(graphState!);
    openSavePicker().then((file) {
      if (file == '') {
        return (null, null);
      }
      saveToPath(json, file).then((result) {
        if (result) {
          const snackBar = SnackBar(
            content: Text('保存成功'),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        } else {
          const snackBar = SnackBar(
            content: Text('保存失败'),
            duration: Duration(seconds: 2),
          );
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        }
      });
    });
  }
}

class OpenIntent extends Intent {
  const OpenIntent();
}

class OpenAction extends Action<OpenIntent> {
  OpenAction(this.context);
  final BuildContext context;
  @override
  Future<(GraphState?, String?)> invoke(OpenIntent intent) async {
    try {
      return await openFilePicker().then((path) {
        if (path == '') {
          return (null, null);
        }
        File file = File(path);
        String contents = file.readAsStringSync();
        GraphState gs = GraphState.fromJson(contents);
        //Provider.of<GraphState>(context, listen: false).swap(gs);
        (context as Element).markNeedsBuild();
        const snackBar = SnackBar(
          content: Text('打开成功'),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        return (gs, basename(path));
      });
    } catch (e) {
      SnackBar snackBar = SnackBar(
        content: Text('打开错误：$e'),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return (null, null);
    }
  }
}
