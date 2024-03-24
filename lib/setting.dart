import 'dart:ffi';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils.dart';

class SettingState extends ChangeNotifier {
  double _fontSize = 20.0;
  String _fontStyle = 'ABeeZee';
  Color _mainColor = Color(0xffffb56b);
  
  SettingState(){
    print('SettingState init');
  }
  // Getter方法
  Color get mainColor => _mainColor;

  // Setter方法
  set mainColor(Color value) {
    _mainColor = value;
    notifyListeners();
  }

  // Getter方法
  double get fontSize => _fontSize;

  // Setter方法
  set fontSize(double value) {
    _fontSize = value;
    notifyListeners();
  }

  String get fontStyle => _fontStyle;

  // Setter方法
  set fontStyle(String value) {
    _fontStyle = value;
    notifyListeners();
  }
}

List<double> generateList(double start, double end, double step) {
  List<double> result = [];
  for (double i = start; i <= end; i += step) {
    result.add(i);
  }
  return result;
}

class SecondRoute extends StatefulWidget {
  const SecondRoute({super.key});

  @override
  State<SecondRoute> createState() => _SecondRouteState();
}

class _SecondRouteState extends State<SecondRoute> {
  int _selectedIndex = 0;
  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;

  late String selectedFont;
  late Future _googleFontsPending;
  final Iterable<String> fonts = GoogleFonts.asMap().keys;

  late List<double> fontSizes;

  @override
  void initState() {
    super.initState();
    selectedFont = fonts.first;
    fontSizes = generateList(10.0, 50.0, 1.0);
    _googleFontsPending =
        GoogleFonts.pendingFonts([GoogleFonts.getFont(selectedFont)]);
    print('init setting');
  }

  @override
  Widget build(BuildContext context) {
    return Row(children: <Widget>[
      NavigationRail(
        selectedIndex: _selectedIndex,
        groupAlignment: groupAlignment,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        labelType: labelType,
        leading: showLeading
            ? FloatingActionButton(
                elevation: 0,
                onPressed: () {
                  // Add your onPressed code here!
                },
                child: const Icon(Icons.add),
              )
            : const SizedBox(),
        trailing: showTrailing
            ? IconButton(
                onPressed: () {
                  // Add your onPressed code here!
                },
                icon: const Icon(Icons.more_horiz_rounded),
              )
            : const SizedBox(),
        destinations: const <NavigationRailDestination>[
          NavigationRailDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: Text('First'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.book),
            label: Text('Second'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.star_border),
            selectedIcon: Icon(Icons.star),
            label: Text('Third'),
          ),
        ],
      ),
      const VerticalDivider(thickness: 1, width: 1),
      // This is the main content.
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
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
                      _googleFontsPending = GoogleFonts.pendingFonts(
                        [GoogleFonts.getFont(selectedFont)],
                      );
                      ;
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
            SettingItem(
                settingDesc: "font size",
                child: Consumer<SettingState>(
                    builder: (context, settingState, child) {
                  print("widget using Consumer settingState rebuilt");
                  return DropdownMenu<String>(
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
                  );
                })),
            const SizedBox(height: 20),
            Text('Label type: ${labelType.name}'),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            Text('Group alignment: $groupAlignment'),
            const SizedBox(height: 10),
            const SizedBox(height: 20),
          ],
        ),
      ),
    ]);
  }
}

class SettingItem extends StatefulWidget {
  SettingItem({super.key, required this.settingDesc, required this.child});

  String settingDesc = "";
  Widget child;
  @override
  State<SettingItem> createState() => _SettingItemState();
}

class _SettingItemState extends State<SettingItem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.center,

        children: <Widget>[
          const SizedBox(width: 20),
          Text(widget.settingDesc),
          const SizedBox(width: 10),
          widget.child,
        ],
      ),
    );
  }
}
