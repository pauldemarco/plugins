// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

void main() async {
  final FirebaseApp app = await FirebaseApp.configure(
    name: 'test',
    options: new FirebaseOptions(
      googleAppID: Platform.isIOS
          ? '1:159623150305:ios:4a213ef3dbd8997b'
          : '1:159623150305:android:ef48439a0cc0263d',
      gcmSenderID: '159623150305',
      apiKey: 'AIzaSyChk3KEG7QYrs4kQPLP1tjJNxBTbfCAdgg',
      projectID: 'flutter-firebase-plugins',
    ),
  );
  final FirebaseStorage storage = new FirebaseStorage(
      app: app, storageBucket: 'gs://flutter-firebase-plugins.appspot.com');
  runApp(new MyApp(storage: storage));
}

class MyApp extends StatelessWidget {
  MyApp({this.storage});
  final FirebaseStorage storage;

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Storage Example',
      home: new MyHomePage(storage: storage),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({this.storage});
  final FirebaseStorage storage;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

const String kTestString = "Hello world!";

class _MyHomePageState extends State<MyHomePage> {
  String _fileContents;
  String _name;
  String _bucket;
  String _path;
  String _tempFileContents;

  StorageUploadTask uploadTask;

/*
  StorageUploadTask.Future<Null> _uploadFile() async {
    final Directory systemTempDir = Directory.systemTemp;
    final File file = await new File('${systemTempDir.path}/foo.txt').create();
    file.writeAsString(kTestString);
    assert(await file.readAsString() == kTestString);
    final String rand = "${new Random().nextInt(10000)}";
    final StorageReference ref =
        widget.storage.ref().child('text').child('foo$rand.txt');
    final StorageUploadTask uploadTask = ref.putFile(
      file,
      new StorageMetadata(
        contentLanguage: 'en',
        customMetadata: <String, String>{'activity': 'test'},
      ),
    );

    final Uri downloadUrl = await uploadTask.downloadUrl;
    final http.Response downloadData = await http.get(downloadUrl);
    final String name = await ref.getName();
    final String bucket = await ref.getBucket();
    final String path = await ref.getPath();
    final File tempFile = new File('${systemTempDir.path}/tmp.txt');
    if (tempFile.existsSync()) {
      await tempFile.delete();
    }
    await tempFile.create();
    assert(await tempFile.readAsString() == "");
    final StorageFileDownloadTask task = ref.writeToFile(tempFile);
    final int byteCount = (await task.future).totalByteCount;
    final String tempFileContents = await tempFile.readAsString();
    assert(tempFileContents == kTestString);
    assert(byteCount == kTestString.length);

    setState(() {
      _fileContents = downloadData.body;
      _name = name;
      _path = path;
      _bucket = bucket;
      _tempFileContents = tempFileContents;
    });
  }*/

  void _startUpload() async {
    final Directory systemTempDir = Directory.systemTemp;
    final File file = await new File('${systemTempDir.path}/foo.txt').create();
    file.writeAsString(kTestString);
    assert(await file.readAsString() == kTestString);
    final String rand = "${new Random().nextInt(10000)}";
    final StorageReference ref =
        widget.storage.ref().child('text').child('foo$rand.txt');
    final StorageUploadTask task =
        ref.putFile(file, StorageMetadata(contentLanguage: "en"));
    setState(() {
      uploadTask = task;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new StreamBuilder<StorageTaskEvent>(
      stream: uploadTask?.events,
      builder: (context, snapshot) {
        return new Scaffold(
          appBar: new AppBar(
            title: const Text('Flutter Storage Example'),
          ),
          body: new Center(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _fileContents == null
                    ? const Text('Press the button to upload a file \n '
                        'and download its contents to tmp.txt')
                    : new Text(
                        'Success!\n Uploaded $_name \n to bucket: $_bucket\n '
                            'at path: $_path \n\nFile contents: "$_fileContents" \n'
                            'Wrote "$_tempFileContents" to tmp.txt',
                        style: const TextStyle(
                            color: const Color.fromARGB(255, 0, 155, 0)),
                      )
              ],
            ),
          ),
          floatingActionButton: new FloatingActionButton(
            onPressed: (uploadTask == null || uploadTask.isComplete)
                ? _startUpload
                : null,
            tooltip: 'Upload',
            child: const Icon(Icons.file_upload),
          ),
          persistentFooterButtons: <Widget>[
            new RaisedButton.icon(
              icon: const Icon(Icons.pause),
              label: const Text('Pause'),
              onPressed: (uploadTask != null && uploadTask.isInProgress)
                  ? uploadTask.pause
                  : null,
            ),
            new RaisedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Resume'),
              onPressed: (uploadTask != null && uploadTask.isPaused)
                  ? uploadTask.resume
                  : null,
            ),
            new RaisedButton.icon(
              icon: const Icon(Icons.cancel),
              label: const Text('Cancel'),
              onPressed: (uploadTask != null && !uploadTask.isComplete)
                  ? uploadTask.cancel
                  : null,
            ),
          ],
        );
      },
    );
  }
}
