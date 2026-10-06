import 'package:flutter/material.dart';
import 'package:paginated_typeahead/paginated_typeahead.dart';

import 'options.dart';
import 'widgets/app_search_field.dart';

class SettingsTypeAhead extends StatelessWidget {
  const SettingsTypeAhead({
    super.key,
    required this.controller,
    required this.settings,
  });

  final TextEditingController controller;
  final FieldSettings settings;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: settings.direction.value == VerticalDirection.up
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: PaginatedTypeAhead<FieldOption>(
            initialPage: 0,
            hideOnUnfocus: false,
            hideOnSelect: false,
            controller: controller,
            builder: (context, ctrl, focus) => AppSearchField(
              controller: ctrl,
              focusNode: focus,
              hintText: 'Search settings...',
            ),
            itemBuilder: _buildSettingItem,
            separatorBuilder: settings.dividers.value
                ? (context, index) => const Divider(height: 1)
                : null,
            onSelected: _onSuggestionSelected,
            suggestionsCallback: (pattern, page) =>
                (settings.search(pattern), false),
            constrainWidth: settings.constrainWidth.value,
            direction: settings.direction.value,
          ),
        ),
      ],
    );
  }

  void _onSuggestionSelected(FieldOption setting) => setting.change();

  Widget _buildSettingItem(FieldOption setting) {
    if (setting is ToggleFieldOption) {
      final icon = setting.value
          ? setting.icon
          : (setting.iconFalse ?? setting.icon);
      return CheckboxListTile(
        key: ValueKey(setting.value),
        title: Text(setting.title),
        secondary: icon != null ? Icon(icon) : null,
        value: setting.value,
        onChanged: (_) => _onSuggestionSelected(setting),
      );
    }

    return ListTile(
      key: ValueKey(setting.value),
      leading: Icon(setting.icon),
      title: Text(setting.title),
      trailing: setting is ChoiceFieldOption
          ? Text(setting.value.toString())
          : null,
      onTap: () => _onSuggestionSelected(setting),
    );
  }
}
