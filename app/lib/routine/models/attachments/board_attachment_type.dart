enum BoardAttachmentType {
  markdown,
  text,
  unknown,
}

extension BoardAttachmentTypeX
    on
        BoardAttachmentType {
  String get label {
    switch (this) {
      case BoardAttachmentType.markdown:
        return 'Markdown';
      case BoardAttachmentType.text:
        return 'Texto';
      case BoardAttachmentType.unknown:
        return 'Arquivo';
    }
  }

  String get extension {
    switch (this) {
      case BoardAttachmentType.markdown:
        return 'md';
      case BoardAttachmentType.text:
        return 'txt';
      case BoardAttachmentType.unknown:
        return '';
    }
  }

  String get mimeType {
    switch (this) {
      case BoardAttachmentType.markdown:
        return 'text/markdown';
      case BoardAttachmentType.text:
        return 'text/plain';
      case BoardAttachmentType.unknown:
        return 'application/octet-stream';
    }
  }

  bool get isTextBased {
    switch (this) {
      case BoardAttachmentType.markdown:
      case BoardAttachmentType.text:
        return true;
      case BoardAttachmentType.unknown:
        return false;
    }
  }

  static BoardAttachmentType fromFileName(
    String fileName,
  ) {
    final normalized = fileName.trim().toLowerCase();

    if (normalized.endsWith(
          '.md',
        ) ||
        normalized.endsWith(
          '.markdown',
        )) {
      return BoardAttachmentType.markdown;
    }

    if (normalized.endsWith(
      '.txt',
    )) {
      return BoardAttachmentType.text;
    }

    return BoardAttachmentType.unknown;
  }

  static BoardAttachmentType fromValue(
    String? value,
  ) {
    switch (value?.trim().toLowerCase()) {
      case 'markdown':
      case 'md':
      case 'text/markdown':
        return BoardAttachmentType.markdown;
      case 'text':
      case 'txt':
      case 'text/plain':
        return BoardAttachmentType.text;
      default:
        return BoardAttachmentType.unknown;
    }
  }
}
