// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_storage;

class StorageReference {
  StorageReference._(
    FirebaseStorage storage,
    List<String> pathComponents,
  )   : _storage = storage,
        _pathComponents = pathComponents,
        assert(storage != null);

  final FirebaseStorage _storage;
  final List<String> _pathComponents;

  String get path => _pathComponents.join('/');

  /// Returns a new instance of [StorageReference] pointing to a child
  /// location of the current reference.
  StorageReference child(String path) {
    return new StorageReference._(_storage,
        new List<String>.from(_pathComponents)..addAll(path.split("/")));
  }

  /// Returns a new instance of [StorageReference] pointing to the parent
  /// location or null if this instance references the root location.
  StorageReference parent() {
    if (_pathComponents.isEmpty ||
        _pathComponents.every((String e) => e.isEmpty)) {
      return null;
    }

    final List<String> parentPath = new List<String>.from(_pathComponents);
    // Trim for trailing empty path components that can
    // come from trailing slashes in the path.
    while (parentPath.last.isEmpty) {
      parentPath.removeLast();
    }
    parentPath.removeLast();

    return new StorageReference._(_storage, parentPath);
  }

  /// Returns a new instance of [StorageReference] pointing to the root location.
  StorageReference root() {
    return new StorageReference._(_storage, <String>[]);
  }

  /// Returns the [FirebaseStorage] service which created this reference.
  FirebaseStorage getStorage() {
    return _storage;
  }

  /// This method is deprecated. Please use [putFile] instead.
  ///
  /// Asynchronously uploads a file to the currently specified
  /// [StorageReference], with an optional [metadata].
  @deprecated
  StorageUploadTask put(File file, [StorageMetadata metadata]) {
    return putFile(file, metadata);
  }

  /// Asynchronously uploads a file to the currently specified
  /// [StorageReference], with an optional [metadata].
  StorageUploadTask putFile(File file, [StorageMetadata metadata]) {
    final StorageUploadTask task = new _StorageFileUploadTask(
      storage: _storage,
      reference: this,
      file: file,
      metadata: metadata,
    );
    task._start();
    return task;
  }

  /// Asynchronously uploads byte data to the currently specified
  /// [StorageReference], with an optional [metadata].
  StorageUploadTask putData(Uint8List data, [StorageMetadata metadata]) {
    final StorageUploadTask task = new _StorageDataUploadTask(
      storage: _storage,
      reference: this,
      data: data,
      metadata: metadata,
    );
    task._start();
    return task;
  }

  /// Returns the Google Cloud Storage bucket that holds this object.
  Future<String> getBucket() async {
    return await FirebaseStorage.channel
        .invokeMethod("StorageReference#getBucket", <String, String>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/"),
    });
  }

  /// Returns the full path to this object, not including the Google Cloud
  /// Storage bucket.
  Future<String> getPath() async {
    return await FirebaseStorage.channel
        .invokeMethod("StorageReference#getPath", <String, String>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/"),
    });
  }

  /// Returns the short name of this object.
  Future<String> getName() async {
    return await FirebaseStorage.channel
        .invokeMethod("StorageReference#getName", <String, String>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/"),
    });
  }

  /// Asynchronously downloads the object at the StorageReference to a list in memory.
  /// A list of the provided max size will be allocated.
  Future<Uint8List> getData(int maxSize) async {
    return await FirebaseStorage.channel.invokeMethod(
      "StorageReference#getData",
      <String, dynamic>{
        'app': _storage.app?.name,
        'bucket': _storage.storageBucket,
        'maxSize': maxSize,
        'path': _pathComponents.join("/"),
      },
    );
  }

  /// Asynchronously downloads the object at this [StorageReference] to a
  /// specified system file.
  StorageFileDownloadTask writeToFile(File file) {
    final StorageFileDownloadTask task = new StorageFileDownloadTask._(
        _storage, _pathComponents.join("/"), file);
    task._start();
    return task;
  }

  /// Asynchronously retrieves a long lived download URL with a revokable token.
  /// This can be used to share the file with others, but can be revoked by a
  /// developer in the Firebase Console if desired.
  Future<dynamic> getDownloadURL() async {
    return await FirebaseStorage.channel
        .invokeMethod("StorageReference#getDownloadUrl", <String, String>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/"),
    });
  }

  Future<void> delete() {
    return FirebaseStorage.channel
        .invokeMethod("StorageReference#delete", <String, String>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/")
    });
  }

  /// Retrieves metadata associated with an object at this [StorageReference].
  Future<StorageMetadata> getMetadata() async {
    return new StorageMetadata._fromMap(await FirebaseStorage.channel
        .invokeMethod("StorageReference#getMetadata", <String, String>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/"),
    }));
  }

  /// Updates the metadata associated with this [StorageReference].
  ///
  /// Returns a [Future] that will complete to the updated [StorageMetadata].
  ///
  /// This method ignores fields of [metadata] that cannot be set by the public
  /// [StorageMetadata] constructor. Writable metadata properties can be deleted
  /// by passing the empty string.
  Future<StorageMetadata> updateMetadata(StorageMetadata metadata) async {
    return new StorageMetadata._fromMap(await FirebaseStorage.channel
        .invokeMethod("StorageReference#updateMetadata", <String, dynamic>{
      'app': _storage.app?.name,
      'bucket': _storage.storageBucket,
      'path': _pathComponents.join("/"),
      'metadata': metadata == null ? null : _buildMetadataUploadMap(metadata),
    }));
  }
}
