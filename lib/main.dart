import 'dart:ffi';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'line_painter.dart';
import 'graph_state.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'dart:math';
import 'dart:ui' as ui;

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
  // 计算起始矩形的左上角和右下角坐标
  double startX1 = startPoint.x - startRect.width / 2;
  double startY1 = startPoint.y - startRect.height / 2;
  double startX2 = startPoint.x + startRect.width / 2;
  double startY2 = startPoint.y + startRect.height / 2;

  // 计算结束矩形的左上角和右下角坐标
  double endX1 = endPoint.x - endRect.width / 2;
  double endY1 = endPoint.y - endRect.height / 2;
  double endX2 = endPoint.x + endRect.width / 2;
  double endY2 = endPoint.y + endRect.height / 2;

  // 计算避开矩形区域后的线段的起始位置和终止位置
  double newX1 = max(startX1, endX1);
  double newY1 = max(startY1, endY1);
  double newX2 = min(startX2, endX2);
  double newY2 = min(startY2, endY2);

  return LineSegment(
      vector_math.Vector2(newX1, newY1), vector_math.Vector2(newX2, newY2));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
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
  GraphView({super.key});

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Flutter Demo title'),
      ),
      body: SingleChildScrollView(
        child: ChangeNotifierProvider(
          create: (context) => GraphState(),
          child: Consumer<GraphState>(
            builder: (context, graphState, child) => Stack(
              children: [
                    // Use SomeExpensiveWidget here, without rebuilding every time.
                    if (child != null) child,
                    Container(
                      height: 1000,
                    ),
                  ] +
                  graphState.nodeLayout.entries
                      .map((MapEntry<Node, vector_math.Vector2> entry) =>
                          NodeView(
                              node: entry.key,
                              positionX: entry.value[0],
                              positionY: entry.value[1]))
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
                            startPoint: ui.Size(ls.start[0], ls.start[1]),
                            endPoint: ui.Size(ls.end[0], ls.end[1]),
                          ),
                        );
                      })
                      .toList()
                      .cast<Widget>(),
            ),
          ),
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

  void _showOptions(BuildContext context, IntegerNode node) {
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

  void _createTextEditWindow(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return Positioned(
        left: widget.positionX,
        top: widget.positionY,
        child: SizedBox(
            width: 100,
            height: 50,
            child: FloatingActionButton(
                child: GestureDetector(
                  onSecondaryTap: () {
                    _showOptions(context, IntegerNode(widget.node.hashCode));
                  },
                  child: Text(Provider.of<GraphState>(context, listen: false)
                          .titles[widget.node] ??
                      'init'),
                ),
                tooltip: 'Increment',
                onPressed: () {
                  _createTextEditWindow(context);
                })));
  }
}
