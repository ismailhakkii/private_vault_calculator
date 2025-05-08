enum FileType {
  image,
  video,
  document,
  other,
}

class VaultFile {
  final String id;
  final String name;
  final String path;
  final FileType type;
  final int size;
  final DateTime addedAt;
  final String? thumbnailPath;

  const VaultFile({
    required this.id,
    required this.name,
    required this.path,
    required this.type,
    required this.size,
    required this.addedAt,
    this.thumbnailPath,
  });

  // Create a copy with modified fields
  VaultFile copyWith({
    String? id,
    String? name,
    String? path,
    FileType? type,
    int? size,
    DateTime? addedAt,
    String? thumbnailPath,
  }) {
    return VaultFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      size: size ?? this.size,
      addedAt: addedAt ?? this.addedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }

  // For storing in database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.index,
      'size': size,
      'addedAt': addedAt.millisecondsSinceEpoch,
      'thumbnailPath': thumbnailPath,
    };
  }

  // Create from database
  factory VaultFile.fromMap(Map<String, dynamic> map) {
    return VaultFile(
      id: map['id'] as String,
      name: map['name'] as String,
      path: map['path'] as String,
      type: FileType.values[map['type'] as int],
      size: map['size'] as int,
      addedAt: DateTime.fromMillisecondsSinceEpoch(map['addedAt'] as int),
      thumbnailPath: map['thumbnailPath'] as String?,
    );
  }

  String get sizeDisplay {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get typeDisplay {
    switch (type) {
      case FileType.image:
        return 'Resim';
      case FileType.video:
        return 'Video';
      case FileType.document:
        return 'Belge';
      case FileType.other:
        return 'Diğer';
    }
  }
} 