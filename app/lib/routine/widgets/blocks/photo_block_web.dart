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

  @override
  Widget build(
    BuildContext context,
  ) {
    final reference = block.content.trim();
    final network = Uri.tryParse(
      reference,
    );
    final isNetwork =
        network !=
            null &&
        (network.scheme ==
                'https' ||
            network.scheme ==
                'http');

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(
        14,
      ),
      child: Container(
        padding: const EdgeInsets.all(
          12,
        ),
        decoration: BoxDecoration(
          color: const Color(
            0xFFF4F6F5,
          ),
          borderRadius: BorderRadius.circular(
            14,
          ),
          border: Border.all(
            color: const Color(
              0xFFD1D5DB,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              <
                Widget
              >[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      10,
                    ),
                    child: isNetwork
                        ? Image.network(
                            reference,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (
                                  _,
                                  _,
                                  _,
                                ) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(
                  height: 8,
                ),
                Text(
                  block.title.trim().isEmpty
                      ? 'Foto'
                      : block.title.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(
                      0xFF172019,
                    ),
                  ),
                ),
              ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: const Color(
        0xFFE5E7EB,
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children:
            <
              Widget
            >[
              Icon(
                Icons.image_outlined,
                size: 38,
                color: Color(
                  0xFF68746B,
                ),
              ),
              SizedBox(
                height: 8,
              ),
              Text(
                'Adicione uma URL de imagem no conteúdo.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(
                    0xFF68746B,
                  ),
                  fontSize: 12,
                ),
              ),
            ],
      ),
    );
  }
}
