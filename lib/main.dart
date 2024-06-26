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
import 'package:screenshot/screenshot.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'chat.dart';
import 'package:flutter/scheduler.dart';
import 'package:graph_note/messages.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// import 'package:flutter_gemini/flutter_gemini.dart';

import 'dart:io';

import 'package:google_generative_ai/google_generative_ai.dart';

String _apiKey = Platform.environment['API_KEY'] ?? "";

class LoggingActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    print('Action invoked: $action($intent) from $context');
    super.invokeAction(action, intent, context);

    return null;
  }
}

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 必须加上这一行。
  await windowManager.ensureInitialized();
  return runApp(const MyApp());
}

class MyApp extends StatefulWidget  {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();

}

class _MyAppState extends State<MyApp> {

  Locale _locale = const Locale('zh', ''); // 默认语言为英文
//_loadLocaleFromPreferences 方法从 SharedPreferences 中加载用户偏好设置的语言环境。如果存在保存的语言代码，就将其更新到 _locale 变量中。
  Future<void> _loadLocaleFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('languageCode');
    if (languageCode != null) {
      setState(() {
        _locale = Locale(languageCode, '');
      });
    }
  }

//_saveLocaleToPreferences 方法用于将选择的语言环境保存到 SharedPreferences 中，以便下次启动应用时可以加载该语言环境。
  Future<void> _saveLocaleToPreferences(Locale locale) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  void setLocale(Locale newLocale) {
    _saveLocaleToPreferences(newLocale);
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadLocaleFromPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
        providers: [
          ChangeNotifierProvider(
              create: (context) => SettingState()), // 全局设置更改会通知相应子组件
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
              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                ...GlobalMaterialLocalizations.delegates,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''),
                Locale('zh', ''),
              ],
              locale: _locale, // 设置当前语言
              home: MultiGraph());
        }));
  }
}

class MultiGraph extends StatefulWidget {
  const MultiGraph({super.key});

  @override
  State<MultiGraph> createState() => _MultiGraphState();
}

class _MultiGraphState extends State<MultiGraph> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  @override
  void initState() {
    _state = SchedulerBinding.instance.lifecycleState;
    WidgetsBinding.instance.addObserver(this);
    _listener = AppLifecycleListener(
      // onShow: () => _handleTransition('show'),
      // onResume: () => _handleTransition('resume'),
      // onHide: () => _handleTransition('hide'),
      // onInactive: () => _handleTransition('inactive'),
      onInactive: () {
        // 关闭时自动保存
        print("on onInactive");
        for (var graph in _Graphs) {
          saveToDocumentsDirectory(graph.gs, graph.graphName);
          captureImage(graph.mykey, graph.graphName);
        }
      },
      // onPause: () => _handleTransition('pause'),
      onDetach: () {
        // 关闭时自动保存
        print("on Detach");
        for (var graph in _Graphs) {
          saveToDocumentsDirectory(graph.gs, graph.graphName);
          captureImage(graph.mykey, graph.graphName);
        }
      },
      // onRestart: () => _handleTransition('restart'),
      // This fires for each state change. Callbacks above fire only for
      // specific state transitions.
      // onStateChange: _handleStateChange,
    );
    _selectedIndex = 0;
    _tabIndex = 0;
    _Graphs = [];
    fontSizes = generateList(10.0, 50.0, 1.0);
    checkAndCreateDirectory();
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

  // 标识当前用户所在第几个页面，0表示home，从1开始表示打开的笔记索引，访问笔记索引时需要用_tabIndex-1
  int _tabIndex = 0;
  // 页面的主要内容，图结构组件
  List<Graph> _Graphs = [];
  late List<double> fontSizes;
  FocusNode _focusNode = FocusNode();
  final controller = TextEditingController();
  late final AppLifecycleListener _listener;
  late AppLifecycleState? _state;
  @override
  void dispose() {
    _focusNode.dispose(); // 释放资源
    _listener.dispose();
    WidgetsBinding.instance.removeObserver(this);
    print("dispose called");
    super.dispose();
  }

  void _toggleLanguage(BuildContext context) {
    var currentLocale = Localizations.localeOf(context);
    var newLocale = currentLocale.languageCode == 'en'
        ? const Locale('zh', '')
        : const Locale('en', '');

    MyApp.setLocale(context, newLocale);
  }

  bool _loading = false;

  bool get loading => _loading;

  set loading(bool set) => setState(() => _loading = set);
  bool _aiWindowOpen = false;
  @override
  Widget build(BuildContext context_root) {
    var messages = AppLocalizations.of(context_root)!;
    return Consumer<SettingState>(builder: (context, settingState, child) {
      print("widget using Consumer rebuilt");
      return Scaffold(
        appBar: AppBar(
            title: Text(messages['interactiveViewer'],),
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            actions: [

              SettingItem(
                settingDesc: messages['fontSize'],
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
                  settingDesc: messages['fontStyle'],
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
                icon: Icon(Icons.g_translate),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _toggleLanguage(context)
              ),
              IconButton(
                icon: Icon(Icons.psychology_alt),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                tooltip: messages['randomTheme'],
                onPressed: () {
                  setState(() {
                    settingState.mainColor = getRandomColor();
                  });
                },
              ),
              IconButton(
                icon: Icon(Icons.camera_alt),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                tooltip: messages['screenshot'],
                onPressed: () {
                  windowManager.minimize();
                  ScreenshotAction().invoke(ScreenshotIntent());
                },
              ),
            ]),
        //侧边栏
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                // decoration: BoxDecoration(
                //   color: Colors.blue,
                // ),
                child: Text(messages['drawerHeader']),
              ),
              ListTile(
                title: Text(messages['saveToDataDir']),
                onTap: () {
                  saveToDocumentsDirectory(_Graphs[_tabIndex - 1].gs,
                      _Graphs[_tabIndex - 1].graphName);
                  captureImage(_Graphs[_tabIndex - 1].mykey,
                      _Graphs[_tabIndex - 1].graphName);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text(messages['new']),
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
                title: Text(messages['open'],),
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
                title: Text(
                    messages['save'],
                ),
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
        // 自定义tabBar包含了顶部tab和下面的页面内容
        body: Shortcuts(
            shortcuts: <ShortcutActivator, Intent>{
              LogicalKeySet(
                LogicalKeyboardKey.controlLeft,
                LogicalKeyboardKey.keyS,
              ): SaveIntent(),
              LogicalKeySet(
                      LogicalKeyboardKey.altLeft, LogicalKeyboardKey.keyA):
                  ScreenshotIntent(),
              LogicalKeySet(
                  LogicalKeyboardKey.controlLeft,
                  LogicalKeyboardKey.altLeft,
                  LogicalKeyboardKey.keyA): ScreenshotIntent(),
              //LogicalKeySet(LogicalKeyboardKey.keyA): ScreenshotIntent(),
            },
            child: Actions(
                dispatcher: LoggingActionDispatcher(),
                actions: <Type, Action<Intent>>{
                  SaveIntent: SaveAction(
                      context,
                      (_tabIndex - 1 >= 0 &&
                              _tabIndex - 1 < _Graphs.length &&
                              _Graphs.isNotEmpty)
                          ? _Graphs[_tabIndex - 1].gs
                          : null),
                  ScreenshotIntent: ScreenshotAction()
                },
                child: Focus(
                  focusNode: _focusNode,
                  autofocus: true,
                  child: Stack(
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Stack(
                        children: [
                          IndexedStack(
                              index: _tabIndex,
                              children: <Widget>[
                                    home(
                                      parentOpenNewPage: openNewPage,
                                    )
                                  ] +
                                  _Graphs),
                          if (_aiWindowOpen)
                            Positioned(
                                left: 0,
                                top: 107,
                                width: MediaQuery.of(context).size.width / 4,
                                height:
                                    MediaQuery.of(context).size.height / 1.5,
                                child: Padding(
                                  padding: EdgeInsets.all(0),
                                  child: Card(
                                      color: settingState.mainColor,
                                      elevation: 8.0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                      margin: EdgeInsets.all(0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text('AI'),
                                          Expanded(
                                              child: SelectionArea(
                                                  child: ChatWidget(
                                            apiKey: _apiKey,
                                          )))
                                        ],
                                      )),
                                ))
                        ],
                      ),
                      Positioned(
                          left: 0,
                          top: 50,
                          child: FloatingActionButton(
                              child: _aiWindowOpen
                                  ? Icon(Icons.remove)
                                  : Icon(Icons.add),
                              backgroundColor: settingState.mainColor,
                              hoverElevation: 5.0,
                              tooltip: messages['aiChat'],
                              onPressed: () {
                                setState(() {
                                  _aiWindowOpen = !_aiWindowOpen;
                                });
                              })),
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
                                          color:
                                              Color.fromARGB(31, 226, 213, 213),
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
                                                textStyle:
                                                    GoogleFonts.merriweather(
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
                    ],
                  ),
                ))),
      );
    });
  }

  void openNewPage(
    String fileName,
  ) {
    // 输入为不带路径前缀的笔记文件名，文件是json格式
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

  // Animate和TransformationController相关组件用于在用户创建新的节点后，将新的节点定位到屏幕中间方便用户编辑
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

  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    SettingState settingState =
        Provider.of<SettingState>(context, listen: true);
    vector_math.Vector2 lastNodePosition =
        widget.gs.nodeLayout[widget.gs.graph_nodes.last]!;
    _animateResetInitialize(lastNodePosition, context);
    return Center(
        child: RepaintBoundary(
            // 用于保存笔记时截取缩略图在home页面展示
            key: widget.mykey, // global key用于获取组件context并获取缩略图
            child: InteractiveViewer(
              transformationController: _transformationController,
              clipBehavior: Clip.none,
              boundaryMargin: const EdgeInsets.all(0),
              constrained: false,
              minScale: 0.05,
              maxScale: 5,
              onInteractionStart: _onInteractionStart,
              child: Container(
                width: settingState.graphSize,
                height: settingState.graphSize,
                child: Stack(
                    children: <Widget>[
                          Container(
                              width: settingState.graphSize,
                              height: settingState.graphSize,
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
                        // 绘制所有节点连线
                        widget.gs.edgeList
                            .map((edge) {
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
                        // 绘制所有节点
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


