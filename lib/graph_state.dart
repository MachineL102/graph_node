import 'dart:ffi';
import 'package:provider/provider.dart'; 
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';

class NoteNode extends IntegerNode {
  NoteNode(super.id);

}
class GraphState extends ChangeNotifier {

  List<NoteNode> _nodes = [NoteNode(0)];
  
  List<List<double>> _graph_nodes = [[50, 50]];

  List<List<double>> get graph_nodes => _graph_nodes;
  Set<Edge> _edgeList = Set<Edge>();

  set graph_nodes(List<List<double>> value) {
    _graph_nodes = value;
    notifyListeners(); // Notify listeners about the change
  }

  void addRelatedNode(List<double> node) {
    Graph.fromEdgeList(edgeList)
    graph_nodes = [...graph_nodes, [graph_nodes.last[0] + 50, graph_nodes.last[1] + 50]];
  }

  void addNode() {
    graph_nodes = [...graph_nodes, [graph_nodes.last[0] + 50, graph_nodes.last[1] + 50]];
  }
}