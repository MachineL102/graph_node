import 'dart:ffi';
import 'package:flutter/services.dart';
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

LineSegment calculateAvoidingRectangle(vector_math.Vector2 startPoint,
    Rectangle startRect, vector_math.Vector2 endPoint, Rectangle endRect) {
  // result
  vector_math.Vector2 r1 = vector_math.Vector2(.0, .0);
  vector_math.Vector2 r2 = vector_math.Vector2(.0, .0);
  // 计算线段的斜率
  double slope = (endPoint.y - startPoint.y) / (endPoint.x - startPoint.x);
  double k1 = -50.0 / 100.0;
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
  double v3 = k1 * endPoint[0] + b1 - endPoint[1];
  double v4 = k2 * endPoint[0] + b2 - endPoint[1];
  if ((v3) > 0 && (v4) > 0) {
    r2[1] = endY2;
    r2[0] = endPoint.x - (endPoint.y - r2[1]) / slope;
  } else if ((v3) > 0 && (v4) < 0) {
    r2[0] = endX2;
    r2[1] = endPoint.y - (endPoint.x - r2[0]) * slope;
  } else if ((v3) < 0 && (v4) > 0) {
    r2[0] = endX1;
    r2[1] = endPoint.y - (endPoint.x - r2[0]) * slope;
  } else if ((v3) < 0 && (v4) < 0) {
    r2[1] = endY1;
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
      print('1111111111111');
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
    GraphState gg = GraphState.fromJson(json);
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
  void _toggleCtrlState() {
    setState(() {
      _ctrlOn = true;
    });
  }
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    setState(() {
      // print(event.logicalKey.keyLabel);
      if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
        print("ctrl key");
      }
    });
    return event.logicalKey == LogicalKeyboardKey.keyQ
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext contextRoot) {
    print("_GraphViewState build");
    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            SaveIntent(),
      },
      child: ChangeNotifierProvider(
        create: (context) => GraphState(),
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
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
                      icon: Icon(Icons.file_copy),
                      onPressed: () {
                        // 点击“文件”按钮时的操作
                        print('文件按钮被点击');
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.edit),
                      onPressed: () {
                        print('编辑按钮被点击');
                      },
                    ),
                  ],
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
                          SaveAction(context, graphState).invoke(SaveIntent());
                        },
                      ),
                    ],
                  ),
                ),
                body: Focus(
                  autofocus: true,
                  onKeyEvent: _handleKeyEvent,
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                            // Use SomeExpensiveWidget here, without rebuilding every time.
                            if (child != null) child,
                            Container(
                              height: 1000,
                            ),
                          ] +
                          graphState.nodeLayout.entries
                              .map(
                                  (MapEntry<Node, vector_math.Vector2> entry) =>
                                      NodeView(
                                          node: entry.key,
                                          positionX: entry.value[0] - 50.0,
                                          positionY: entry.value[1] - 25.0))
                              .toList()
                              .cast<Widget>() +
                          graphState.edgeList
                              .map((edge) {
                                LineSegment ls = calculateAvoidingRectangle(
                                  graphState.nodeLayout[edge.left] ??
                                      vector_math.Vector2(0, 0),
                                  Rectangle(100.0, 50.0),
                                  graphState.nodeLayout[edge.right] ??
                                      vector_math.Vector2(0, 0),
                                  Rectangle(100.0, 50.0),
                                );

                                return CustomPaint(
                                  painter: LinePainter(
                                      startPoint:
                                          ui.Size(ls.start[0], ls.start[1]),
                                      endPoint: ui.Size(ls.end[0], ls.end[1]),
                                      directed:
                                          graphState.directions[edge] ?? false),
                                );
                              })
                              .toList()
                              .cast<Widget>(),
                    ),
                  ),
                ),
              ),
            );
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

  NodeView({
    required this.node,
    required this.positionX,
    required this.positionY,
  });
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

  void _showOptions(BuildContext context, IntegerNodeWithJson node) {
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
                .addRelatedNode(node, RelationType.related);
          },
        ),
        PopupMenuItem(
          child: Text('create parent node'),
          onTap: () {
            Provider.of<GraphState>(context, listen: false)
                .addRelatedNode(node, RelationType.parent);
          },
        ),
        PopupMenuItem(
          child: Text('create child node'),
          onTap: () {
            Provider.of<GraphState>(context, listen: false)
                .addRelatedNode(node, RelationType.child);
          },
        ),
      ],
    );
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
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    setState(() {
      // print(event.logicalKey.keyLabel);
      if (event.logicalKey == LogicalKeyboardKey.controlLeft || event.logicalKey == LogicalKeyboardKey.controlRight) {
        print("node ctrl key");
      }
    });
    return event.logicalKey == LogicalKeyboardKey.keyQ
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }
  @override
  Widget build(BuildContext context) {
    GraphState gs = Provider.of<GraphState>(context, listen: true);
    return Positioned(
        left: widget.positionX,
        top: widget.positionY,
        child: Focus(
                  autofocus: true,
                  onKeyEvent: _handleKeyEvent,child:SizedBox(
            width: 100,
            height: 50,
            child: FloatingActionButton(
                child: GestureDetector(
                  onSecondaryTap: () {
                    _showOptions(
                        context, IntegerNodeWithJson(widget.node.hashCode));
                  },
                  child: Text(gs.titles[widget.node] ?? 'init'),
                ),
                tooltip: 'Increment',
                onPressed: () {
                  _createTextEditWindow(context, gs);
                }))));
  }
}
