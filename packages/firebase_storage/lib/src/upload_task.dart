// Copyright 2017, the Flutter project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

/// TODO: (pauldemarco) Reduce code duplication with StorageDownloadTask
abstract class StorageUploadTask {
  StorageUploadTask({
    @required FirebaseStorage storage,
    @required StorageReference reference,
    StorageMetadata metadata,
  })  : _storage = storage,
        _reference = reference,
        _metadata = metadata,
        assert(storage != null);

  final FirebaseStorage _storage;
  final StorageMetadata _metadata;
  final StorageReference _reference;

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

  /// Returns a StorageTaskSnapshot on complete, or throws error
  Future<StorageTaskSnapshot> _start() async {
    _handle = await _platformMethod().then<int>((dynamic result) => result);
    return await _storage._methodStream
        .where((MethodCall m) => m.method == 'StorageTaskEvent')
        .where((MethodCall m) => m.arguments['handle'] == _handle)
        .map<Map<dynamic, dynamic>>((MethodCall m) => m.arguments)
        .map<StorageTaskEvent>((Map<dynamic, dynamic> m) =>
            new StorageTaskEvent._(m['type'], m['snapshot']))
        .map<StorageTaskEvent>((StorageTaskEvent e) {
          _resetState();
          switch (e.type) {
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
              _completer.complete(e.snapshot);
              _downloadUrl.complete(e.snapshot.downloadUrl);
              break;
            case StorageTaskEventType.failure:
              isComplete = true;
              if (e.snapshot.error == StorageError.canceled) {
                isCanceled = true;
              }
              _completer.complete(e.snapshot);
              _downloadUrl.complete(e.snapshot.downloadUrl);
              break;
          }
          lastSnapshot = e.snapshot;
          _controller.add(e);
          return e;
        })
        .firstWhere((StorageTaskEvent e) =>
            e.type == StorageTaskEventType.success ||
            e.type == StorageTaskEventType.failure)
        .then<StorageTaskSnapshot>((StorageTaskEvent event) => event.snapshot);
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
          'app': _storage.app?.name,
          'bucket': _storage.storageBucket,
          'handle': _handle,
        },
      );

  /// Resume the upload
  void resume() => FirebaseStorage.channel.invokeMethod(
        'UploadTask#resume',
        <String, dynamic>{
          'app': _storage.app?.name,
          'bucket': _storage.storageBucket,
          'handle': _handle,
        },
      );

  /// Cancel the upload
  void cancel() => FirebaseStorage.channel.invokeMethod(
        'UploadTask#cancel',
        <String, dynamic>{
          'app': _storage.app?.name,
          'bucket': _storage.storageBucket,
          'handle': _handle,
        },
      );
}

class _StorageFileUploadTask extends StorageUploadTask {
  _StorageFileUploadTask({
    @required FirebaseStorage storage,
    @required StorageReference reference,
    StorageMetadata metadata,
    @required this.file,
  }) : super(storage: storage, reference: reference, metadata: metadata);

  final File file;

  @override
  Future<dynamic> _platformMethod() {
    return FirebaseStorage.channel.invokeMethod(
      'StorageReference#putFile',
      <String, dynamic>{
        'app': _storage.app?.name,
        'bucket': _storage.storageBucket,
        'filename': file.absolute.path,
        'path': _reference.path,
        'metadata':
            _metadata == null ? null : _buildMetadataUploadMap(_metadata),
      },
    );
  }
}

class _StorageDataUploadTask extends StorageUploadTask {
  _StorageDataUploadTask({
    @required FirebaseStorage storage,
    @required StorageReference reference,
    StorageMetadata metadata,
    @required this.data,
  }) : super(storage: storage, reference: reference, metadata: metadata);

  final Uint8List data;

  @override
  Future<dynamic> _platformMethod() {
    return FirebaseStorage.channel.invokeMethod(
      'StorageReference#putFile',
      <String, dynamic>{
        'app': _storage.app?.name,
        'bucket': _storage.storageBucket,
        'data': data,
        'path': _reference.path,
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
