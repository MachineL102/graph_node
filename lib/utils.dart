import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

ui.Size textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      maxLines: 20,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 50, maxWidth: 300);
  return ui.Size(textPainter.size.width + 20, textPainter.size.height + 20);
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

Color getRandomColor() {
  Random random = Random(DateTime.now().millisecondsSinceEpoch);
  return Color.fromRGBO(
    random.nextInt(256), // 生成0到255之间的随机红色值
    random.nextInt(256), // 生成0到255之间的随机绿色值
    random.nextInt(256), // 生成0到255之间的随机蓝色值
    1.0, // 不透明度为1
  );
}

Color getLighterColor(Color color, double factor) {
  // 提取颜色的RGBA值
  int red = color.red;
  int green = color.green;
  int blue = color.blue;

  // 调整颜色的不透明度，使其看起来更浅
  return Color.fromRGBO(
    (red + ((255 - red) * factor)).toInt(),
    (green + ((255 - green) * factor)).toInt(),
    (blue + ((255 - blue) * factor)).toInt(),
    color.opacity, // 保持原始颜色的不透明度
  );
}
