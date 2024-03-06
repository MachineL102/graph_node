import 'dart:ffi';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';

// class DirectedEdge extends Edge {
//   final bool directed;
//   DirectedEdge(
//       {required Node left, required Node right, required this.directed, s})
//       : super(left: left, right: right);
//   @override
//   bool operator ==(DirectedEdge other) =>
//       return this.left.hashCode == other.left.hashCode &&
//       this.left.hashCode == other.left.hashCode;

// }

enum RelationType {
  related,
  parent,
  child,
}

class GraphState extends ChangeNotifier {
  String title = "node title";
  String mainText = "node main text";

  int _current_node_id = 0;
  List<IntegerNode> _graph_nodes = [IntegerNode(0)];
  List<IntegerNode> get graph_nodes => _graph_nodes;
  Set<Edge> _edgeList = Set<Edge>();
  Set<Edge> get  edgeList => _edgeList;
  NodeLayout _nodeLayout = Map<Node, Vector2>();
  Map<Edge, bool> directions = Map<Edge, bool>();
  Map<Node, String> titles = Map<Node, String>();
  Map<Node, String> mainTexts = Map<Node, String>();
  GraphState() {
    _nodeLayout[IntegerNode(0)] = Vector2(1, 1);
    titles[IntegerNode(0)] = title;
    mainTexts[IntegerNode(0)] = mainText;
  }

  Map<Node, Vector2> get nodeLayout => _nodeLayout;

  set graph_nodes(List<IntegerNode> value) {
    _graph_nodes = value;
    notifyListeners(); // Notify listeners about the change
  }

  void addRelatedNode(IntegerNode node, RelationType directed) {
    _current_node_id = _current_node_id + 1;
    _graph_nodes.add(IntegerNode(_current_node_id));

    titles[_graph_nodes.last] = title;
    mainTexts[_graph_nodes.last] = mainText;

    switch (directed) {
      case RelationType.related:
    _edgeList.add(
        Edge(left: node, right: _graph_nodes.last));
        directions[_edgeList.last] = false;
        break;
      case RelationType.parent:
    _edgeList.add(
        Edge(left: _graph_nodes.last, right: node));
        directions[_edgeList.last] = true;
        break;
      case RelationType.child:
    _edgeList.add(
        Edge(left: node, right: _graph_nodes.last));
        directions[_edgeList.last] = true;
        break;
      default:
        print('error');
    }

    final graph = Graph.fromEdgeList(_edgeList.map((edge) => edge as Edge).toSet());
    final layoutAlgorithm = FruchtermanReingold(graph: graph);
    layoutAlgorithm.updateLayoutParameters(
      width: 300,
      height: 400,
      nodeRadius: 10,
    );
    layoutAlgorithm.computeLayout();
    for (final nodeLayout in layoutAlgorithm.nodeLayout.entries) {
      print(
          'the node with identifier ${nodeLayout.key.hashCode} is placed at ${nodeLayout.value}');
    }
    _nodeLayout = layoutAlgorithm.nodeLayout;
    notifyListeners(); // Notify listeners about the change
  }
}
