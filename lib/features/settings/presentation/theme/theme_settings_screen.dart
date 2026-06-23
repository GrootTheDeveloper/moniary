import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_theme.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../application/theme_settings_controller.dart';
import '../../domain/theme/app_theme_settings.dart';

class ThemeSettingsScreen extends ConsumerStatefulWidget {
  const ThemeSettingsScreen({super.key});

  static const routePath = '/theme-settings';

  @override
  ConsumerState<ThemeSettingsScreen> createState() =>
      _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends ConsumerState<ThemeSettingsScreen> {
  late AppThemeSettings _draft;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(themeSettingsControllerProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final current = ref.read(themeSettingsControllerProvider);
    if (_draft.presetId != AppThemeSettings.customPresetId) {
      _draft = current;
    }
  }

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(themeSettingsControllerProvider);
    final colors = context.moniaryColors;

    return Theme(
      data: AppTheme.fromSettings(_draft),
      child: Builder(
        builder: (context) {
          final previewColors = context.moniaryColors;
          return Scaffold(
            appBar: AppBar(title: Text(context.l10n.themeSettingsTitle)),
            body: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              children: [
                _PreviewCard(settings: _draft),
                const SizedBox(height: 20),
                _SectionTitle(text: context.l10n.themePresetSection),
                const SizedBox(height: 10),
                _PresetSelector(
                  draft: _draft,
                  onSelected: (preset) {
                    setState(() => _draft = preset);
                  },
                ),
                const SizedBox(height: 22),
                _SectionTitle(text: context.l10n.themeColorsSection),
                const SizedBox(height: 10),
                _ColorTile(
                  label: context.l10n.themePrimaryColor,
                  colorValue: _draft.primaryColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themePrimaryColor,
                    initialColor: Color(_draft.primaryColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(primaryColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeSecondaryColor,
                  colorValue: _draft.secondaryColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeSecondaryColor,
                    initialColor: Color(_draft.secondaryColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(secondaryColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeBackgroundColor,
                  colorValue: _draft.backgroundColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeBackgroundColor,
                    initialColor: Color(_draft.backgroundColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(backgroundColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeSurfaceColor,
                  colorValue: _draft.surfaceColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeSurfaceColor,
                    initialColor: Color(_draft.surfaceColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(surfaceColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeTextPrimaryColor,
                  colorValue: _draft.textPrimaryColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeTextPrimaryColor,
                    initialColor: Color(_draft.textPrimaryColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(textPrimaryColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeTextSecondaryColor,
                  colorValue: _draft.textSecondaryColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeTextSecondaryColor,
                    initialColor: Color(_draft.textSecondaryColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(textSecondaryColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeButtonColor,
                  colorValue: _draft.buttonColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeButtonColor,
                    initialColor: Color(_draft.buttonColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(buttonColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeIconColor,
                  colorValue: _draft.iconColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeIconColor,
                    initialColor: Color(_draft.iconColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(iconColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeAppBarColor,
                  colorValue: _draft.appBarColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeAppBarColor,
                    initialColor: Color(_draft.appBarColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(appBarColor: color.toARGB32()),
                    ),
                  ),
                ),
                _ColorTile(
                  label: context.l10n.themeNavigationBarColor,
                  colorValue: _draft.navigationBarColor,
                  onTap: () => _pickColor(
                    context,
                    title: context.l10n.themeNavigationBarColor,
                    initialColor: Color(_draft.navigationBarColor),
                    onSelected: (color) => _updateDraft(
                      _draft.copyWith(navigationBarColor: color.toARGB32()),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed:
                      _draft.toJson().toString() == saved.toJson().toString()
                      ? null
                      : () => _saveTheme(context),
                  icon: const Icon(Icons.check_outlined),
                  label: Text(context.l10n.themeApplySave),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => _resetTheme(context),
                  icon: Icon(Icons.restart_alt_outlined, color: colors.icon),
                  label: Text(context.l10n.themeResetDefault),
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.themeSaveHint,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: previewColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _updateDraft(AppThemeSettings settings) {
    setState(() => _draft = settings.asCustom());
  }

  Future<void> _saveTheme(BuildContext context) async {
    try {
      await ref.read(themeSettingsControllerProvider.notifier).save(_draft);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.themeSavedMessage)));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to save custom theme settings',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
    }
  }

  Future<void> _resetTheme(BuildContext context) async {
    try {
      await ref.read(themeSettingsControllerProvider.notifier).resetToDefault();
      setState(() => _draft = AppThemeSettings.defaults);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.themeResetMessage)));
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to reset custom theme settings',
        error,
        stackTrace,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
    }
  }

  Future<void> _pickColor(
    BuildContext context, {
    required String title,
    required Color initialColor,
    required ValueChanged<Color> onSelected,
  }) async {
    final selected = await showDialog<Color>(
      context: context,
      builder: (context) =>
          _ColorPickerDialog(title: title, initialColor: initialColor),
    );

    if (selected != null) {
      onSelected(selected);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({required this.draft, required this.onSelected});

  final AppThemeSettings draft;
  final ValueChanged<AppThemeSettings> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppThemeSettings.presets.map((preset) {
        final selected = draft.presetId == preset.presetId;
        return ChoiceChip(
          selected: selected,
          label: Text(_presetLabel(context, preset.presetId)),
          avatar: CircleAvatar(
            backgroundColor: Color(preset.primaryColor),
            radius: 8,
          ),
          onSelected: (_) => onSelected(preset),
        );
      }).toList(),
    );
  }

  String _presetLabel(BuildContext context, String presetId) {
    switch (presetId) {
      case AppThemeSettings.defaultPresetId:
        return context.l10n.themePresetDefault;
      case 'emerald':
        return context.l10n.themePresetEmerald;
      case 'rose':
        return context.l10n.themePresetRose;
      case 'high_contrast':
        return context.l10n.themePresetHighContrast;
      default:
        return context.l10n.themePresetCustom;
    }
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.settings});

  final AppThemeSettings settings;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Color(settings.appBarColor),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border(bottom: BorderSide(color: colors.outline)),
            ),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, color: colors.icon),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    context.l10n.themePreviewTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(Icons.more_horiz, color: colors.icon),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.themePreviewHeadline,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.themePreviewBody,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () {},
                        child: Text(context.l10n.themePreviewButton),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.savings_outlined, color: colors.icon),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: colors.navBar,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Icon(Icons.calendar_month_outlined, color: colors.primary),
                Icon(Icons.pie_chart_outline, color: colors.navInactive),
                Icon(Icons.groups_2_outlined, color: colors.navInactive),
                Icon(Icons.person_outlined, color: colors.navInactive),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorTile extends StatelessWidget {
  const _ColorTile({
    required this.label,
    required this.colorValue,
    required this.onTap,
  });

  final String label;
  final int colorValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outline),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Color(colorValue),
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.outline),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      _colorToHex(colorValue),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Icon(Icons.tune_outlined, color: colors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPickerDialog extends StatefulWidget {
  const _ColorPickerDialog({required this.title, required this.initialColor});

  final String title;
  final Color initialColor;

  @override
  State<_ColorPickerDialog> createState() => _ColorPickerDialogState();
}

class _ColorPickerDialogState extends State<_ColorPickerDialog> {
  late Color _color;
  late final TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _color = widget.initialColor;
    _hexController = TextEditingController(
      text: _colorToHex(_color.toARGB32()),
    );
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 82,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _hexController,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[#a-fA-F0-9]')),
                LengthLimitingTextInputFormatter(9),
              ],
              decoration: InputDecoration(
                labelText: context.l10n.themeHexLabel,
                hintText: '#FF2563EB',
              ),
              onChanged: (value) {
                final parsed = AppThemeSettings.parseColorString(value);
                if (parsed != null) {
                  setState(() => _color = Color(parsed));
                }
              },
            ),
            const SizedBox(height: 12),
            _ColorSlider(
              label: context.l10n.themeRedChannel,
              value: (_color.r * 255).round(),
              activeColor: Colors.redAccent,
              onChanged: (value) => _setChannel(red: value),
            ),
            _ColorSlider(
              label: context.l10n.themeGreenChannel,
              value: (_color.g * 255).round(),
              activeColor: Colors.greenAccent,
              onChanged: (value) => _setChannel(green: value),
            ),
            _ColorSlider(
              label: context.l10n.themeBlueChannel,
              value: (_color.b * 255).round(),
              activeColor: Colors.lightBlueAccent,
              onChanged: (value) => _setChannel(blue: value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _color),
          child: Text(context.l10n.commonSelect),
        ),
      ],
    );
  }

  void _setChannel({int? red, int? green, int? blue}) {
    final next = Color.fromARGB(
      (_color.a * 255).round(),
      red ?? (_color.r * 255).round(),
      green ?? (_color.g * 255).round(),
      blue ?? (_color.b * 255).round(),
    );
    setState(() {
      _color = next;
      _hexController.text = _colorToHex(next.toARGB32());
    });
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color activeColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            divisions: 255,
            activeColor: activeColor,
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            value.toString(),
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

String _colorToHex(int value) {
  return '#${value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
}
