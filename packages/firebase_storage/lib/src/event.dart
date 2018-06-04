part of firebase_storage;

enum StorageTaskEventType {
  resume,
  progress,
  pause,
  success,
  failure,
}

/// `Event` encapsulates a StorageTaskSnapshot
class StorageTaskEvent {
  StorageTaskEvent._(int type, Map<dynamic, dynamic> data)
      : type = StorageTaskEventType.values[type],
        snapshot = new StorageTaskSnapshot._(data);

  final StorageTaskEventType type;
  final StorageTaskSnapshot snapshot;
}

class StorageTaskSnapshot {
  StorageTaskSnapshot._(Map<dynamic, dynamic> m)
      : downloadUrl =
            m['downloadUrl'] != null ? Uri.parse(m['downloadUrl']) : null,
        error = m['error'],
        bytesTransferred = m['bytesTransferred'],
        totalByteCount = m['totalByteCount'],
        uploadSessionUri = m['uploadSessionUri'] != null
            ? Uri.parse(m['uploadSessionUri'])
            : null,
        storageMetadata = m['storageMetadata'] != null
            ? new StorageMetadata._fromMap(m['storageMetadata'])
            : null;

  final Uri downloadUrl;
  final int error;
  final int bytesTransferred;
  final int totalByteCount;
  final Uri uploadSessionUri;
  final StorageMetadata storageMetadata;
}
