import 'package:flutter/material.dart';
import 'package:graph_note/home_widget.dart';
import 'graph_state.dart';
import 'package:graph_layout/graph_layout.dart';
import 'node_view.dart';
import 'action_intent.dart';
import 'package:path/path.dart';
import 'package:vector_math/vector_math.dart' as vector_math;
import 'setting.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'line_painter.dart';
import 'dart:ui' as ui;
import 'utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

// ctrl + z ctrl + f format；
// remove white margin, which can use nodeRadius = Screensize/2
// remove node
// hash(title) as hashcode of node, auto merge the same node
// setting add r
// serach bar
// moveable node
// layout size = k * node count
// multi-subgraph
// persistent state

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => SettingState()),
        ],
        child: Consumer<SettingState>(builder: (context, settingState, child) {
          return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                useMaterial3: true,

                // Define the default brightness and colors.
                colorScheme: ColorScheme.fromSeed(
                  seedColor: settingState.mainColor,
                  // ···
                  //brightness: Brightness.light,
                ),

                // Define the default `TextTheme`. Use this to specify the default
                // text styling for headlines, titles, bodies of text, and more.
                textTheme: TextTheme(
                  displayLarge: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                  // ···
                  titleLarge: GoogleFonts.oswald(
                    fontSize: 30,
                    fontStyle: FontStyle.italic,
                  ),
                  bodyMedium: GoogleFonts.merriweather(),
                  displaySmall: GoogleFonts.pacifico(),
                ),
              ),
              home: MultiGraph());
        }));
  }
}

class MultiGraph extends StatefulWidget {
  const MultiGraph({super.key});

  @override
  State<MultiGraph> createState() => _MultiGraphState();
}

class _MultiGraphState extends State<MultiGraph> {
  int _selectedIndex = 0;
  @override
  void initState() {
    _selectedIndex = 0;
    _tabIndex = 0;
    _Graphs = [];
    fontSizes = generateList(10.0, 50.0, 1.0);
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<String?> _showNameDialog(BuildContext context) async {
    String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();

        return AlertDialog(
          title: Text('Enter Your Note Name'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter your Note name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                String? enteredName = controller.text;
                Navigator.of(context).pop(enteredName);
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (name != null) {
      return name;
    } else {
      return null;
    }
  }

  int _tabIndex = 0;
  List<Graph> _Graphs = [];
  late List<double> fontSizes;
  @override
  Widget build(BuildContext context_root) {
    return Shortcuts(
        shortcuts: <ShortcutActivator, Intent>{
          const SingleActivator(LogicalKeyboardKey.keyS, control: true):
              SaveIntent(),
        },
        child: Consumer<SettingState>(builder: (context, settingState, child) {
          print("widget using Consumer rebuilt");
          return Scaffold(
            appBar: AppBar(
                title: const Text('InteractiveViewer'),
                backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                actions: [
                  SettingItem(
                    settingDesc: "font size",
                    child: DropdownMenu<String>(
                      menuHeight: 400,
                      initialSelection: settingState.fontSize.toString(),
                      onSelected: (String? newValue) {
                        settingState.fontSize = double.parse(newValue!);
                      },
                      dropdownMenuEntries: fontSizes.map((double fontSize) {
                        return DropdownMenuEntry<String>(
                          label: fontSize.toString(),
                          value: fontSize.toString(),
                        );
                      }).toList(),
                    ),
                  ),
                  SettingItem(
                      settingDesc: "font style",
                      child: Consumer<SettingState>(
                          builder: (context, settingState, child) {
                        print("widget using Consumer settingState rebuilt");
                        return DropdownMenu<String>(
                          menuHeight: 400,
                          initialSelection: settingState.fontStyle,
                          onSelected: (String? newValue) {
                            settingState.fontStyle = newValue!;
                          },
                          dropdownMenuEntries:
                              GoogleFonts.asMap().keys.map((String font) {
                            return DropdownMenuEntry<String>(
                              label: font,
                              value: font,
                            );
                          }).toList(),
                        );
                      })),
                  IconButton(
                    icon: Icon(Icons.psychology_alt),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.black,
                    ),
                    tooltip: "随机主题",
                    onPressed: () {
                      setState(() {
                        settingState.mainColor = getRandomColor();
                      });
                    },
                  ),
                ]),
            drawer: Drawer(
              // Add a ListView to the drawer. This ensures the user can scroll
              // through the options in the drawer if there isn't enough vertical
              // space to fit everything.
              child: ListView(
                // Important: Remove any padding from the ListView.
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    // decoration: BoxDecoration(
                    //   color: Colors.blue,
                    // ),
                    child: Text('Drawer Header'),
                  ),
                  ListTile(
                    title: const Text('Save to data dir'),
                    onTap: () {
                      saveToDocumentsDirectory(_Graphs[_tabIndex - 1].gs,
                          _Graphs[_tabIndex - 1].graphName);
                      captureImage(_Graphs[_tabIndex - 1].mykey,
                          _Graphs[_tabIndex - 1].graphName);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('New'),
                    selected: _selectedIndex == 0,
                    onTap: () async {
                      String? fileName = await _showNameDialog(context);
                      if (fileName != null) {
                        setState(() {
                          _tabIndex += 1;
                          print(_tabIndex);
                          GraphState gs = GraphState();
                          saveToDocumentsDirectory(gs, fileName);
                          _Graphs.insert(
                              _tabIndex - 1,
                              Graph(
                                mykey: GlobalKey(),
                                gs: gs,
                                graphName: fileName,
                              ));
                        });
                      }

                      _onItemTapped(0);
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Open'),
                    selected: _selectedIndex == 1,
                    onTap: () async {
                      var value =
                          await OpenAction(context_root).invoke(OpenIntent());
                      setState(() {
                        if (value.$1 != null && value.$2 != null) {
                          setState(() {
                            _tabIndex += 1;
                            _Graphs.insert(
                                _tabIndex - 1,
                                Graph(
                                    mykey: GlobalKey(),
                                    gs: value.$1!,
                                    graphName: value.$2!));
                          });
                        } else {
                          print('open error');
                        }
                      });

                      _onItemTapped(1);
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Save'),
                    selected: _selectedIndex == 2,
                    onTap: () async {
                      SaveAction(context, _Graphs[_tabIndex - 1].gs)
                          .invoke(SaveIntent());
                      captureImage(_Graphs[_tabIndex - 1].mykey,
                          _Graphs[_tabIndex - 1].graphName);
                      _onItemTapped(2);
                      // Then close the drawer
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // TabBar
                Container(
                  color: Theme.of(context).colorScheme.inversePrimary,

                  child: Row(
                      children: <Widget>[
                            IconButton(
                              icon: Icon(Icons.home),
                              onPressed: () {
                                // 按钮被点击时的操作
                                setState(() {
                                  _tabIndex = 0;
                                });
                              },
                            ),
                          ] +
                          List<Widget>.generate(
                            _Graphs.length,
                            (index) => Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: Color.fromARGB(31, 226, 213, 213),
                                    width: 1.0),
                              ),
                              child: Container(
                                  color: index == _tabIndex - 1
                                      ? Theme.of(context)
                                          .colorScheme
                                          .inversePrimary
                                      : getLighterColor(
                                          Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                          0.5),
                                  child: Row(
                                    children: [
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          textStyle: GoogleFonts.merriweather(
                                              fontSize: 15.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius
                                                .zero, // 将边框半径设置为零以获得方角矩形
                                          ),
                                          elevation: 0,
                                          foregroundColor:
                                              index == _tabIndex - 1
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .inversePrimary
                                                  : getLighterColor(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                      0.5),
                                        ),
                                        onPressed: () {
                                          // 按钮被点击时的操作
                                          setState(() {
                                            _tabIndex = index + 1;
                                          });
                                        },
                                        child: Text(
                                          _Graphs[index].graphName,
                                          style: GoogleFonts.merriweather(
                                              fontSize: 15.0,
                                              color: Colors.black),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.close),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor:
                                              index == _tabIndex - 1
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .inversePrimary
                                                  : getLighterColor(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                      0.5),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _Graphs.removeAt(index);
                                            if (index == _tabIndex - 1)
                                              _tabIndex -= 1;
                                          });
                                        },
                                      ),
                                    ],
                                  )),
                            ),
                          )),
                  // graph view
                ),
                Actions(
                    actions: <Type, Action<Intent>>{
                      SaveIntent: SaveAction(
                          context,
                          (_tabIndex - 1 >= 0 &&
                                  _tabIndex - 1 < _Graphs.length &&
                                  _Graphs.isNotEmpty)
                              ? _Graphs[_tabIndex - 1].gs
                              : null),
                    },
                    child: Expanded(
                        child: IndexedStack(
                            index: _tabIndex,
                            children: <Widget>[
                                  home(
                                    parentOpenNewPage: openNewPage,
                                  )
                                ] +
                                _Graphs)))
              ],
            ),
          );
        }));
  }

  void openNewPage(
    String fileName,
  ) {
    // 不需要同步等待异步结果时，直接在同步函数中调用异步函数即可，并且不需要await
    getApplicationDocumentsDirectory().then((appDocumentsDir) {
      final String filePath = '${appDocumentsDir.path}/$fileName';
      setState(() {
        _tabIndex += 1;

        File graphFile = File(filePath);
        String contents = graphFile.readAsStringSync();
        GraphState gs = GraphState.fromJson(contents);
        _Graphs.insert(
            _tabIndex - 1,
            Graph(
                mykey: GlobalKey(),
                gs: gs,
                graphName: basenameWithoutExtension(graphFile.path)));
      });
    });
  }
}

class Graph extends StatefulWidget {
  Graph(
      {Key? key,
      required this.mykey,
      required this.gs,
      required this.graphName})
      : super(key: key);
  final GlobalKey mykey;

  final GraphState gs;
  final String graphName;
  @override
  State<Graph> createState() => _GraphState();
}

class _GraphState extends State<Graph> with TickerProviderStateMixin {
  void _updateCounter() {
    setState(() {});
  }

  final TransformationController _transformationController =
      TransformationController();
  Animation<Matrix4>? _animationReset;
  late final AnimationController _controllerReset;

  void _onAnimateReset() {
    _transformationController.value = _animationReset!.value;
    if (!_controllerReset.isAnimating) {
      _animationReset!.removeListener(_onAnimateReset);
      _animationReset = null;
      _controllerReset.reset();
    }
  }

  void _animateResetInitialize(
      vector_math.Vector2 lastNodePosition, BuildContext context) {
    _controllerReset.reset();
    double x = -lastNodePosition[0];
    double y = -lastNodePosition[1];
    Size screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;

    print(
        'from ${_transformationController.value} to ${Matrix4.identity()..translate(-1000.0, -1000.0, 0.0)}');
    _animationReset = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity()
        ..translate(x + screenWidth / 2, y + screenHeight / 2, 0.0),
    ).animate(_controllerReset);
    _animationReset!.addListener(_onAnimateReset);
    _controllerReset.forward();
  }

  void _animateResetStop() {
    _controllerReset.stop();
    _animationReset?.removeListener(_onAnimateReset);
    _animationReset = null;
    _controllerReset.reset();
  }

  void _onInteractionStart(ScaleStartDetails details) {
    // If the user tries to cause a transformation while the reset animation is
    // running, cancel the reset animation.
    if (_controllerReset.status == AnimationStatus.forward) {
      _animateResetStop();
    }
  }

  @override
  void initState() {
    _controllerReset = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    super.initState();
  }

  @override
  void dispose() {
    _controllerReset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SettingState settingState =
        Provider.of<SettingState>(context, listen: true);
    vector_math.Vector2 lastNodePosition =
        widget.gs.nodeLayout[widget.gs.graph_nodes.last]!;
    _animateResetInitialize(lastNodePosition, context);
    return Center(
        child: RepaintBoundary(
            key: widget.mykey,
            child: InteractiveViewer(
              transformationController: _transformationController,
              clipBehavior: Clip.none,
              boundaryMargin: const EdgeInsets.all(0),
              constrained: false,
              minScale: 0.05,
              maxScale: 5,
              onInteractionStart: _onInteractionStart,
              child: Container(
                width: settingState.graphSize, // 设置一个固定的宽度
                height: settingState.graphSize, // 设置一个固定的高度
                child: Stack(
                    children: <Widget>[
                          Container(
                              width: settingState.graphSize, // 设置一个固定的宽度
                              height: settingState.graphSize, // 设置一个固定的高度
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment(0.8, 1),
                                  colors: <Color>[
                                    Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                                    Color.fromARGB(255, 227, 120, 136),
                                    Color.fromARGB(255, 207, 89, 35),
                                  ], // Gradient from https://learnui.design/tools/gradient-generator.html
                                  tileMode: TileMode.mirror,
                                ),
                              ))
                        ] +
                        widget.gs.edgeList
                            .map((edge) {
                              final String text =
                                  widget.gs.titles[edge.left] ?? 'init';
                              final TextStyle textStyle = GoogleFonts.getFont(
                                settingState.fontStyle,
                                fontSize: settingState.fontSize,
                              );
                              final ui.Size txtSize = textSize(text, textStyle);
                              final String text2 =
                                  widget.gs.titles[edge.left] ?? 'init';
                              final TextStyle textStyle2 = GoogleFonts.getFont(
                                settingState.fontStyle,
                                fontSize: settingState.fontSize,
                              );
                              final ui.Size txtSize2 =
                                  textSize(text, textStyle);

                              return CustomPaint(
                                painter: LinePainter(
                                    startPoint: ui.Size(
                                        widget.gs.nodeLayout[edge.left]![0],
                                        widget.gs.nodeLayout[edge.left]![1]),
                                    endPoint: ui.Size(
                                        widget.gs.nodeLayout[edge.right]![0],
                                        widget.gs.nodeLayout[edge.right]![1]),
                                    directed:
                                        widget.gs.directions[edge] ?? false),
                              );
                            })
                            .toList()
                            .cast<Widget>() +
                        widget.gs.nodeLayout.entries
                            .map((MapEntry<Node, vector_math.Vector2> entry) {
                              return NodeView(
                                gs: widget.gs,
                                node: entry.key,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                onUpdate: _updateCounter,
                              );
                            })
                            .toList()
                            .cast<Widget>()),
              ),
            )));
  }
}
