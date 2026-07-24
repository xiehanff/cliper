import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../application/controllers/app_controller.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import 'color_dot.dart';

class NewGroupInput extends StatefulWidget {
  final VoidCallback onDone;

  const NewGroupInput({super.key, required this.onDone});

  @override
  State<NewGroupInput> createState() => _NewGroupInputState();
}

class _NewGroupInputState extends State<NewGroupInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _selectedColor = AppConstants.groupColors.first;
  String? _errorText;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleTapOutside() {
    if (mounted && !_finished) {
      _confirm();
    }
  }

  void _confirm() {
    if (_finished) return;
    final name = _controller.text.trim();
    if (name.isEmpty) {
      _cancel();
      return;
    }
    final controller = Provider.of<AppController>(context, listen: false);
    if (controller.isGroupNameTaken(name)) {
      setState(() {
        _errorText = _duplicateNameText(controller.currentLanguage);
      });
      _focusNode.requestFocus();
      return;
    }
    _finished = true;
    controller.createGroup(name, _selectedColor);
    widget.onDone();
  }

  void _cancel() {
    if (_finished) return;
    _finished = true;
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final l10n = AppLocalizations.of(context);

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.escape): _cancel,
      },
      child: TapRegion(
        onTapOutside: (_) => _handleTapOutside(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ColorDot(color: _selectedColor, size: 10),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onSubmitted: (_) => _confirm(),
                      onChanged: (_) {
                        if (_errorText != null) {
                          setState(() => _errorText = null);
                        }
                      },
                      style: TextStyle(color: theme.primaryText, fontSize: 12),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        hintText: l10n.groupNamePlaceholder,
                        hintStyle: TextStyle(
                          color: theme.secondaryText,
                          fontSize: 12,
                        ),
                        filled: true,
                        fillColor: theme.cardBackground,
                        errorText: _errorText,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.purpleAccent,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: theme.purpleAccentDark,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: AppConstants.groupColors
                      .map(
                        (c) => ColorDot(
                          color: c,
                          size: 20,
                          selected: c == _selectedColor,
                          onTap: () {
                            setState(() => _selectedColor = c);
                            _focusNode.requestFocus();
                          },
                          borderColor: theme.brightness == Brightness.light
                              ? Colors.black.withValues(alpha: 0.12)
                              : Colors.transparent,
                          selectedBorderColor:
                              theme.brightness == Brightness.light
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : Colors.white,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _duplicateNameText(String language) {
    return language == 'en' ? 'Group name already exists' : '分组名称已存在';
  }
}
