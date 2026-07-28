mixin TrainingStatusState {
  bool isLoading = false;
  bool isSaving = false;
  bool isSavingPlan = false;

  String? errorMessage;
  String? successMessage;

  bool get hasError {
    return errorMessage?.isNotEmpty ?? false;
  }

  bool get hasSuccess {
    return successMessage?.isNotEmpty ?? false;
  }

  void setError(String message) {
    errorMessage = message;
    successMessage = null;
  }

  void setSuccess(String message) {
    successMessage = message;
    errorMessage = null;
  }

  void clearMessages() {
    errorMessage = null;
    successMessage = null;
  }

  void resetLoadingState() {
    isLoading = false;
    isSaving = false;
    isSavingPlan = false;
  }

  void resetStatusState() {
    resetLoadingState();
    clearMessages();
  }
}
