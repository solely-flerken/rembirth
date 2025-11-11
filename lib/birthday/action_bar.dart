import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';

class ActionBar extends StatelessWidget {
  final Iterable<int> categoryIds;
  final bool isEntrySelected;
  final VoidCallback onAdd;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final void Function(Iterable<int>) onExpandAll;
  final void Function(Iterable<int>) onCollapseAll;
  final VoidCallback onOpenSettings;
  final VoidCallback onToggleCategoryView;

  const ActionBar({
    super.key,
    required this.categoryIds,
    required this.isEntrySelected,
    required this.onAdd,
    this.onEdit,
    this.onDelete,
    required this.onExpandAll,
    required this.onCollapseAll,
    required this.onOpenSettings,
    required this.onToggleCategoryView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settingsController = context.watch<SettingsController>();

    final isCategoryView = settingsController.settings.categoryViewEnabled;
    final isToolbarBottom = settingsController.settings.positionToolbarBottom;
    final bool canExpandCollapse = isCategoryView && categoryIds.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: SizedBox(
        height: 72.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const SizedBox(width: 8.0),
            _buildActionButton(context, icon: Icons.add, onPressed: onAdd),
            const SizedBox(width: 8.0),
            _buildActionButton(context, icon: Icons.edit, onPressed: isEntrySelected ? onEdit : null),
            const SizedBox(width: 8.0),
            _buildActionButton(context, icon: Icons.delete, onPressed: isEntrySelected ? onDelete : null),
            const Spacer(),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
              child: SizedBox(
                width: 56.0,
                height: 56.0,
                child: PopupMenuButton<VoidCallback>(
                  icon: Icon(Icons.more_horiz, size: 28.0, color: Theme.of(context).colorScheme.primary),
                  position: isToolbarBottom ? PopupMenuPosition.over : PopupMenuPosition.under,
                  offset: isToolbarBottom ? const Offset(0, -260) : const Offset(0, 12.0),
                  onSelected: (callback) => callback(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: onToggleCategoryView,
                      child: ListTile(
                        leading: Icon(
                          isCategoryView ? Icons.view_list : Icons.grid_view,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(isCategoryView ? l10n.list_show_as_list : l10n.list_show_as_categories),
                      ),
                    ),
                    PopupMenuItem(
                      value: () => onExpandAll(categoryIds),
                      enabled: canExpandCollapse,
                      child: ListTile(
                        leading: Icon(Icons.unfold_more, color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.list_expand_all),
                      ),
                    ),
                    PopupMenuItem(
                      value: () => onCollapseAll(categoryIds),
                      enabled: canExpandCollapse,
                      child: ListTile(
                        leading: Icon(Icons.unfold_less, color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.list_collapse_all),
                      ),
                    ),
                    const PopupMenuDivider(indent: 8, endIndent: 8, thickness: 2),
                    PopupMenuItem(
                      value: onOpenSettings,
                      child: ListTile(
                        leading: Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                        title: Text(l10n.list_settings),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 56.0,
      height: 56.0,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: EdgeInsets.zero),
        child: Icon(icon, size: 28.0),
      ),
    );
  }
}
