import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'graph_state.dart';
import 'package:graph_layout/graph_layout.dart';
import 'dart:ui' as ui;
import 'package:google_fonts/google_fonts.dart';
import 'setting.dart';
import 'utils.dart';

class NodeView extends StatefulWidget {
  Node node;
  double positionX = 0.0;
  double positionY = 0.0;
  Color color;
  final GraphState gs;
  final VoidCallback onUpdate;
  NodeView({required this.gs, required this.node, required this.color, required this.onUpdate});
  @override
  State<NodeView> createState() => _NodeViewState();
}

class _NodeViewState extends State<NodeView> {
  late TextEditingController _titleController;
  late TextEditingController _mainTextController;
  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.gs.titles[widget.node]);
    _mainTextController =
        TextEditingController(text: widget.gs.mainTexts[widget.node]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _mainTextController.dispose();
    super.dispose();
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
            setState(() {
              widget.gs.addRelatedNode(nodes, RelationType.related);
            });
                widget.onUpdate();
          },
        ),
        PopupMenuItem(
          child: Text('create parent node'),
          onTap: () {
                        setState(() {
            widget.gs.addRelatedNode(nodes, RelationType.parent);
            });
                widget.onUpdate();
          },
        ),
        PopupMenuItem(
          child: Text('create child node'),
          onTap: () {
            widget.gs.addRelatedNode(nodes, RelationType.child);
                widget.onUpdate();
          },
        ),
      ],
    );
  }

  //Color colorState =;
  @override
  Widget build(BuildContext context) {
    SettingState settingState = Provider.of<SettingState>(context, listen: true);
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
