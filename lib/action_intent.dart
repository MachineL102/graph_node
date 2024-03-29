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
import 'package:screen_capturer/screen_capturer.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' as intl;

const String dataDirName = 'GraphNote';
void checkAndCreateDirectory() async {
  // 获取应用程序文档目录
  Directory documentsDirectory = await getApplicationDocumentsDirectory();
  String dirPath = '${documentsDirectory.path}/$dataDirName';

  // 创建子目录
  Directory dir = Directory(dirPath);
  bool isDirExist = await dir.exists();

  if (!isDirExist) {
    // 如果目录不存在，则创建目录
    await dir.create(recursive: true);
    print('Directory created: $dirPath');
  } else {
    print('Directory already exists: $dirPath');
  }
}

Future<void> captureImage(GlobalKey key, String graphName) async {
  try {
    RenderRepaintBoundary boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image =
        await boundary.toImage(pixelRatio: 3.0); // 为了提高图像质量，可以设置更高的像素密度
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$graphName.png');
    Uint8List tmp = (byteData?.buffer.asUint8List())!;
    await file.writeAsBytes(tmp);
    print('图像保存到${file.path}');
    return;
  } catch (e) {
    print('捕获图像失败：$e');
    return;
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

String getCurrentTimeInSeconds() {
  DateTime now = DateTime.now();
  // 使用DateFormat将时间格式化为指定的格式，这里使用'yyyyMMddHHmmss'表示年月日时分秒
  intl.DateFormat formatter = intl.DateFormat('yyyyMMddHHmmss');
  // 格式化当前时间并返回字符串
  return formatter.format(now);
}

class ScreenshotIntent extends Intent {
  const ScreenshotIntent();
}

class ScreenshotAction extends Action<ScreenshotIntent> {
  ScreenshotAction();
  @override
  void invoke(ScreenshotIntent intent) async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String filePath =
        '${documentsDirectory.path}\\$dataDirName\\${getCurrentTimeInSeconds()}.png';
    print('filePath: $filePath');

    CapturedData? aa = (await screenCapturer.capture(
      mode: CaptureMode.region, // screen, window
      imagePath: filePath,
      copyToClipboard: true,
      silent: true,
    ));
    ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      print('Clipboard text: ${clipboardData.text}');
    } else {
      print('Clipboard is empty or doesn\'t contain text');
    }
    print('aa:$aa');
    Clipboard.setData(const ClipboardData(text: ''));
    Clipboard.setData(ClipboardData(text: "![Image](file:${filePath})"));
    clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      print('Clipboard text: ${clipboardData.text}');
    } else {
      print('Clipboard is empty or doesn\'t contain text');
    }
    if (aa != null) {
      print("ScreenshotAction");
      ClipboardData? clipboardData =
          await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData != null && clipboardData.text != null) {
        print('Clipboard text: ${clipboardData.text}');
      } else {
        print('Clipboard is empty or doesn\'t contain text');
      }
    }
  }
}
