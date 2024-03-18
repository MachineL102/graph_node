import 'dart:ffi';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'line_painter.dart';
import 'graph_state.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'setting.dart';

// ctrl + z
// remove node
// ctrl + f format
// hash(title) as hashcode of node, auto merge the same node
// ui overlapping
// settings ui
// setting add r
// serach bar

ui.Size _textSize(String text, TextStyle style) {
  final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: TextAlign.center,
      maxLines: 20,
      textDirection: TextDirection.ltr)
    ..layout(minWidth: 50, maxWidth: 400);
  return ui.Size(textPainter.size.width + 50, textPainter.size.height + 50);
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

void showOptions(BuildContext context, List<IntegerNodeWithJson> nodes,
    TapUpDetails? details) {
  final RenderBox button = context.findRenderObject() as RenderBox;
  final Offset offset = button.localToGlobal(Offset.zero);

  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
      offset.dx + button.size.width,
      offset.dy + button.size.height,
      offset.dx + button.size.width,
      0,
    ),
    items: [
      PopupMenuItem(
        child: Text('create related node'),
        onTap: () {
          Provider.of<GraphState>(context, listen: false)
              .addRelatedNode(nodes, RelationType.related);
        },
      ),
      PopupMenuItem(
        child: Text('create parent node'),
        onTap: () {
          Provider.of<GraphState>(context, listen: false)
              .addRelatedNode(nodes, RelationType.parent);
        },
      ),
      PopupMenuItem(
        child: Text('create child node'),
        onTap: () {
          Provider.of<GraphState>(context, listen: false)
              .addRelatedNode(nodes, RelationType.child);
        },
      ),
    ],
  );
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

void main() {
  runApp(MyApp());
}

class LineSegment {
  final vector_math.Vector2 start;
  final vector_math.Vector2 end;

  LineSegment(this.start, this.end);
}

class Rectangle {
  final double width;
  final double height;

  Rectangle(this.width, this.height);
}

LineSegment calculateAvoidingRectangle(
  vector_math.Vector2 startPoint,
  Rectangle startRect,
  vector_math.Vector2 endPoint,
  Rectangle endRect,
) {
  // result
  vector_math.Vector2 r1 = vector_math.Vector2(.0, .0);
  vector_math.Vector2 r2 = vector_math.Vector2(.0, .0);
  // 计算线段的斜率
  double slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
  double k1 = -startRect.height / startRect.width;
  double k2 = -k1;

  // 计算矩形的四条边的方程
  double startX1 = startPoint.x - startRect.width / 2;
  double startY1 = startPoint.y - startRect.height / 2;
  double startX2 = startPoint.x + startRect.width / 2;
  double startY2 = startPoint.y + startRect.height / 2;

  double endX1 = endPoint.x - endRect.width / 2;
  double endY1 = endPoint.y - endRect.height / 2;
  double endX2 = endPoint.x + endRect.width / 2;
  double endY2 = endPoint.y + endRect.height / 2;

  //
  double b1 = startY1 - k1 * startX1;
  double b2 = startY2 - k2 * startX2;

  double v1 = k1 * endPoint[0] + b1 - endPoint[1];
  double v2 = k2 * endPoint[0] + b2 - endPoint[1];
  if ((v1) > 0 && (v2) > 0) {
    r1[1] = startY1;
    r1[0] = endPoint.x - (endPoint.y - r1[1]) / slope;
  } else if ((v1) > 0 && (v2) < 0) {
    r1[0] = startX1;
    r1[1] = endPoint.y - (endPoint.x - r1[0]) * slope;
  } else if ((v1) < 0 && (v2) > 0) {
    r1[0] = startX2;
    r1[1] = endPoint.y - (endPoint.x - r1[0]) * slope;
  } else if ((v1) < 0 && (v2) < 0) {
    r1[1] = startY2;
    r1[0] = endPoint.x - (endPoint.y - r1[1]) / slope;
  }

  //
  k1 = -endRect.height / endRect.width;
  k2 = -k1;
  b1 = endY1 - k1 * endX1;
  b2 = endY2 - k2 * endX2;

  double v3 = k1 * startPoint[0] + b1 - startPoint[1];
  double v4 = k2 * startPoint[0] + b2 - startPoint[1];
  if ((v3) > 0 && (v4) > 0) {
    r2[1] = endY1;
    r2[0] = endPoint.x - (endPoint.y - r2[1]) / slope;
  } else if ((v3) > 0 && (v4) < 0) {
    r2[0] = endX1;
    r2[1] = endPoint.y - (endPoint.x - r2[0]) * slope;
  } else if ((v3) < 0 && (v4) > 0) {
    r2[0] = endX2;
    r2[1] = endPoint.y - (endPoint.x - r2[0]) * slope;
  } else if ((v3) < 0 && (v4) < 0) {
    r2[1] = endY2;
    r2[0] = endPoint.x - (endPoint.y - r2[1]) / slope;
  }

  // 返回线段
  return LineSegment(
    r1,
    r2,
  );
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //ShortcutManager.init(context); // 初始化快捷键监听器
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: GraphView(),
    );
  }
}

class GraphView extends StatefulWidget {
  // Order
  // key
  GraphView({super.key});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class SaveIntent extends Intent {
  const SaveIntent();
}

class SaveAction extends Action<SaveIntent> {
  SaveAction(this.context, this.graphState);
  final BuildContext context;
  final GraphState graphState;
  @override
  void invoke(SaveIntent intent) {
    String json = jsonEncode(graphState);
    openSavePicker().then((file) {
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
  OpenAction(this.context, this.graphState);
  final BuildContext context;
  final GraphState graphState;
  @override
  void invoke(OpenIntent intent) async {
    try {
      await openFilePicker().then((path) {
        File file = File(path);
        String contents = file.readAsStringSync();
        GraphState gs = GraphState.fromJson(contents);
        Provider.of<GraphState>(context, listen: false).swap(gs);
        (context as Element).markNeedsBuild();
        const snackBar = SnackBar(
          content: Text('打开成功'),
          duration: Duration(seconds: 2),
        );
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    } catch (e) {
      SnackBar snackBar = SnackBar(
        content: Text('打开错误：$e'),
        duration: const Duration(seconds: 2),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}

class _GraphViewState extends State<GraphView> {
  bool _ctrlOn = false;
  double scrollViewHeight = 2500;
  void _toggleCtrlState() {
    setState(() {
      _ctrlOn = true;
    });
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    setState(() {
      // print(event.logicalKey.keyLabel);
      if (event.logicalKey == LogicalKeyboardKey.controlLeft ||
          event.logicalKey == LogicalKeyboardKey.controlRight) {
        print("ctrl key");
      }
    });
    return event.logicalKey == LogicalKeyboardKey.keyQ
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  bool openSetting = false;
    bool isDark = false;

  @override
  Widget build(BuildContext contextRoot) {
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            SaveIntent(),
      },
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => GraphState()),
          ChangeNotifierProvider(create: (context) => SettingState()),
        ],
        child: Consumer<GraphState>(
          builder: (context, graphState, child) {
            print("widget using Consumer rebuilt");
            return Actions(
                actions: <Type, Action<Intent>>{
                  OpenIntent: OpenAction(context, graphState),
                  SaveIntent: SaveAction(context, graphState),
                  ActivateIntent: CallbackAction<Intent>(
                    onInvoke: (Intent intent) => _toggleCtrlState(),
                  ),
                },
                child: Scaffold(
                  appBar: AppBar(
                    backgroundColor:
                        Theme.of(context).colorScheme.inversePrimary,
                    leading: Builder(
                      builder: (BuildContext context) {
                        return IconButton(
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            Scaffold.of(context).openDrawer();
                          },
                          tooltip: MaterialLocalizations.of(context)
                              .openAppDrawerTooltip,
                        );
                      },
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.settings),
                        onPressed: () {
                          setState(() {
                            openSetting = true;
                          });
                        },
                      ),
                      Container(width: 200, child: SearchAnchor(
              builder: (BuildContext context, SearchController controller) {
            return SearchBar(
              controller: controller,
              padding: const MaterialStatePropertyAll<EdgeInsets>(
                  EdgeInsets.symmetric(horizontal: 16.0)),
              onTap: () {
                controller.openView();
              },
              onChanged: (_) {
                controller.openView();
              },
              leading: const Icon(Icons.search),
              trailing: <Widget>[
                Tooltip(
                  message: 'Change brightness mode',
                  child: IconButton(
                    isSelected: isDark,
                    onPressed: () {
                      setState(() {
                        isDark = !isDark;
                      });
                    },
                    icon: const Icon(Icons.wb_sunny_outlined),
                    selectedIcon: const Icon(Icons.brightness_2_outlined),
                  ),
                )
              ],
            );
          }, suggestionsBuilder:
                  (BuildContext context, SearchController controller) {
            return List<ListTile>.generate(5, (int index) {
              final String item = 'item $index';
              return ListTile(
                title: Text(item),
                onTap: () {
                  setState(() {
                    controller.closeView(item);
                  });
                },
              );
            });
          }),
                  )],
                  ),
                  drawer: Drawer(
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: <Widget>[
                        DrawerHeader(
                          decoration: BoxDecoration(
                            color: Color.fromARGB(255, 181, 161, 193),
                          ),
                          child: Text(
                            'File',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                            ),
                          ),
                        ),
                        ListTile(
                          title: Text('open'),
                          onTap: () {
                            setState(() {
                              OpenAction(context, graphState)
                                  .invoke(OpenIntent());
                            });

                            //(contextRoot as Element).markNeedsBuild();
                          },
                        ),
                        ListTile(
                          title: Text('save'),
                          onTap: () {
                            SaveAction(context, graphState)
                                .invoke(SaveIntent());
                          },
                        ),
                      ],
                    ),
                  ),
                  body: Focus(
                    autofocus: true,
                    //onKeyEvent: _handleKeyEvent,
                    child: GestureDetector(
                      onSecondaryTapUp: (details) {
                        showOptions(
                            context,
                            graphState.selectedNodes
                                .map((e) => IntegerNodeWithJson(e))
                                .toList(),
                            details);
                      },
                      child: Consumer<SettingState>(
                        builder: (context, settingState, child) {
                          print("widget using Consumer settingState rebuilt");
                          return SingleChildScrollView(
                              child: Stack(
                                  alignment: Alignment.topCenter,
                                  children: <Widget>[
                                Stack(
                                  children: [
                                        // Use SomeExpensiveWidget here, without rebuilding every time.
                                        if (child != null) child,
                                        Container(
                                          height: scrollViewHeight,
                                        ),
                                      ] +
                                      graphState.nodeLayout.entries
                                          .map((MapEntry<Node,
                                                  vector_math.Vector2>
                                              entry) {
                                            return NodeView(
                                              node: entry.key,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
                                            );
                                          })
                                          .toList()
                                          .cast<Widget>() +
                                      graphState.edgeList
                                          .map((edge) {
                                            final String text =
                                                graphState.titles[edge.left] ??
                                                    'init';
                                            final TextStyle textStyle =
                                                GoogleFonts.getFont(
                                              settingState.fontStyle,
                                              fontSize: settingState.fontSize,
                                            );
                                            final ui.Size txtSize =
                                                _textSize(text, textStyle);
                                            final String text2 =
                                                graphState.titles[edge.left] ??
                                                    'init';
                                            final TextStyle textStyle2 =
GoogleFonts.getFont(
                                              settingState.fontStyle,
                                              fontSize: settingState.fontSize,
                                            );
                                            final ui.Size txtSize2 =
                                                _textSize(text, textStyle);
                                            LineSegment ls =
                                                calculateAvoidingRectangle(
                                              graphState
                                                      .nodeLayout[edge.left] ??
                                                  vector_math.Vector2(0, 0),
                                              Rectangle(txtSize.width,
                                                  txtSize.height),
                                              graphState
                                                      .nodeLayout[edge.right] ??
                                                  vector_math.Vector2(0, 0),
                                              Rectangle(txtSize2.width,
                                                  txtSize2.height),
                                            );

                                            return CustomPaint(
                                              painter: LinePainter(
                                                  startPoint: ui.Size(
                                                      ls.start[0], ls.start[1]),
                                                  endPoint: ui.Size(
                                                      ls.end[0], ls.end[1]),
                                                  directed: graphState
                                                          .directions[edge] ??
                                                      false),
                                            );
                                          })
                                          .toList()
                                          .cast<Widget>(),
                                ),
                                openSetting
                                    ? Padding(
                                        padding: EdgeInsets.all(
                                            60.0), // 设置四个边的边距为20.0

                                        child: Column(children: [
                                          Container(
                                              child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary, // 设置背景色为蓝色
                                                    border: Border.all(
                                                      color: Colors
                                                          .deepPurple, // Border color
                                                      width:
                                                          3.0, // Border width
                                                    ),
                                                  ),
                                                  child: Padding(
                                                      padding: EdgeInsets.all(
                                                          20.0), // 设置四个边的边距为20.0

                                                      child: Column(children: [
                                                        Row(children: [
                                                          Icon(
                                                            Icons.settings,
                                                            size: 24.0,
                                                            color: Colors
                                                                .deepPurple,
                                                          ),
                                                          SizedBox(
                                                            width: 10,
                                                          ),
                                                          Text('settings'),
                                                          Spacer(),
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.close),
                                                            onPressed: () {
                                                              setState(() {
                                                                openSetting =
                                                                    false;
                                                              });
                                                            },
                                                          ),
                                                        ]),
                                                        Divider(
                                                          // 绘制分界线
                                                          height: 20, // 设置分界线高度
                                                          color: Colors
                                                              .grey, // 设置分界线颜色
                                                        ),
                                                        Stack(children: [
                                                          Container(
                                                            height: 400,
                                                            //color: Color.fromARGB(255, 181, 161, 193),
                                                            child: Center(
                                                              child:
                                                                  SecondRoute(),
                                                            ),
                                                          ),
                                                        ]),
                                                      ]))))
                                        ]))
                                    : SizedBox(
                                        width: 0,
                                        height: 0,
                                      ),
                              ]));
                        },
                      ),
                    ),
                  ),
                ));
          },
        ),
      ),
    );
  }
}

class NodeView extends StatefulWidget {
  Node node;
  double positionX = 0.0;
  double positionY = 0.0;
  Color color;
  NodeView({required this.node, required this.color});
  @override
  State<NodeView> createState() => _NodeViewState();
}

class _NodeViewState extends State<NodeView> {
  late TextEditingController _titleController;
  late TextEditingController _mainTextController;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
        text: Provider.of<GraphState>(context, listen: false)
            .titles[widget.node]);
    _mainTextController = TextEditingController(
        text: Provider.of<GraphState>(context, listen: false)
            .mainTexts[widget.node]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mainTextController.dispose();
    super.dispose();
  }

  void _createTextEditWindow(BuildContext context, GraphState gs) {
    _titleController.text = gs.titles[widget.node] ?? "panic";
    _mainTextController.text = gs.mainTexts[widget.node] ?? "panic";
    String pre_title = _titleController.text;
    String pre_main_text = _mainTextController.text;

    showDialog(
      context: context,
      builder: (context2) {
        return AlertDialog(
          title: Text('Edit Node'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: _mainTextController,
                decoration: InputDecoration(labelText: 'Main Text'),
                maxLines: null,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  Provider.of<GraphState>(context, listen: false)
                      .titles[widget.node] = _titleController.text;
                  Provider.of<GraphState>(context, listen: false)
                      .mainTexts[widget.node] = _mainTextController.text;
                });
                Navigator.of(context2).pop();
              },
              child: Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _titleController.text = pre_title;
                  _mainTextController.text = pre_main_text;
                });
                Navigator.of(context2).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
  //   setState(() {
  //     // print(event.logicalKey.keyLabel);
  //     if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
  //       print("node ctrl key");
  //     }
  //   });
  //   return event.logicalKey == LogicalKeyboardKey.keyQ
  //       ? KeyEventResult.handled
  //       : KeyEventResult.ignored;
  // }
  HardwareKeyboard hardwareKeyboard = HardwareKeyboard();
  //Color colorState =;
  @override
  Widget build(BuildContext context) {
    GraphState gs = Provider.of<GraphState>(context, listen: true);
    SettingState settingState = Provider.of<SettingState>(context, listen: true);
    final String text = gs.titles[widget.node] ?? 'init';
    final TextStyle textStyle = GoogleFonts.getFont(
                                              settingState.fontStyle,
                                              fontSize: settingState.fontSize,
                                            );
    final ui.Size txtSize = _textSize(text, textStyle);

    widget.positionX = gs.nodeLayout[widget.node]![0] - txtSize.width / 2;
    widget.positionY = gs.nodeLayout[widget.node]![1] - txtSize.height / 2;

    return Positioned(
        left: widget.positionX,
        top: widget.positionY,
        child: GestureDetector(
            onSecondaryTap: () {
              if (gs.selectedNodes.length != 0) {
                showOptions(
                    context,
                    gs.selectedNodes
                        .map((e) => IntegerNodeWithJson(e))
                        .toList(),
                    null);
              } else {
                showOptions(
                    context, [IntegerNodeWithJson(widget.node.hashCode)], null);
              }
            },
            child: SizedBox(
                width: txtSize.width,
                height: txtSize.height,
                child: FloatingActionButton(
                    backgroundColor: widget.color,
                    hoverElevation: 8.0,
                    heroTag: "btn${widget.node.hashCode}",
                    child: Text(
                      text,
                      style: textStyle,
                    ),
                    tooltip: 'Increment',
                    onPressed: () {
                      if (HardwareKeyboard.instance.isControlPressed) {
                        print("ctrl+click node");
                        gs.selectedNodes.add(widget.node.hashCode);
                        print(gs.selectedNodes);
                        setState(() {
                          widget.color = darkenColor(widget.color);
                        });
                      } else {
                        _createTextEditWindow(context, gs);
                      }
                    }))));
  }
}
