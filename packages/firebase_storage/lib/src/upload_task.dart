// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_storage;

abstract class StorageUploadTask {
  final FirebaseStorage _firebaseStorage;
  final String _path;
  final StorageMetadata _metadata;

  StorageUploadTask._(this._firebaseStorage, this._path, this._metadata);
  Future<dynamic> _platformMethod();

  int _handle;

  bool isCanceled = false;
  bool isComplete = false;
  bool isInProgress = true;
  bool isPaused = false;
  bool isSuccessful = false;

  StorageTaskSnapshot lastSnapshot;

  /// Returns a last snapshot when completed
  Completer<StorageTaskSnapshot> _completer =
      new Completer<StorageTaskSnapshot>();
  Future<StorageTaskSnapshot> get onComplete => _completer.future;

  /// Convenience method to get the downloadUrl when complete
  Completer<Uri> _downloadUrl = new Completer<Uri>();
  Future<Uri> get downloadUrl => _downloadUrl.future.then((Uri u) {
        if (u == null) throw Exception('Failed to upload');
        return u;
      });

  StreamController<StorageTaskEvent> _controller =
      new StreamController<StorageTaskEvent>.broadcast();
  Stream<StorageTaskEvent> get events => _controller.stream;

  Future<StorageTaskSnapshot> _start() async {
    _handle = await _platformMethod();
    final StorageTaskEvent event = await _firebaseStorage._methodStream
        .where((MethodCall m) {
      return m.method == 'StorageTaskEvent' && m.arguments['handle'] == _handle;
    }).map<StorageTaskEvent>((MethodCall m) {
      final Map<dynamic, dynamic> args = m.arguments;
      final StorageTaskEvent e =
          new StorageTaskEvent._(args['type'], args['snapshot']);
      _setState(e);
      lastSnapshot = e.snapshot;
      _controller.add(e);
      if (e.type == StorageTaskEventType.success ||
          e.type == StorageTaskEventType.failure) {
        _completer.complete(e.snapshot);
        _downloadUrl.complete(e.snapshot.downloadUrl);
      }
      return e;
    }).firstWhere((StorageTaskEvent e) =>
            e.type == StorageTaskEventType.success ||
            e.type == StorageTaskEventType.failure);
    return event.snapshot;
  }

  void _setState(StorageTaskEvent event) {
    _resetState();
    switch (event.type) {
      case StorageTaskEventType.progress:
        isInProgress = true;
        break;
      case StorageTaskEventType.resume:
        isInProgress = true;
        break;
      case StorageTaskEventType.pause:
        isPaused = true;
        break;
      case StorageTaskEventType.success:
        isSuccessful = true;
        isComplete = true;
        break;
      case StorageTaskEventType.failure:
        isComplete = true;
        if (event.snapshot.error == StorageError.canceled) {
          isCanceled = true;
        }
        break;
    }
  }

  void _resetState() {
    isCanceled = false;
    isComplete = false;
    isInProgress = false;
    isPaused = false;
    isSuccessful = false;
  }

  /// Pause the upload
  void pause() => FirebaseStorage.channel.invokeMethod(
        'UploadTask#pause',
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'handle': _handle,
        },
      );

  /// Resume the upload
  void resume() => FirebaseStorage.channel.invokeMethod(
        'UploadTask#resume',
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'handle': _handle,
        },
      );

  /// Cancel the upload
  void cancel() => FirebaseStorage.channel.invokeMethod(
        'UploadTask#cancel',
        <String, dynamic>{
          'app': _firebaseStorage.app?.name,
          'bucket': _firebaseStorage.storageBucket,
          'handle': _handle,
        },
      );
}

class StorageFileUploadTask extends StorageUploadTask {
  final File _file;
  StorageFileUploadTask._(this._file, FirebaseStorage firebaseStorage,
      String path, StorageMetadata metadata)
      : super._(firebaseStorage, path, metadata);

  @override
  Future<dynamic> _platformMethod() {
    return FirebaseStorage.channel.invokeMethod(
      'StorageReference#putFile',
      <String, dynamic>{
        'app': _firebaseStorage.app?.name,
        'bucket': _firebaseStorage.storageBucket,
        'filename': _file.absolute.path,
        'path': _path,
        'metadata':
            _metadata == null ? null : _buildMetadataUploadMap(_metadata),
      },
    );
  }
}

class StorageDataUploadTask extends StorageUploadTask {
  final Uint8List _bytes;
  StorageDataUploadTask._(this._bytes, FirebaseStorage firebaseStorage,
      String path, StorageMetadata metadata)
      : super._(firebaseStorage, path, metadata);

  @override
  Future<dynamic> _platformMethod() {
    return FirebaseStorage.channel.invokeMethod(
      'StorageReference#putData',
      <String, dynamic>{
        'app': _firebaseStorage.app?.name,
        'bucket': _firebaseStorage.storageBucket,
        'data': _bytes,
        'path': _path,
        'metadata':
            _metadata == null ? null : _buildMetadataUploadMap(_metadata),
      },
    );
  }
}

Map<String, dynamic> _buildMetadataUploadMap(StorageMetadata metadata) {
  return <String, dynamic>{
    'cacheControl': metadata.cacheControl,
    'contentDisposition': metadata.contentDisposition,
    'contentLanguage': metadata.contentLanguage,
    'contentType': metadata.contentType,
    'contentEncoding': metadata.contentEncoding,
    'customMetadata': metadata.customMetadata,
  };
}
