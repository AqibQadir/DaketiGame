import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/tutorial_storage_service.dart';
import '../../domain/tutorial_demo_state.dart';
import '../../domain/tutorial_step.dart';

class TutorialController extends ChangeNotifier {
  TutorialController({TutorialStorageService? storage})
      : _storage = storage ?? TutorialStorageService();

  final TutorialStorageService _storage;
  int _stepIndex = 0;
  bool _targetCompleted = false;
  Timer? _advanceTimer;

  int get stepIndex => _stepIndex;
  TutorialStep get step => tutorialSteps[_stepIndex];
  TutorialDemoState get demo => TutorialDemoState.forStep(_stepIndex);
  int get stepCount => tutorialSteps.length;
  bool get isFirst => _stepIndex == 0;
  bool get isLast => _stepIndex == tutorialSteps.length - 1;
  bool get canAdvance => !step.requiresTargetTap || _targetCompleted;

  void targetTapped() {
    if (!step.requiresTargetTap || _targetCompleted) return;
    _targetCompleted = true;
    notifyListeners();
    _advanceTimer?.cancel();
    _advanceTimer = Timer(const Duration(milliseconds: 260), next);
  }

  void next() {
    if (!canAdvance || isLast) return;
    _advanceTimer?.cancel();
    _stepIndex++;
    _targetCompleted = false;
    notifyListeners();
  }

  void back() {
    if (isFirst) return;
    _advanceTimer?.cancel();
    _stepIndex--;
    _targetCompleted = false;
    notifyListeners();
  }

  void restart() {
    _advanceTimer?.cancel();
    _stepIndex = 0;
    _targetCompleted = false;
    notifyListeners();
  }

  Future<void> complete() => _storage.markCompleted();

  @override
  void dispose() {
    _advanceTimer?.cancel();
    super.dispose();
  }
}
