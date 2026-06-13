import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../application/controllers/app_controller.dart';

class AppLocalizations {
  final String _language;

  const AppLocalizations._(this._language);

  static AppLocalizations of(BuildContext context) {
    final controller = Provider.of<AppController>(context, listen: false);
    return AppLocalizations._(controller.currentLanguage);
  }

  static AppLocalizations forLanguage(String language) {
    return AppLocalizations._(language);
  }

  Map<String, String> get _strings {
    return _language == 'en' ? _en : _zh;
  }

  String get realtime => _strings['realtime']!;
  String get collections => _strings['collections']!;
  String get newGroup => _strings['newGroup']!;
  String get deleteGroupConfirm => _strings['deleteGroupConfirm']!;
  String get groupNamePlaceholder => _strings['groupNamePlaceholder']!;
  String get doubleClickToCopy => _strings['doubleClickToCopy']!;
  String get empty => _strings['empty']!;
  String get delete => _strings['delete']!;
  String get settings => _strings['settings']!;
  String get language => _strings['language']!;
  String get switchTo => _strings['switchTo']!;
  String get shortcut => _strings['shortcut']!;
  String get theme => _strings['theme']!;
  String get dark => _strings['dark']!;
  String get light => _strings['light']!;
  String get editShortcut => _strings['editShortcut']!;
  String get waitingForKey => _strings['waitingForKey']!;

  static const Map<String, String> _zh = {
    'realtime': '实时剪贴板',
    'collections': '收藏夹',
    'newGroup': '新建分组',
    'deleteGroupConfirm': '确定要删除这个分组吗？',
    'groupNamePlaceholder': '分组名称...',
    'doubleClickToCopy': '双击复制',
    'empty': '空',
    'delete': '删除',
    'settings': '设置',
    'language': '语言',
    'switchTo': 'En',
    'shortcut': '快捷键',
    'theme': '主题',
    'dark': '深色',
    'light': '浅色',
    'editShortcut': '点击修改',
    'waitingForKey': '等待按键',
  };

  static const Map<String, String> _en = {
    'realtime': 'Realtime History',
    'collections': 'Collections',
    'newGroup': 'New Group',
    'deleteGroupConfirm': 'Delete group?',
    'groupNamePlaceholder': 'Name...',
    'doubleClickToCopy': 'Double-click to copy',
    'empty': 'Empty',
    'delete': 'Delete',
    'settings': 'Settings',
    'language': 'Language',
    'switchTo': '中',
    'shortcut': 'Shortcut',
    'theme': 'Theme',
    'dark': 'Dark',
    'light': 'Light',
    'editShortcut': 'Click to edit',
    'waitingForKey': 'Waiting for keys',
  };
}
