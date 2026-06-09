import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/network/api_client.dart';

class SettingsState {
  final ThemeMode themeMode;
  final int simulationsCount;
  final String apiUrl;

  SettingsState({
    required this.themeMode,
    required this.simulationsCount,
    required this.apiUrl,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    int? simulationsCount,
    String? apiUrl,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      simulationsCount: simulationsCount ?? this.simulationsCount,
      apiUrl: apiUrl ?? this.apiUrl,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier()
      : super(SettingsState(
          themeMode: ThemeMode.dark,
          simulationsCount: 10000,
          apiUrl: 'http://127.0.0.1:8000/api/v1',
        ));

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setSimulationsCount(int count) {
    state = state.copyWith(simulationsCount: count);
  }

  void setApiUrl(String url) {
    state = state.copyWith(apiUrl: url);
    apiClient.updateBaseUrl(url);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
