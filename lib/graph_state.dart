import 'dart:ffi';
import 'package:provider/provider.dart'; 
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

// class NoteNode extends IntegerNode {
//   NoteNode(super.id);
//   double _positionX = 0.0;
//   double _positionY = 0.0;

//   double get positionX => _positionX;
//   double get positionY => _positionY;
// }
class GraphState extends ChangeNotifier {
    String title = "node title";
  String mainText = "node main text";

  int _current_node_id = 0;
  List<IntegerNode> _graph_nodes = [IntegerNode(0)];
  List<IntegerNode> get graph_nodes => _graph_nodes;
  Set<Edge> _edgeList = Set<Edge>();
  NodeLayout _nodeLayout = Map<Node, Vector2>();
  Map<Node,String> titles = Map<Node,String>();
  Map<Node,String> mainTexts = Map<Node,String>();
  GraphState() {
    _nodeLayout[IntegerNode(0)] = Vector2(1,1);
    titles[IntegerNode(0)] = title;
    mainTexts[IntegerNode(0)] = mainText;
  }

  Map<Node, Vector2> get nodeLayout => _nodeLayout;
  
  set graph_nodes(List<IntegerNode> value) {
    _graph_nodes = value;
    notifyListeners(); // Notify listeners about the change
  }

  void addRelatedNode(IntegerNode node) {
    _current_node_id = _current_node_id + 1;
    _graph_nodes.add(IntegerNode(_current_node_id));

    titles[_graph_nodes.last] = title;
    mainTexts[_graph_nodes.last] = mainText;
    _edgeList.add(Edge(left: node, right: _graph_nodes.last));
    final graph = Graph.fromEdgeList(_edgeList);
    final layoutAlgorithm = FruchtermanReingold(graph: graph);
    layoutAlgorithm.updateLayoutParameters(
      width: 300,
      height: 400,
      nodeRadius: 10,
    );
    layoutAlgorithm.computeLayout();
    for (final nodeLayout in layoutAlgorithm.nodeLayout.entries) {
      print('the node with identifier ${nodeLayout.key.hashCode} is placed at ${nodeLayout.value}');
    }
    _nodeLayout = layoutAlgorithm.nodeLayout;
    notifyListeners(); // Notify listeners about the change
  }
}