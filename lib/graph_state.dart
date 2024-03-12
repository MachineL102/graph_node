import 'dart:ffi';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:graph_layout/graph_layout.dart';
import 'package:vector_math/vector_math.dart';
import 'vector2_ext.dart';
import 'dart:convert';
// class DirectedEdge extends EdgeWithJson {
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

class IntegerNodeWithJson extends IntegerNode {
  IntegerNodeWithJson(int id) : super(id);

  // Add a factory constructor to create an IntegerNodeWithJson from a JSON map.
  factory IntegerNodeWithJson.fromJson(String json) {
    Map<String, dynamic> jsonMap = jsonDecode(json);
    return IntegerNodeWithJson(jsonMap['id']);
  }

  // Add a method to convert the IntegerNodeWithJson to a JSON map.
  Map<String, dynamic> toJson() {
    return {'id': id};
  }

  @override
  String toString() {
    // TODO: implement toString
    return id.toString();
  }

  static IntegerNodeWithJson fromString(String str) {
    // 在这个示例中，假设输入的字符串是一个数字，我们直接将它转换为整数作为节点的id
    int id = int.tryParse(str) ?? 0; // 如果解析失败，默认值为0
    return IntegerNodeWithJson(id);
  }
}

class EdgeWithJson extends Edge {
  EdgeWithJson(Node left, Node right) : super(left: left, right: right);

  // Add a factory constructor to create an IntegerNodeWithJson from a JSON map.
  factory EdgeWithJson.fromJson(Map<String, dynamic> json) {
    return EdgeWithJson(IntegerNodeWithJson(json['left']['id'] as int),
        IntegerNodeWithJson(json['right']['id'] as int));
  }

  // Add a method to convert the IntegerNodeWithJson to a JSON map.
  Map<String, dynamic> toJson() {
    return {'left': left, 'right': right};
  }

  // @override
  // String toString() {
  //   // TODO: implement toString
  //   return {'\"left\"': left, '\"right\"': right}.toString();
  // }

  static EdgeWithJson fromString(String str) {
    // 在这个示例中，假设输入的字符串是一个数字，我们直接将它转换为整数作为节点的id
    Map<String, dynamic> jsonMap = jsonDecode(str);

    return EdgeWithJson.fromJson(jsonMap);
  }
}

extension Vector2Json on Vector2 {
  Map<String, dynamic> toJson() {
    return {'x': 'a', 'y': 'b'};
  }
}

class GraphState extends ChangeNotifier {
  String title = "node title";
  String mainText = "node main text";
  int _current_node_id = 0;
  List<IntegerNodeWithJson> _graph_nodes = [IntegerNodeWithJson(0)];
  Set<EdgeWithJson> _edgeList = Set<EdgeWithJson>();
  NodeLayout _nodeLayout = Map<Node, Vector2>();
  Map<EdgeWithJson, bool> directions = Map<EdgeWithJson, bool>();
  Map<Node, String> titles = Map<Node, String>();
  Map<Node, String> mainTexts = Map<Node, String>();

  List<IntegerNodeWithJson> get graph_nodes => _graph_nodes;
  Set<EdgeWithJson> get edgeList => _edgeList;
  GraphState() {
    _nodeLayout[IntegerNodeWithJson(0)] = Vector2(100.0, 50.0);
    titles[IntegerNodeWithJson(0)] = title;
    mainTexts[IntegerNodeWithJson(0)] = mainText;
  }
  factory GraphState.fromJson(String jsonStr) {
    Map<String, dynamic> json = jsonDecode(jsonStr);
    String title = json['title'] as String;
    String mainText = json['mainText'] as String;
    int current_node_id = json['_current_node_id'] as int;
    List<IntegerNodeWithJson> graph_nodes = (json['_graph_nodes'] as List<dynamic>)
        .map((id) => IntegerNodeWithJson(id as int))
        .toList();
    Set<EdgeWithJson> edgeList =
        (json['_edgeList'] as List<dynamic>).map((edgeJson) => EdgeWithJson.fromJson(edgeJson)).toSet();
        
    Map<EdgeWithJson, bool> directions =
        (json['directions'] as Map<String, dynamic>)
            .map((key, value) => MapEntry(EdgeWithJson.fromString(key), value as bool));
    Map<Node, String> titles = (json['titles'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(IntegerNodeWithJson(int.parse(key)), value as String));
    Map<Node, String> mainTexts = (json['mainTexts'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(IntegerNodeWithJson(int.parse(key)), value as String));

    NodeLayout nodeLayout = (json['_nodeLayout'] as Map<String, dynamic>).map((key, value) => 
    MapEntry(IntegerNodeWithJson(int.parse(key)), Vector2(double.parse(value.split(',')[0]), double.parse(value.split(',')[1]))));
    return GraphState();
  }

  Map<Node, Vector2> get nodeLayout => _nodeLayout;

  Map<String, dynamic> toJson() => {
        'title': title,
        'mainText': mainText,
        '_current_node_id': _current_node_id,
        '_graph_nodes': _graph_nodes.map((e) => e.hashCode).toList(),
        '_edgeList': _edgeList.toList(), // only list support json encode
        '_nodeLayout': _nodeLayout.map((key, value) =>
            MapEntry('${key.hashCode}', '${value.x},${value.y}')),
        'directions':
            directions.map((key, value) => MapEntry(jsonEncode(key), value)),
        'titles':
            titles.map((key, value) => MapEntry('${key.hashCode}', value)),
        'mainTexts':
            mainTexts.map((key, value) => MapEntry('${key.hashCode}', value)),
      };

  set graph_nodes(List<IntegerNodeWithJson> value) {
    _graph_nodes = value;
    notifyListeners(); // Notify listeners about the change
  }

  void addRelatedNode(IntegerNodeWithJson node, RelationType directed) {
    _current_node_id = _current_node_id + 1;
    _graph_nodes.add(IntegerNodeWithJson(_current_node_id));

    titles[_graph_nodes.last] = title;
    mainTexts[_graph_nodes.last] = mainText;

    switch (directed) {
      case RelationType.related:
        _edgeList.add(EdgeWithJson(node, _graph_nodes.last));
        directions[_edgeList.last] = false;
        break;
      case RelationType.parent:
        _edgeList.add(EdgeWithJson(_graph_nodes.last, node));
        directions[_edgeList.last] = true;
        break;
      case RelationType.child:
        _edgeList.add(EdgeWithJson(node, _graph_nodes.last));
        directions[_edgeList.last] = true;
        break;
      default:
        print('error');
    }

    final graph = Graph.fromEdgeList(
        _edgeList.map((edge) => edge as EdgeWithJson).toSet());
    final layoutAlgorithm = FruchtermanReingold(graph: graph);
    layoutAlgorithm.updateLayoutParameters(
      width: 1000, //应该同步等于画布大小
      height: 1000,
      nodeRadius: 5,
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
