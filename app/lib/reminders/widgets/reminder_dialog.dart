import 'package:flutter/material.dart';

import '../../app/dependencies/app_dependencies.dart' as dependencies;
import '../../telegram/widgets/telegram_connect_dialog.dart';

import '../controllers/reminder_controller.dart';

class ReminderDialog
    extends
        StatefulWidget {
  const ReminderDialog({
    super.key,
    required this.controller,
    this.initialTitle = '',
    this.initialMessage = '',
    this.sourceType,
    this.sourceId,
  });

  // ============================================================
  // CONTROLLER
  // ============================================================

  final ReminderController controller;

  // ============================================================
  // INITIAL DATA
  // ============================================================

  final String initialTitle;

  final String initialMessage;

  final String? sourceType;

  final String? sourceId;

  // ============================================================
  // SHOW
  // ============================================================

  static Future<
    bool?
  >
  show(
    BuildContext context, {
    required ReminderController controller,
    String initialTitle = '',
    String initialMessage = '',
    String? sourceType,
    String? sourceId,
  }) {
    return showDialog<
      bool
    >(
      context: context,
      barrierDismissible: false,
      builder:
          (
            context,
          ) {
            return ReminderDialog(
              controller: controller,
              initialTitle: initialTitle,
              initialMessage: initialMessage,
              sourceType: sourceType,
              sourceId: sourceId,
            );
          },
    );
  }

  // ============================================================
  // STATE
  // ============================================================

  @override
  State<
    ReminderDialog
  >
  createState() {
    return _ReminderDialogState();
  }
}

class _ReminderDialogState
    extends
        State<
          ReminderDialog
        > {
  // ============================================================
  // CORES
  // ============================================================

  static const Color _background = Color(
    0xFFFFFFFF,
  );

  static const Color _surface = Color(
    0xFFF7FBF1,
  );

  static const Color _surfaceSoft = Color(
    0xFFF3F8EE,
  );

  static const Color _border = Color(
    0xFFC7DFC9,
  );

  static const Color _primary = Color(
    0xFFBCF0B4,
  );

  static const Color _primaryDark = Color(
    0xFF3B6939,
  );

  static const Color _text = Color(
    0xFF172019,
  );

  static const Color _muted = Color(
    0xFF68746B,
  );

  static const Color _error = Color(
    0xFFB3261E,
  );

  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final TextEditingController _titleController;

  late final TextEditingController _messageController;

  // ============================================================
  // DATA
  // ============================================================

  late DateTime _selectedDate;

  late TimeOfDay _selectedTime;

  bool _notifyInApp = true;

  bool _notifyTelegram = false;

  bool _saving = false;

  String? _errorMessage;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.initialTitle,
    );

    _messageController = TextEditingController(
      text: widget.initialMessage,
    );

    final initial = _brasiliaNow.add(
      const Duration(
        hours: 1,
      ),
    );

    _selectedDate = DateTime(
      initial.year,
      initial.month,
      initial.day,
    );

    _selectedTime = TimeOfDay(
      hour: initial.hour,
      minute: initial.minute,
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _titleController.dispose();

    _messageController.dispose();

    super.dispose();
  }

  // ============================================================
  // DATE
  // ============================================================

  Future<
    void
  >
  _pickDate() async {
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(
        _brasiliaNow.year,
        _brasiliaNow.month,
        _brasiliaNow.day,
      ),
      lastDate: DateTime(
        _brasiliaNow.year +
            10,
      ),
      builder:
          (
            context,
            child,
          ) {
            return Theme(
              data:
                  Theme.of(
                    context,
                  ).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _primaryDark,
                      onPrimary: Colors.white,
                      surface: _background,
                      onSurface: _text,
                    ),
                    datePickerTheme: const DatePickerThemeData(
                      backgroundColor: _background,
                    ),
                  ),
              child: child!,
            );
          },
    );

    if (result ==
        null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _selectedDate = DateTime(
          result.year,
          result.month,
          result.day,
        );

        _errorMessage = null;
      },
    );
  }

  // ============================================================
  // TIME
  // ============================================================

  Future<
    void
  >
  _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder:
          (
            context,
            child,
          ) {
            return Theme(
              data:
                  Theme.of(
                    context,
                  ).copyWith(
                    colorScheme: const ColorScheme.light(
                      primary: _primaryDark,
                      onPrimary: Colors.white,
                      surface: _background,
                      onSurface: _text,
                    ),
                    timePickerTheme: const TimePickerThemeData(
                      backgroundColor: _background,
                    ),
                  ),
              child: child!,
            );
          },
    );

    if (result ==
        null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(
      () {
        _selectedTime = result;

        _errorMessage = null;
      },
    );
  }

  // ============================================================
  // HORÁRIO DE BRASÍLIA
  // ============================================================
  //
  // O horário escolhido pelo usuário é interpretado como
  // horário de Brasília / São Paulo (UTC-3).
  //
  // Isso evita depender do fuso configurado no computador.
  //
  // ============================================================

  DateTime get _brasiliaNow {
    final utcNow = DateTime.now().toUtc();

    final brasilia = utcNow.subtract(
      const Duration(
        hours: 3,
      ),
    );

    return DateTime(
      brasilia.year,
      brasilia.month,
      brasilia.day,
      brasilia.hour,
      brasilia.minute,
      brasilia.second,
      brasilia.millisecond,
      brasilia.microsecond,
    );
  }

  // ============================================================
  // REMIND AT
  // ============================================================
  //
  // Interpreta explicitamente o horário escolhido como UTC-3.
  //
  // Não depende do fuso horário configurado no Linux/Windows.
  //
  // Exemplo:
  //
  // 22:30 Brasília (-03:00)
  // vira
  // 01:30 UTC do dia seguinte.
  //
  // ============================================================

  DateTime get _remindAt {
    final year = _selectedDate.year.toString().padLeft(
      4,
      '0',
    );

    final month = _selectedDate.month.toString().padLeft(
      2,
      '0',
    );

    final day = _selectedDate.day.toString().padLeft(
      2,
      '0',
    );

    final hour = _selectedTime.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = _selectedTime.minute.toString().padLeft(
      2,
      '0',
    );

    final iso = '$year-$month-${day}T$hour:$minute:00-03:00';

    return DateTime.parse(
      iso,
    ).toUtc();
  }

  // ============================================================
  // SAVE
  // ============================================================

  Future<
    void
  >
  _save() async {
    if (_saving) {
      return;
    }

    final title = _titleController.text.trim();

    final message = _messageController.text.trim();

    if (title.isEmpty) {
      setState(
        () {
          _errorMessage = 'Digite um título para o lembrete.';
        },
      );

      return;
    }

    if (message.isEmpty) {
      setState(
        () {
          _errorMessage = 'Digite uma mensagem para o lembrete.';
        },
      );

      return;
    }

    final remindAt = _remindAt;

    if (!remindAt.isAfter(
      DateTime.now().toUtc(),
    )) {
      setState(
        () {
          _errorMessage = 'Escolha uma data e hora no futuro.';
        },
      );

      return;
    }

    if (!_notifyInApp &&
        !_notifyTelegram) {
      setState(
        () {
          _errorMessage = 'Selecione pelo menos uma forma de notificação.';
        },
      );

      return;
    }

    setState(
      () {
        _saving = true;

        _errorMessage = null;
      },
    );

    final result = await widget.controller.create(
      title: title,
      message: message,
      remindAt: remindAt,
      sourceType: widget.sourceType,
      sourceId: widget.sourceId,
      notifyInApp: _notifyInApp,
      notifyTelegram: _notifyTelegram,
    );

    if (!mounted) {
      return;
    }

    if (result ==
        null) {
      setState(
        () {
          _saving = false;

          _errorMessage =
              widget.controller.errorMessage ??
              'Não foi possível criar o lembrete.';
        },
      );

      return;
    }

    Navigator.of(
      context,
    ).pop(
      true,
    );
  }

  // ============================================================
  // TELEGRAM NOTIFICATION
  // ============================================================

  Future<void> _changeTelegramNotification(
    bool value,
  ) async {
    if (_saving) {
      return;
    }

    if (!value) {
      setState(
        () {
          _notifyTelegram = false;
          _errorMessage = null;
        },
      );

      return;
    }

    final telegramController = dependencies.telegramConnectionController;

    await telegramController.load();

    if (!mounted) {
      return;
    }

    if (!telegramController.isConnected) {
      final connected = await TelegramConnectDialog.show(
        context,
        controller: telegramController,
      );

      if (!mounted) {
        return;
      }

      if (connected != true) {
        setState(
          () {
            _notifyTelegram = false;
          },
        );

        return;
      }
    }

    setState(
      () {
        _notifyTelegram = true;
        _errorMessage = null;
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(
        24,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 520,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(
              22,
            ),
            border: Border.all(
              color: _border,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(
                  0x14000000,
                ),
                blurRadius: 26,
                offset: Offset(
                  0,
                  10,
                ),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(
              22,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =================================================
                // HEADER
                // =================================================
                _buildHeader(),

                const SizedBox(
                  height: 22,
                ),

                // =================================================
                // TITLE
                // =================================================
                _buildLabel(
                  'Título',
                ),

                const SizedBox(
                  height: 7,
                ),

                _buildTextField(
                  controller: _titleController,
                  hint: 'Ex: Comprar componentes',
                  icon: Icons.title_rounded,
                ),

                const SizedBox(
                  height: 16,
                ),

                // =================================================
                // MESSAGE
                // =================================================
                _buildLabel(
                  'Mensagem',
                ),

                const SizedBox(
                  height: 7,
                ),

                _buildTextField(
                  controller: _messageController,
                  hint: 'O que você quer lembrar?',
                  icon: Icons.notes_rounded,
                  minLines: 3,
                  maxLines: 5,
                ),

                const SizedBox(
                  height: 18,
                ),

                // =================================================
                // DATE AND TIME
                // =================================================
                Row(
                  children: [
                    Expanded(
                      child: _buildDateButton(),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child: _buildTimeButton(),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 8,
                ),

                const Row(
                  children: [
                    Icon(
                      Icons.public_rounded,
                      size: 14,
                      color: _muted,
                    ),

                    SizedBox(
                      width: 6,
                    ),

                    Text(
                      'Horário de Brasília (UTC-3)',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // NOTIFICATIONS
                // =================================================
                _buildLabel(
                  'Notificar em',
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildNotificationOption(
                  icon: Icons.notifications_none_rounded,
                  title: 'Aplicativo',
                  subtitle: 'Exibe o lembrete dentro do programa.',
                  value: _notifyInApp,
                  onChanged:
                      (
                        value,
                      ) {
                        setState(
                          () {
                            _notifyInApp = value;

                            _errorMessage = null;
                          },
                        );
                      },
                ),

                const SizedBox(
                  height: 8,
                ),

                _buildNotificationOption(
                  icon: Icons.send_outlined,
                  title: 'Telegram',
                  subtitle: 'Envia uma mensagem para seu celular.',
                  value: _notifyTelegram,
                  onChanged: (value) {
                    _changeTelegramNotification(value);
                  },
                ),

                // =================================================
                // ERROR
                // =================================================
                if (_errorMessage !=
                    null) ...[
                  const SizedBox(
                    height: 14,
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(
                      12,
                    ),
                    decoration: BoxDecoration(
                      color: _error.withValues(
                        alpha: 0.07,
                      ),
                      borderRadius: BorderRadius.circular(
                        11,
                      ),
                      border: Border.all(
                        color: _error.withValues(
                          alpha: 0.20,
                        ),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: _error,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],

                const SizedBox(
                  height: 22,
                ),

                // =================================================
                // ACTIONS
                // =================================================
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(
              13,
            ),
          ),
          child: const Icon(
            Icons.alarm_rounded,
            color: _primaryDark,
            size: 23,
          ),
        ),

        const SizedBox(
          width: 13,
        ),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Criar lembrete',
                style: TextStyle(
                  color: _text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),

              SizedBox(
                height: 3,
              ),

              Text(
                'Escolha quando você quer ser lembrado.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        IconButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop(
                    false,
                  );
                },
          icon: const Icon(
            Icons.close_rounded,
          ),
          color: _muted,
          tooltip: 'Fechar',
        ),
      ],
    );
  }

  // ============================================================
  // LABEL
  // ============================================================

  Widget _buildLabel(
    String text,
  ) {
    return Text(
      text,
      style: const TextStyle(
        color: _text,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      minLines: minLines,
      maxLines: maxLines,
      style: const TextStyle(
        color: _text,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: Icon(
          icon,
          color: _primaryDark,
          size: 19,
        ),
        filled: true,
        fillColor: _surfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: const BorderSide(
            color: _border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            12,
          ),
          borderSide: const BorderSide(
            color: _primaryDark,
            width: 1.3,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DATE BUTTON
  // ============================================================

  Widget _buildDateButton() {
    final day = _selectedDate.day.toString().padLeft(
      2,
      '0',
    );

    final month = _selectedDate.month.toString().padLeft(
      2,
      '0',
    );

    final year = _selectedDate.year;

    return _buildPickerButton(
      icon: Icons.calendar_month_outlined,
      label: 'Data',
      value: '$day/$month/$year',
      onTap: _pickDate,
    );
  }

  // ============================================================
  // TIME BUTTON
  // ============================================================

  Widget _buildTimeButton() {
    final hour = _selectedTime.hour.toString().padLeft(
      2,
      '0',
    );

    final minute = _selectedTime.minute.toString().padLeft(
      2,
      '0',
    );

    return _buildPickerButton(
      icon: Icons.schedule_rounded,
      label: 'Hora',
      value: '$hour:$minute',
      onTap: _pickTime,
    );
  }

  // ============================================================
  // PICKER BUTTON
  // ============================================================

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _saving
            ? null
            : onTap,
        borderRadius: BorderRadius.circular(
          13,
        ),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(
              13,
            ),
            border: Border.all(
              color: _border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  icon,
                  color: _primaryDark,
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
                      label,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      value,
                      style: const TextStyle(
                        color: _text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // NOTIFICATION OPTION
  // ============================================================

  Widget _buildNotificationOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<
      bool
    >
    onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: value
            ? _primary.withValues(
                alpha: 0.28,
              )
            : _surfaceSoft,
        borderRadius: BorderRadius.circular(
          13,
        ),
        border: Border.all(
          color: value
              ? _primaryDark.withValues(
                  alpha: 0.28,
                )
              : _border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: value
                  ? _primary
                  : _background,
              borderRadius: BorderRadius.circular(
                10,
              ),
            ),
            child: Icon(
              icon,
              color: _primaryDark,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 11,
          ),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(
                  height: 2,
                ),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 10,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,
            onChanged: _saving
                ? null
                : onChanged,
            activeThumbColor: _primaryDark,
            activeTrackColor: _primary,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  Navigator.of(
                    context,
                  ).pop(
                    false,
                  );
                },
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        const SizedBox(
          width: 8,
        ),

        ElevatedButton.icon(
          onPressed: _saving
              ? null
              : _save,
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: _primary,
            foregroundColor: _primaryDark,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                12,
              ),
            ),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _primaryDark,
                  ),
                )
              : const Icon(
                  Icons.alarm_add_rounded,
                  size: 18,
                ),
          label: Text(
            _saving
                ? 'Salvando...'
                : 'Criar lembrete',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
