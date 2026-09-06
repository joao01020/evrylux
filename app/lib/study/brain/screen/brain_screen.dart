import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/dependencies/app_dependencies.dart' as dependencies;
import '../../../brain/visualization/brain_visualization.dart';
import '../../../brain/visualization/painters/brain_paths.dart';

import '../controllers/brain_controller.dart';
import '../experience/controllers/brain_experience_controller.dart';
import '../experience/services/brain_initialization_service.dart';

import '../models/brain_concept.dart';
import '../models/brain_file.dart';
import '../models/brain_source.dart';
import '../settings/models/brain_data_mode.dart';

import '../search/models/brain_search_response.dart';
import '../search/services/brain_search_engine.dart';
import '../search/services/brain_search_parser.dart';
import '../search/widgets/brain_search_help_dialog.dart';
import '../source/widgets/brain_source_dialog.dart';

// ============================================================
// SCREENS
// ============================================================

import 'concept/concept_screen.dart';
import 'question/question_screen.dart';
import 'example/example_screen.dart';
import 'warning/warning_screen.dart';
import 'note/brain_note_screen.dart';

part 'brain_screen_parts/brain_screen_core.dart';
part 'brain_screen_parts/brain_screen_visual_search.dart';
part 'brain_screen_parts/brain_screen_creation.dart';
part 'brain_screen_parts/brain_screen_layout.dart';
part 'brain_screen_parts/brain_screen_models.dart';

// ============================================================
// BRAIN SCREEN
// ============================================================
//
// Responsabilidade desta tela:
//
// - compor a experiência visual;
// - reagir aos controllers;
// - abrir navegação e dialogs pertencentes à UI.
//
// A coordenação da primeira experiência NÃO mora mais aqui.
// Ela foi extraída para:
//
// BrainExperienceController
//        ↓
// BrainInitializationService
//
// O BrainController continua sendo a instância global offline-first
// criada em app_dependencies.dart.
//
// ============================================================

class BrainScreen
    extends
        StatefulWidget {
  const BrainScreen({
    super.key,
  });

  @override
  State<
    BrainScreen
  >
  createState() {
    return _BrainScreenState();
  }
}

class _BrainScreenState
    extends
        State<
          BrainScreen
        > {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  late final BrainController _controller;

  late final BrainExperienceController _experienceController;

  // ============================================================
  // CÉREBRO VISUAL — EVRYLUX
  // ============================================================

  BrainVisualController? _brainVisualController;

  Timer? _brainSearchPulseStopTimer;

  bool _brainVisualReady = false;

  int _brainVisualKnowledgeCount = 0;

  static const Duration _brainGrowthPreviewDuration = Duration(
    milliseconds: 2050,
  );

  // ============================================================
  // PRIMEIRA EXPERIÊNCIA
  // ============================================================

  bool _dataModeDialogRunning = false;

  bool _dataModeDialogScheduled = false;

  bool _experienceErrorShown = false;

  // ============================================================
  // PESQUISA
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  static const BrainSearchParser _searchParser = BrainSearchParser();

  static const BrainSearchEngine _searchEngine = BrainSearchEngine();

  bool _showAllSearchResults = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // ========================================================
    // CONTROLLER GLOBAL OFFLINE-FIRST
    // ========================================================
    //
    // BrainScreen não cria um BrainController local.
    //
    // Mantemos a instância global configurada no container:
    //
    // BrainController
    //      ↓
    // BrainRepository
    //      ↓
    // armazenamento local / Vault
    //      ↓
    // SyncQueue
    //      ↓
    // SyncService
    //      ↓
    // Supabase
    //
    // ========================================================

    _controller = dependencies.brainController;

    // ========================================================
    // PRIMEIRA EXPERIÊNCIA
    // ========================================================
    //
    // O service carrega os dados necessários.
    // O controller coordena o fluxo.
    // A Screen apenas reage ao estado.
    //
    // ========================================================

    final initializationService = BrainInitializationService(
      brainController: _controller,
      visualStateStorage: BrainVisualStateStorage(
        storageScope: dependencies.userStorageScope,
      ),
      dataModeStorage: dependencies.brainDataModeStorage,
    );

    _experienceController = BrainExperienceController(
      initializationService: initializationService,
    );

    _controller.addListener(
      _onControllerChanged,
    );

    _experienceController.addListener(
      _onExperienceChanged,
    );

    unawaited(
      _initialize(),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _experienceController.removeListener(
      _onExperienceChanged,
    );

    _brainSearchPulseStopTimer?.cancel();

    _brainVisualController?.dispose();

    _experienceController.dispose();

    _searchController.dispose();

    // ========================================================
    // NÃO FAZER _controller.dispose()
    // ========================================================
    //
    // O BrainController pertence ao container global da aplicação.
    //
    // ========================================================

    super.dispose();
  }

  // ============================================================
  // CONTROLLER GLOBAL
  // ============================================================

  void _onControllerChanged() {
    _mutateState(
      () {},
    );
  }

  // ============================================================
  // EXPERIENCE CONTROLLER
  // ============================================================

  void _onExperienceChanged() {
    if (!mounted) {
      return;
    }

    _prepareBrainVisualFromExperience();

    _mutateState(
      () {},
    );

    _scheduleDataModeChoiceIfNeeded();

    _showExperienceErrorIfNeeded();
  }

  // ============================================================
  // STATE MUTATION GATE
  // ============================================================
  //
  // Extensions da BrainScreen não chamam State.setState()
  // diretamente.
  //
  // Isso mantém o acesso ao membro protegido dentro da própria
  // subclasse de State e oferece um único ponto seguro para
  // atualizações vindas dos módulos da tela.
  //
  // ============================================================

  void _mutateState(
    VoidCallback mutation,
  ) {
    if (!mounted) {
      return;
    }

    setState(
      mutation,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      // ========================================================
      // APP BAR
      // ========================================================
      //
      // Mantemos a AppBar para preservar o botão de voltar,
      // mas removemos o título "Cérebro" e o ícone do topo.
      //
      // ========================================================
      appBar: AppBar(),

      body:
          _controller.isLoading ||
              _experienceController.isInitializing
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildBody(
              context,
            ),
    );
  }
}
