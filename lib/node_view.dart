import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'graph_state.dart';
import 'package:graph_layout/graph_layout.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'setting.dart';
import 'utils.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:graph_note/messages.dart';

class NodeView extends StatefulWidget {
  Node node;
  double positionX = 0.0;
  double positionY = 0.0;
  Color color;
  final GraphState gs;
  final VoidCallback onUpdate;
  NodeView(
      {required this.gs,
      required this.node,
      required this.color,
      required this.onUpdate});
  @override
  State<NodeView> createState() => _NodeViewState();
}

class _NodeViewState extends State<NodeView> {
  late TextEditingController _titleController;
  late TextEditingController _mainTextController;
  ValueNotifier<String> _displayText = ValueNotifier<String>('');

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.gs.titles[widget.node]);
    _mainTextController =
        TextEditingController(text: widget.gs.mainTexts[widget.node]);
    _mainTextController.addListener(_updateDisplayText);
    _displayText.value = _mainTextController.text;
    // 初始化时调用先根据文本内容刷新一次UI
    _buildMarkdownWidget(_displayText.value);
  }

  void _updateDisplayText() {
    setState(() {
      _displayText.value = _mainTextController.text;
    });
  }

  @override
  void dispose() {
    _mainTextController.removeListener(_updateDisplayText);
    _titleController.dispose();
    _mainTextController.dispose();
    super.dispose();
  }

  WrapAlignment _wrapAlignment = WrapAlignment.start;

  Widget _buildMarkdownWidget(String value) {
    //print('_buildMarkdownWidget _displayText.value:${_displayText.value}');
    return Markdown(
      key: Key(_wrapAlignment.toString()),
      data: value,
      // styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      //   textAlign: _wrapAlignment,
      //   pPadding: const EdgeInsets.only(bottom: 4.0),
      //   h1Align: _wrapAlignment,
      //   h1Padding: const EdgeInsets.only(left: 4.0),
      //   h2Align: _wrapAlignment,
      //   h2Padding: const EdgeInsets.only(left: 8.0),
      //   h3Align: _wrapAlignment,
      //   h3Padding: const EdgeInsets.only(left: 12.0),
      //   h4Align: _wrapAlignment,
      //   h4Padding: const EdgeInsets.only(left: 16.0),
      //   h5Align: _wrapAlignment,
      //   h5Padding: const EdgeInsets.only(left: 20.0),
      //   h6Align: _wrapAlignment,
      //   h6Padding: const EdgeInsets.only(left: 24.0),
      //   unorderedListAlign: _wrapAlignment,
      //   orderedListAlign: _wrapAlignment,
      //   blockquoteAlign: _wrapAlignment,
      //   codeblockAlign: _wrapAlignment,
      // ),
    );
  }

  void _createTextEditWindow(BuildContext context) {
    _titleController.text = widget.gs.titles[widget.node] ?? "panic";
    _mainTextController.text = widget.gs.mainTexts[widget.node] ?? "panic";
    String pre_title = _titleController.text;
    String pre_main_text = _mainTextController.text;
    showDialog(
      context: context,
      builder: (context2) {
        return AlertDialog(
          title: Text('Edit Node'),
          scrollable: false,
          content: Row(
            // mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                //height: 3000,
                width: MediaQuery.of(context).size.width /2,//必须指定
                child: ValueListenableBuilder<String>(
                    valueListenable: _displayText,
                    builder:
                        (BuildContext context, String value, Widget? child) {
                      // This builder will only get called when the _counter
                      // is updated.
                      _displayText.value = value;
                      return _buildMarkdownWidget(value);
                    }),
              ),
              Container(
                width: MediaQuery.of(context).size.width /3,//必须指定
                child: SingleChildScrollView(
                  child: Column(
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
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                setState(() {
                  widget.gs.titles[widget.node] = _titleController.text;
                  widget.gs.mainTexts[widget.node] = _mainTextController.text;
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

  HardwareKeyboard hardwareKeyboard = HardwareKeyboard();

  void showOptions(BuildContext context, List<IntegerNodeWithJson> nodes,
      TapUpDetails? details, SettingState settingState) {
    var messages = AppLocalizations.of(context)!;
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
          child: Text(messages['createRelatedNode'],),
          onTap: () {
            setState(() {
              widget.gs
                  .addRelatedNode(nodes, RelationType.related, settingState);
            });
            widget.onUpdate();
          },
        ),
        PopupMenuItem(
          child: Text(messages['createParentNode'],),
          onTap: () {
            setState(() {
              widget.gs
                  .addRelatedNode(nodes, RelationType.parent, settingState);
            });
            widget.onUpdate();
          },
        ),
        PopupMenuItem(
          child: Text(messages['createChildNode'],),
          onTap: () {
            widget.gs.addRelatedNode(nodes, RelationType.child, settingState);
            widget.onUpdate();
          },
        ),
      ],
    );
  }

  //Color colorState =;
  @override
  Widget build(BuildContext context) {
    SettingState settingState =
        Provider.of<SettingState>(context, listen: true);
    final String text = widget.gs.titles[widget.node] ?? 'init';
    final TextStyle textStyle = GoogleFonts.getFont(
      settingState.fontStyle,
      fontSize: settingState.fontSize,
    );
    final ui.Size txtSize = textSize(text, textStyle);

    widget.positionX =
        widget.gs.nodeLayout[widget.node]![0] - txtSize.width / 2;
    widget.positionY =
        widget.gs.nodeLayout[widget.node]![1] - txtSize.height / 2;

    return Positioned(
        left: widget.positionX,
        top: widget.positionY,
        child: GestureDetector(
            onSecondaryTap: () {
              if (widget.gs.selectedNodes.length != 0) {
                showOptions(
                    context,
                    widget.gs.selectedNodes
                        .map((e) => IntegerNodeWithJson(e))
                        .toList(),
                    null,
                    settingState);
              } else {
                showOptions(
                    context,
                    [IntegerNodeWithJson(widget.node.hashCode)],
                    null,
                    settingState);
              }
            },
            child: SizedBox(
                width: txtSize.width + 30,
                height: txtSize.height + 20,
                child: FloatingActionButton(
                    backgroundColor: widget.color,
                    hoverElevation: 8.0,
                    heroTag: "btn${widget.node.hashCode}",
                    child: Container(
                      width: txtSize.width,
                      height: txtSize.height,
                      child: Text(
                        text,
                        style: textStyle,
                      ),
                    ),
                    tooltip: 'Increment',
                    onPressed: () {
                      if (HardwareKeyboard.instance.isControlPressed) {
                        print("ctrl+click node");
                        widget.gs.selectedNodes.add(widget.node.hashCode);
                        print(widget.gs.selectedNodes);
                        setState(() {
                          widget.color = darkenColor(widget.color);
                        });
                      } else {
                        _createTextEditWindow(context);
                      }
                    }))));
  }
}
