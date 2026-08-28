import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen
    extends
        StatefulWidget {
  const LoginScreen({
    super.key,
  });

  @override
  State<
    LoginScreen
  >
  createState() => _LoginScreenState();
}

class _LoginScreenState
    extends
        State<
          LoginScreen
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _confirmPasswordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool _loading = false;

  bool _isLogin = true;

  bool _obscurePassword = true;

  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  String? _successMessage;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _background = Color(
    0xFF090A0E,
  );

  static const Color _surface = Color(
    0xFF111319,
  );

  static const Color _surfaceLight = Color(
    0xFF171A22,
  );

  static const Color _border = Color(
    0xFF272B36,
  );

  static const Color _primary = Color(
    0xFF7C5CFF,
  );

  static const Color _primaryLight = Color(
    0xFFA18CFF,
  );

  static const Color _text = Color(
    0xFFF5F7FA,
  );

  static const Color _muted = Color(
    0xFF9298A6,
  );

  static const Color _error = Color(
    0xFFFF8DAA,
  );

  static const Color _success = Color(
    0xFF8BFFB0,
  );

  // ============================================================
  // SUPABASE
  // ============================================================

  SupabaseClient get _supabase => Supabase.instance.client;

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _emailController.dispose();

    _passwordController.dispose();

    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // SUBMIT
  // ============================================================

  Future<
    void
  >
  _submit() async {
    if (_loading) {
      return;
    }

    final email = _emailController.text.trim();

    final password = _passwordController.text;

    final confirmPassword = _confirmPasswordController.text;

    // ==========================================================
    // VALIDATE EMAIL
    // ==========================================================

    if (email.isEmpty) {
      _showError(
        'Digite seu email.',
      );

      return;
    }

    if (!_isValidEmail(
      email,
    )) {
      _showError(
        'Digite um email válido.',
      );

      return;
    }

    // ==========================================================
    // VALIDATE PASSWORD
    // ==========================================================

    if (password.isEmpty) {
      _showError(
        'Digite sua senha.',
      );

      return;
    }

    if (password.length <
        6) {
      _showError(
        'A senha precisa ter pelo menos 6 caracteres.',
      );

      return;
    }

    // ==========================================================
    // REGISTER VALIDATION
    // ==========================================================

    if (!_isLogin) {
      if (confirmPassword.isEmpty) {
        _showError(
          'Confirme sua senha.',
        );

        return;
      }

      if (password !=
          confirmPassword) {
        _showError(
          'As senhas não são iguais.',
        );

        return;
      }
    }

    // ==========================================================
    // START LOADING
    // ==========================================================

    setState(
      () {
        _loading = true;

        _errorMessage = null;

        _successMessage = null;
      },
    );

    try {
      if (_isLogin) {
        await _login(
          email: email,
          password: password,
        );
      } else {
        await _register(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showError(
        _translateAuthError(
          error,
        ),
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showError(
        'Não foi possível concluir a autenticação.\n$error',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _loading = false;
          },
        );
      }
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<
    void
  >
  _login({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user ==
        null) {
      throw StateError(
        'O Supabase não retornou um usuário autenticado.',
      );
    }

    debugPrint(
      '[AUTH] LOGIN OK',
    );

    debugPrint(
      '[AUTH] USER ID: ${response.user!.id}',
    );
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<
    void
  >
  _register({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final user = response.user;

    if (user ==
        null) {
      throw StateError(
        'Não foi possível criar a conta.',
      );
    }

    debugPrint(
      '[AUTH] USER CREATED: ${user.id}',
    );

    // ==========================================================
    // EMAIL CONFIRMATION
    // ==========================================================
    //
    // Se confirmação de email estiver habilitada no Supabase,
    // signUp cria o usuário, mas session pode continuar null.
    //
    // ==========================================================

    if (response.session ==
        null) {
      if (!mounted) {
        return;
      }

      setState(
        () {
          _successMessage = 'Conta criada. Verifique seu email para confirmar o cadastro.';

          _isLogin = true;

          _passwordController.clear();

          _confirmPasswordController.clear();
        },
      );

      return;
    }

    debugPrint(
      '[AUTH] REGISTER + SESSION OK',
    );
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<
    void
  >
  _forgotPassword() async {
    if (_loading) {
      return;
    }

    final email = _emailController.text.trim();

    if (email.isEmpty ||
        !_isValidEmail(
          email,
        )) {
      _showError(
        'Digite seu email antes de recuperar a senha.',
      );

      return;
    }

    setState(
      () {
        _loading = true;

        _errorMessage = null;

        _successMessage = null;
      },
    );

    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
      );

      if (!mounted) {
        return;
      }

      setState(
        () {
          _successMessage = 'Enviamos as instruções de recuperação para seu email.';
        },
      );
    } on AuthException catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showError(
        _translateAuthError(
          error,
        ),
      );
    } catch (
      error
    ) {
      if (!mounted) {
        return;
      }

      _showError(
        'Não foi possível enviar a recuperação de senha.\n$error',
      );
    } finally {
      if (mounted) {
        setState(
          () {
            _loading = false;
          },
        );
      }
    }
  }

  // ============================================================
  // TOGGLE MODE
  // ============================================================

  void _toggleMode() {
    if (_loading) {
      return;
    }

    setState(
      () {
        _isLogin = !_isLogin;

        _errorMessage = null;

        _successMessage = null;

        _passwordController.clear();

        _confirmPasswordController.clear();
      },
    );
  }

  // ============================================================
  // SHOW ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    setState(
      () {
        _errorMessage = message;

        _successMessage = null;
      },
    );
  }

  // ============================================================
  // VALID EMAIL
  // ============================================================

  bool _isValidEmail(
    String email,
  ) {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(
      email,
    );
  }

  // ============================================================
  // AUTH ERROR TRANSLATION
  // ============================================================

  String _translateAuthError(
    AuthException error,
  ) {
    final message = error.message.toLowerCase();

    if (message.contains(
      'invalid login credentials',
    )) {
      return 'Email ou senha incorretos.';
    }

    if (message.contains(
      'email not confirmed',
    )) {
      return 'Confirme seu email antes de entrar.';
    }

    if (message.contains(
      'user already registered',
    )) {
      return 'Já existe uma conta com esse email.';
    }

    if (message.contains(
      'password should be at least',
    )) {
      return 'A senha é muito curta.';
    }

    if (message.contains(
      'signup is disabled',
    )) {
      return 'O cadastro de novos usuários está desativado no Supabase.';
    }

    if (message.contains(
      'email rate limit exceeded',
    )) {
      return 'Muitas tentativas. Aguarde um pouco antes de tentar novamente.';
    }

    return error.message;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          // ====================================================
          // BACKGROUND GLOW
          // ====================================================
          Positioned(
            top: -220,
            right: -160,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primary.withValues(
                      alpha: .15,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            bottom: -250,
            left: -180,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _primaryLight.withValues(
                      alpha: .08,
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ====================================================
          // CONTENT
          // ====================================================
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 440,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(
                      30,
                    ),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(
                        22,
                      ),
                      border: Border.all(
                        color: _border,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(
                            0x55000000,
                          ),
                          blurRadius: 30,
                          offset: Offset(
                            0,
                            14,
                          ),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ======================================
                        // LOGO
                        // ======================================
                        Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: _primary.withValues(
                                alpha: .12,
                              ),
                              borderRadius: BorderRadius.circular(
                                17,
                              ),
                              border: Border.all(
                                color: _primary.withValues(
                                  alpha: .35,
                                ),
                              ),
                            ),
                            child: const Icon(
                              Icons.auto_awesome_outlined,
                              color: _primaryLight,
                              size: 29,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 18,
                        ),

                        // ======================================
                        // TITLE
                        // ======================================
                        Text(
                          _isLogin
                              ? 'Bem-vindo'
                              : 'Criar conta',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _text,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: .3,
                          ),
                        ),

                        const SizedBox(
                          height: 7,
                        ),

                        Text(
                          _isLogin
                              ? 'Entre para continuar sua evolução.'
                              : 'Crie sua conta para salvar sua evolução na nuvem.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),

                        const SizedBox(
                          height: 28,
                        ),

                        // ======================================
                        // EMAIL
                        // ======================================
                        _AuthField(
                          controller: _emailController,
                          enabled: !_loading,
                          label: 'Email',
                          hint: 'voce@email.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          onSubmitted:
                              (
                                _,
                              ) {
                                if (_isLogin) {
                                  _submit();
                                }
                              },
                        ),

                        const SizedBox(
                          height: 14,
                        ),

                        // ======================================
                        // PASSWORD
                        // ======================================
                        _AuthField(
                          controller: _passwordController,
                          enabled: !_loading,
                          label: 'Senha',
                          hint: 'Digite sua senha',
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(
                                () {
                                  _obscurePassword = !_obscurePassword;
                                },
                              );
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _muted,
                              size: 19,
                            ),
                          ),
                          onSubmitted:
                              (
                                _,
                              ) {
                                if (_isLogin) {
                                  _submit();
                                }
                              },
                        ),

                        // ======================================
                        // CONFIRM PASSWORD
                        // ======================================
                        if (!_isLogin) ...[
                          const SizedBox(
                            height: 14,
                          ),
                          _AuthField(
                            controller: _confirmPasswordController,
                            enabled: !_loading,
                            label: 'Confirmar senha',
                            hint: 'Digite a senha novamente',
                            icon: Icons.lock_reset_outlined,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(
                                  () {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  },
                                );
                              },
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _muted,
                                size: 19,
                              ),
                            ),
                            onSubmitted:
                                (
                                  _,
                                ) => _submit(),
                          ),
                        ],

                        // ======================================
                        // FORGOT PASSWORD
                        // ======================================
                        if (_isLogin) ...[
                          const SizedBox(
                            height: 8,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _loading
                                  ? null
                                  : _forgotPassword,
                              child: const Text(
                                'Esqueci minha senha',
                                style: TextStyle(
                                  color: _primaryLight,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ],

                        // ======================================
                        // ERROR
                        // ======================================
                        if (_errorMessage !=
                            null) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          _MessageBox(
                            message: _errorMessage!,
                            color: _error,
                            icon: Icons.error_outline_rounded,
                          ),
                        ],

                        // ======================================
                        // SUCCESS
                        // ======================================
                        if (_successMessage !=
                            null) ...[
                          const SizedBox(
                            height: 12,
                          ),
                          _MessageBox(
                            message: _successMessage!,
                            color: _success,
                            icon: Icons.check_circle_outline_rounded,
                          ),
                        ],

                        const SizedBox(
                          height: 22,
                        ),

                        // ======================================
                        // SUBMIT
                        // ======================================
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading
                                ? null
                                : _submit,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: _primary,
                              disabledBackgroundColor: _primary.withValues(
                                alpha: .45,
                              ),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  13,
                                ),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _isLogin
                                            ? Icons.login_rounded
                                            : Icons.person_add_alt_1_rounded,
                                        size: 18,
                                      ),
                                      const SizedBox(
                                        width: 8,
                                      ),
                                      Text(
                                        _isLogin
                                            ? 'Entrar'
                                            : 'Criar conta',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // ======================================
                        // CHANGE MODE
                        // ======================================
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Ainda não tem conta?'
                                  : 'Já possui uma conta?',
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                            TextButton(
                              onPressed: _loading
                                  ? null
                                  : _toggleMode,
                              child: Text(
                                _isLogin
                                    ? 'Criar conta'
                                    : 'Entrar',
                                style: const TextStyle(
                                  color: _primaryLight,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// AUTH FIELD
// ============================================================

class _AuthField
    extends
        StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.enabled = true,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.onSubmitted,
  });

  final TextEditingController controller;

  final String label;

  final String hint;

  final IconData icon;

  final bool enabled;

  final bool obscureText;

  final TextInputType? keyboardType;

  final Widget? suffixIcon;

  final ValueChanged<
    String
  >?
  onSubmitted;

  @override
  Widget build(
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onSubmitted: onSubmitted,
      style: const TextStyle(
        color: _LoginScreenState._text,
        fontSize: 13,
      ),
      cursorColor: _LoginScreenState._primaryLight,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          color: _LoginScreenState._muted,
          fontSize: 12,
        ),
        hintStyle: const TextStyle(
          color: Color(
            0xFF686F7C,
          ),
          fontSize: 12,
        ),
        prefixIcon: Icon(
          icon,
          color: _LoginScreenState._muted,
          size: 19,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _LoginScreenState._surfaceLight,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: const BorderSide(
            color: _LoginScreenState._border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: const BorderSide(
            color: _LoginScreenState._primary,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: const BorderSide(
            color: _LoginScreenState._border,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MESSAGE BOX
// ============================================================

class _MessageBox
    extends
        StatelessWidget {
  const _MessageBox({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String message;

  final Color color;

  final IconData icon;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      padding: const EdgeInsets.all(
        12,
      ),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: .08,
        ),
        borderRadius: BorderRadius.circular(
          11,
        ),
        border: Border.all(
          color: color.withValues(
            alpha: .45,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color,
            size: 18,
          ),
          const SizedBox(
            width: 9,
          ),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
