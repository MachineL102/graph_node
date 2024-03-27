import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class home extends StatelessWidget {
  const home({required this.parentOpenNewPage, super.key});
  final Function(String) parentOpenNewPage;

  Future<List<File>> loadImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = directory.listSync(recursive: false);
    List<File> pngFiles = [];

    // 找到所有png后缀的文件
    for (FileSystemEntity file in files) {
      print(file);
      if (file is File && file.path.endsWith('.png')) {
        pngFiles.add(file);
      }
    }

    // 按文件最后修改时间排序
    pngFiles
        .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return pngFiles;
  }

  @override
  Widget build(BuildContext context) {
    //loadImages();
    print('build StatelessWidget home');
    return FutureBuilder<List<File>>(
      future: loadImages(),
      builder: (BuildContext context, AsyncSnapshot<List<File>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // 如果Future对象尚未完成（等待状态），则显示加载指示器等待
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          // 如果Future对象完成但出现错误，则显示错误信息
          return Text('Error: ${snapshot.error}');
        } else {
          // 如果Future对象已完成并且没有错误，则根据异步操作的结果构建UI
          if (snapshot.data != null)
            print('snapshot.data!.length:${snapshot.data!.length}');
          return (snapshot.data != null && snapshot.data!.isNotEmpty)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(200, 200, 200, 200),
                  child: GridView.count(
                      primary: false,
                      padding: const EdgeInsets.all(20),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 0,
                      crossAxisCount: 2,
                      children: snapshot.data!
                          .map(
                            (file) => Container(
                              padding:
                                  const EdgeInsets.fromLTRB(10, 10, 10, 10),
                              color: Colors.green,
                              child: Column(
                                children: [
                                  Expanded(
                                      flex: 1,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Expanded(flex: 1, child: Container()),
                                          Expanded(
                                            flex: 3,
                                            child: GestureDetector(
                                              onTap: () {
                                                // 处理点击事件的逻辑
                                                print('Image clicked!');
                                              },
                                              onDoubleTap: () {
                                                parentOpenNewPage('${basenameWithoutExtension(file.path)}.json');
                                                print('Image double clicked!');
                                              },
                                              child: Image.file(
                                                file,
                                                fit: BoxFit.fill,
                                              ),
                                            ),
                                          ),
                                          Expanded(flex: 1, child: Container()),
                                        ],
                                      )),
                                  Expanded(flex: 1, child: Text(basenameWithoutExtension(file.path)))
                                ],
                              ),
                            ),
                          )
                          .toList()),
                )
              : const Center(
                  child: Text('create your first note'),
                );
        }
      },
    );
  }
}
