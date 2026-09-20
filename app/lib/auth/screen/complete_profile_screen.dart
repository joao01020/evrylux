import 'package:flutter/material.dart';

import '../../profile/data/profile_repository.dart';
import '../../profile/models/user_profile.dart';

// ============================================================
// COMPLETE PROFILE SCREEN
// ============================================================

class CompleteProfileScreen
    extends
        StatefulWidget {
  const CompleteProfileScreen({
    super.key,
    required this.onCompleted,
    this.repository,
  });

  final VoidCallback onCompleted;

  final ProfileRepository? repository;

  @override
  State<
    CompleteProfileScreen
  >
  createState() {
    return _CompleteProfileScreenState();
  }
}

// ============================================================
// STATE
// ============================================================

class _CompleteProfileScreenState
    extends
        State<
          CompleteProfileScreen
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _nameController = TextEditingController();

  final FocusNode _nameFocusNode = FocusNode();

  // ============================================================
  // STATE
  // ============================================================

  late final ProfileRepository _repository;

  bool _isSaving = false;

  String? _errorMessage;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _backgroundColor = Color(
    0xFFF7FBF1,
  );

  static const Color _inputColor = Color(
    0xFFF3F8EE,
  );

  static const Color _borderColor = Color(
    0xFFC7DFC9,
  );

  static const Color _primaryColor = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryLightColor = Color(
    0xFF3B6939,
  );

  static const Color _textPrimary = Color(
    0xFF172019,
  );

  static const Color _textSecondary = Color(
    0xFF68746B,
  );

  static const Color _textMuted = Color(
    0xFF8A958C,
  );

  static const Color _errorColor = Color(
    0xFFB3261E,
  );

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _repository =
        widget.repository ??
        ProfileRepository();

    WidgetsBinding.instance.addPostFrameCallback(
      (
        _,
      ) {
        if (!mounted) {
          return;
        }

        _nameFocusNode.requestFocus();
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _nameController.dispose();

    _nameFocusNode.dispose();

    super.dispose();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  _saveName() async {
    if (_isSaving) {
      return;
    }

    final String name = _normalizeName(
      _nameController.text,
    );

    final String? validationError = _validateName(
      name,
    );

    if (validationError !=
        null) {
      setState(
        () {
          _errorMessage = validationError;
        },
      );

      _nameFocusNode.requestFocus();

      return;
    }

    FocusScope.of(
      context,
    ).unfocus();

    setState(
      () {
        _isSaving = true;
        _errorMessage = null;
      },
    );

    try {
      final UserProfile profile = await _repository.saveCurrentUserFullName(
        name,
      );

      if (!mounted) {
        return;
      }

      debugPrint(
        '[COMPLETE PROFILE] Perfil salvo: ${profile.fullName}',
      );

      widget.onCompleted();
    } on ArgumentError catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = _cleanErrorMessage(
            error.message?.toString(),
          );
        },
      );
    } on StateError catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _errorMessage = _cleanErrorMessage(
            error.message,
          );
        },
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      debugPrint(
        '[COMPLETE PROFILE] Erro: $error',
      );

      setState(
        () {
          _errorMessage = 'Não foi possível salvar seu nome. Tente novamente.';
        },
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _isSaving = false;
          },
        );
      }
    }
  }

  // ============================================================
  // NORMALIZE NAME
  // ============================================================

  String _normalizeName(
    String value,
  ) {
    return value.trim().replaceAll(
      RegExp(
        r'\s+',
      ),
      ' ',
    );
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validateName(
    String value,
  ) {
    if (value.isEmpty) {
      return 'Digite seu nome.';
    }

    if (value.length <
        2) {
      return 'Digite um nome válido.';
    }

    if (value.length >
        100) {
      return 'O nome pode ter no máximo 100 caracteres.';
    }

    return null;
  }

  // ============================================================
  // CLEAN ERROR
  // ============================================================

  String _cleanErrorMessage(
    String? message,
  ) {
    if (message ==
            null ||
        message.trim().isEmpty) {
      return 'Não foi possível continuar.';
    }

    return message
        .replaceFirst(
          'Invalid argument(s): ',
          '',
        )
        .replaceFirst(
          'Bad state: ',
          '',
        )
        .trim();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            _buildBackground(),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                  ),
                  child: _buildContent(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BACKGROUND
  // ============================================================

  Widget _buildBackground() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: 700,
                height: 420,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.9,
                    colors: [
                      _primaryColor.withValues(
                        alpha: 0.11,
                      ),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(),

        const SizedBox(
          height: 34,
        ),

        _buildNameField(),

        if (_errorMessage !=
            null) ...[
          const SizedBox(
            height: 14,
          ),

          _buildError(),
        ],

        const SizedBox(
          height: 24,
        ),

        _buildContinueButton(),

        const SizedBox(
          height: 18,
        ),

        _buildFooter(),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Como podemos chamar você?',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w700,
            height: 1.15,
            letterSpacing: -0.6,
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        Text(
          'Queremos deixar sua experiência mais pessoal.',
          style: TextStyle(
            color: _textSecondary.withValues(
              alpha: 0.95,
            ),
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // NAME FIELD
  // ============================================================

  Widget _buildNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nome',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        TextField(
          controller: _nameController,
          focusNode: _nameFocusNode,
          enabled: !_isSaving,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          autofillHints: const [
            AutofillHints.name,
          ],
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: _primaryLightColor,
          onChanged:
              (
                _,
              ) {
                if (_errorMessage ==
                    null) {
                  return;
                }

                setState(
                  () {
                    _errorMessage = null;
                  },
                );
              },
          onSubmitted:
              (
                _,
              ) {
                _saveName();
              },
          decoration: InputDecoration(
            hintText: 'Ex: João Vitor',
            hintStyle: const TextStyle(
              color: _textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 12,
              ),
              child: Icon(
                Icons.badge_outlined,
                color: _textMuted,
                size: 21,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
            ),
            filled: true,
            fillColor: _inputColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 19,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: const BorderSide(
                color: _borderColor,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: const BorderSide(
                color: _borderColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: const BorderSide(
                color: _primaryColor,
                width: 1.4,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                14,
              ),
              borderSide: const BorderSide(
                color: _errorColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _errorColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(
          12,
        ),
        border: Border.all(
          color: _errorColor.withValues(
            alpha: 0.22,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: _errorColor,
            size: 19,
          ),

          const SizedBox(
            width: 10,
          ),

          Expanded(
            child: Text(
              _errorMessage ??
                  '',
              style: const TextStyle(
                color: _errorColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONTINUE BUTTON
  // ============================================================

  Widget _buildContinueButton() {
    return SizedBox(
      height: 54,
      child: FilledButton(
        onPressed: _isSaving
            ? null
            : _saveName,
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          disabledBackgroundColor: _primaryColor.withValues(
            alpha: 0.45,
          ),
          foregroundColor: _primaryLightColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              14,
            ),
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(
            milliseconds: 180,
          ),
          child: _isSaving
              ? const SizedBox(
                  key: ValueKey(
                    'loading',
                  ),
                  width: 21,
                  height: 21,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: _primaryLightColor,
                  ),
                )
              : const Row(
                  key: ValueKey(
                    'continue',
                  ),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return const Text(
      'Você poderá alterar seu nome depois nas configurações.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: _textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
    );
  }
}
