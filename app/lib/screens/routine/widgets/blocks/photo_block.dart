import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/board_block.dart';

class PhotoBlock
    extends
        StatelessWidget {
  const PhotoBlock({
    super.key,
    required this.block,
    this.onOpen,
  });

  final BoardBlock block;
  final VoidCallback? onOpen;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final reference = block.content.trim();

    final hasReference = reference.isNotEmpty;

    final isNetwork = _isNetworkReference(
      reference,
    );

    final isLocal = _isLocalReference(
      reference,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: hasReference
              ? onOpen
              : null,
          borderRadius: BorderRadius.circular(
            13,
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(
                0xFF111319,
              ),
              borderRadius: BorderRadius.circular(
                13,
              ),
              border: Border.all(
                color: const Color(
                  0xFF272B36,
                ),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ==================================================
                  // IMAGE / PLACEHOLDER
                  // ==================================================
                  _buildPreview(
                    reference: reference,
                    hasReference: hasReference,
                    isNetwork: isNetwork,
                    isLocal: isLocal,
                  ),

                  // ==================================================
                  // INFO
                  // ==================================================
                  _buildInfo(
                    reference: reference,
                    hasReference: hasReference,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PREVIEW
  // ============================================================

  Widget _buildPreview({
    required String reference,
    required bool hasReference,
    required bool isNetwork,
    required bool isLocal,
  }) {
    if (!hasReference) {
      return _buildPlaceholder();
    }

    if (isNetwork) {
      return _buildNetworkImage(
        reference,
      );
    }

    if (isLocal) {
      return _buildLocalImage(
        reference,
      );
    }

    // ==========================================================
    // STORAGE PATH
    // ==========================================================
    //
    // Exemplo:
    //
    // user-id/routine-id/image.jpg
    //
    // Esse valor é o caminho privado do Supabase Storage.
    //
    // Para exibir a imagem será necessário gerar uma signed URL
    // no service/controller e colocar essa URL em block.content
    // ou passar a URL resolvida para este widget.
    //
    // ==========================================================

    return _buildStoragePlaceholder();
  }

  // ============================================================
  // NETWORK IMAGE
  // ============================================================

  Widget _buildNetworkImage(
    String url,
  ) {
    return SizedBox(
      height: 210,
      child: Image.network(
        url,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder:
            (
              context,
              child,
              progress,
            ) {
              if (progress ==
                  null) {
                return child;
              }

              return _buildLoading();
            },
        errorBuilder:
            (
              context,
              error,
              stackTrace,
            ) {
              return _buildError();
            },
      ),
    );
  }

  // ============================================================
  // LOCAL IMAGE
  // ============================================================

  Widget _buildLocalImage(
    String path,
  ) {
    final normalizedPath =
        path.startsWith(
          'file://',
        )
        ? Uri.parse(
            path,
          ).toFilePath()
        : path;

    final file = File(
      normalizedPath,
    );

    if (!file.existsSync()) {
      return _buildError(
        message: 'Arquivo local não encontrado',
      );
    }

    return SizedBox(
      height: 210,
      child: Image.file(
        file,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder:
            (
              context,
              error,
              stackTrace,
            ) {
              return _buildError();
            },
      ),
    );
  }

  // ============================================================
  // EMPTY PLACEHOLDER
  // ============================================================

  Widget _buildPlaceholder() {
    return Container(
      height: 170,
      color: const Color(
        0xFF0D0F14,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: block.color.withValues(
                  alpha: .12,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: block.color,
                size: 27,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Nenhuma imagem selecionada',
              style: TextStyle(
                color: Color(
                  0xFF9298A6,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STORAGE PLACEHOLDER
  // ============================================================

  Widget _buildStoragePlaceholder() {
    return Container(
      height: 170,
      color: const Color(
        0xFF0D0F14,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: block.color.withValues(
                  alpha: .12,
                ),
                borderRadius: BorderRadius.circular(
                  14,
                ),
              ),
              child: Icon(
                Icons.cloud_outlined,
                color: block.color,
                size: 27,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Text(
              'Imagem armazenada',
              style: TextStyle(
                color: Color(
                  0xFFF5F7FA,
                ),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(
              height: 4,
            ),
            const Text(
              'Supabase Storage',
              style: TextStyle(
                color: Color(
                  0xFF686F7C,
                ),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoading() {
    return Container(
      height: 210,
      color: const Color(
        0xFF0D0F14,
      ),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: block.color,
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError({
    String message = 'Não foi possível carregar a imagem',
  }) {
    return Container(
      height: 170,
      color: const Color(
        0xFF0D0F14,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              color: Color(
                0xFFFF6B7A,
              ),
              size: 28,
            ),
            const SizedBox(
              height: 8,
            ),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(
                  0xFF9298A6,
                ),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // INFO
  // ============================================================

  Widget _buildInfo({
    required String reference,
    required bool hasReference,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        14,
        12,
        14,
        13,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: block.color.withValues(
                alpha: .10,
              ),
              borderRadius: BorderRadius.circular(
                9,
              ),
            ),
            child: Icon(
              hasReference
                  ? Icons.image_outlined
                  : Icons.add_photo_alternate_outlined,
              color: block.color,
              size: 18,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  block.title.trim().isEmpty
                      ? 'Referência visual'
                      : block.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(
                      0xFFF5F7FA,
                    ),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                if (hasReference) ...[
                  const SizedBox(
                    height: 3,
                  ),
                  Text(
                    _displayReference(
                      reference,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(
                        0xFF686F7C,
                      ),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (hasReference &&
              onOpen !=
                  null) ...[
            const SizedBox(
              width: 8,
            ),
            Icon(
              Icons.open_in_new_rounded,
              color: block.color.withValues(
                alpha: .85,
              ),
              size: 17,
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // NETWORK REFERENCE
  // ============================================================

  bool _isNetworkReference(
    String value,
  ) {
    if (value.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(
      value,
    );

    if (uri ==
        null) {
      return false;
    }

    return uri.scheme ==
            'http' ||
        uri.scheme ==
            'https';
  }

  // ============================================================
  // LOCAL REFERENCE
  // ============================================================

  bool _isLocalReference(
    String value,
  ) {
    if (value.isEmpty) {
      return false;
    }

    if (value.startsWith(
      'file://',
    )) {
      return true;
    }

    // Linux / macOS.
    if (value.startsWith(
      '/',
    )) {
      return true;
    }

    // Windows.
    if (RegExp(
      r'^[a-zA-Z]:[\\/]',
    ).hasMatch(
      value,
    )) {
      return true;
    }

    return false;
  }

  // ============================================================
  // DISPLAY REFERENCE
  // ============================================================

  String _displayReference(
    String reference,
  ) {
    if (_isNetworkReference(
      reference,
    )) {
      final uri = Uri.tryParse(
        reference,
      );

      if (uri !=
              null &&
          uri.host.isNotEmpty) {
        final lastSegment = uri.pathSegments.isEmpty
            ? ''
            : uri.pathSegments.last;

        if (lastSegment.isNotEmpty) {
          return lastSegment;
        }

        return uri.host;
      }
    }

    final normalized = reference.replaceAll(
      '\\',
      '/',
    );

    final parts = normalized
        .split(
          '/',
        )
        .where(
          (
            part,
          ) => part.isNotEmpty,
        )
        .toList();

    if (parts.isNotEmpty) {
      return parts.last;
    }

    return reference;
  }
}
