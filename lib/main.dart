import 'dart:ffi';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'line_painter.dart';
import 'graph_state.dart';

void main() {
  runApp(MyApp());
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
  String title = "node title";
  String mainText = "node main text";

  @override
  State<GraphView> createState() => _GraphViewState();
}

class _GraphViewState extends State<GraphView> {
  late TextEditingController _titleController;
  late TextEditingController _mainTextController;
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _mainTextController = TextEditingController(text: widget.mainText);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mainTextController.dispose();
    super.dispose();
  }

  void _showOptions(BuildContext context, List<double> node) {
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
          child: Text('create Button'),
          onTap: () {
            Provider.of<GraphState>(context, listen: false).addRelatedNode(node);
          },
        ),
        PopupMenuItem(child: Text('create Text')),
        // Add more PopupMenuItems as needed
      ],
    );
  }

  void _createTextEditWindow(BuildContext context) {
    String pre_title = widget.title;
    String pre_main_text = widget.mainText;

    showDialog(
      context: context,
      builder: (context) {
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
                  widget.title = _titleController.text;
                  widget.mainText = _mainTextController.text;
                });
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _titleController.text = pre_title;
                  _mainTextController.text = pre_main_text;
                });
                Navigator.of(context).pop();
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
                  graphState.graph_nodes
                      .map((node) => Positioned(
                          left: node[0],
                          top: node[1],
                          child: SizedBox(
                              width: 100,
                              height: 50,
                              child: FloatingActionButton(
                                  child: GestureDetector(
                                    onSecondaryTap: () {
                                      _showOptions(context, node);
                                    },
                                    child: const Text('new node'),
                                  ),
                                  tooltip: 'Increment',
                                  onPressed: () {
                                    _createTextEditWindow(context);
                                  }))))
                      .toList(),
            ),
          ),
        ),
      ),
    );
  }
}
