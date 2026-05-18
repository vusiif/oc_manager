import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../data/database/app_database.dart';

// 主题模式
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier(ref);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final Ref ref;

  ThemeModeNotifier(this.ref) : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final value = await ref.read(settingsDaoProvider).getValue('theme_mode');
    switch (value) {
      case 'light':
        state = ThemeMode.light;
        break;
      case 'dark':
        state = ThemeMode.dark;
        break;
      default:
        state = ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(settingsDaoProvider).setValue('theme_mode', mode.name);
  }
}

// 基本信息字段
final basicInfoFieldsProvider = FutureProvider<List<BasicInfoField>>((ref) async {
  final dao = ref.read(settingsDaoProvider);
  await dao.initDefaultFields();
  return dao.getBasicInfoFields();
});

// 基本信息字段操作
final basicInfoFieldActionsProvider = Provider((ref) => BasicInfoFieldActions(ref));

class BasicInfoFieldActions {
  final Ref ref;

  BasicInfoFieldActions(this.ref);

  Future<void> updateVisibility(int id, bool isVisible) async {
    await ref.read(settingsDaoProvider).updateBasicInfoField(id, isVisible: isVisible);
    ref.invalidate(basicInfoFieldsProvider);
  }

  Future<void> updateSortOrder(int id, int sortOrder) async {
    await ref.read(settingsDaoProvider).updateBasicInfoField(id, sortOrder: sortOrder);
    ref.invalidate(basicInfoFieldsProvider);
  }

  Future<void> addField(String fieldName) async {
    final fields = await ref.read(basicInfoFieldsProvider.future);
    await ref.read(settingsDaoProvider).addBasicInfoField(
      fieldName,
      sortOrder: fields.length,
    );
    ref.invalidate(basicInfoFieldsProvider);
  }

  Future<void> deleteField(int id) async {
    await ref.read(settingsDaoProvider).deleteBasicInfoField(id);
    ref.invalidate(basicInfoFieldsProvider);
  }
}
