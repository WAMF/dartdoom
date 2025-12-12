import 'package:doom_wad/doom_wad.dart';
import 'package:flutter/material.dart';
import 'package:wad_explorer/src/models/lump_category.dart';

class LumpTreeView extends StatefulWidget {
  const LumpTreeView({
    required this.wadManager,
    required this.onLumpSelected,
    super.key,
  });

  final WadManager wadManager;
  final void Function(int index, LumpInfo info, LumpCategory category)
      onLumpSelected;

  @override
  State<LumpTreeView> createState() => _LumpTreeViewState();
}

class _LumpTreeViewState extends State<LumpTreeView> {
  late List<CategorizedLump> _lumps;
  late Map<LumpCategory, List<CategorizedLump>> _grouped;
  late Map<LumpCategory, Map<String, List<CategorizedLump>>> _subGrouped;
  final Set<LumpCategory> _expandedCategories = {};
  final Set<String> _expandedGroups = {};
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _categorize();
  }

  @override
  void didUpdateWidget(LumpTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wadManager != widget.wadManager) {
      _categorize();
    }
  }

  void _categorize() {
    _lumps = LumpCategorizer.categorizeAll(widget.wadManager);
    _grouped = {};
    _subGrouped = {};

    for (final lump in _lumps) {
      _grouped.putIfAbsent(lump.category, () => []).add(lump);

      if (lump.groupName != null) {
        _subGrouped
            .putIfAbsent(lump.category, () => {})
            .putIfAbsent(lump.groupName!, () => [])
            .add(lump);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = LumpCategory.values
        .where((c) => _grouped[c]?.isNotEmpty ?? false)
        .toList();

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryTile(category);
      },
    );
  }

  Widget _buildCategoryTile(LumpCategory category) {
    final lumps = _grouped[category] ?? [];
    final isExpanded = _expandedCategories.contains(category);
    final hasSubGroups = _subGrouped[category]?.isNotEmpty ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(_CategoryDisplay.icon(category)),
          title: Text('${_CategoryDisplay.name(category)} (${lumps.length})'),
          trailing: Icon(
            isExpanded ? Icons.expand_less : Icons.expand_more,
          ),
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedCategories.remove(category);
              } else {
                _expandedCategories.add(category);
              }
            });
          },
        ),
        if (isExpanded)
          if (hasSubGroups)
            _buildGroupedLumps(category, lumps)
          else
            ...lumps.map((lump) => _buildLumpTile(lump, 48)),
      ],
    );
  }

  Widget _buildGroupedLumps(LumpCategory category, List<CategorizedLump> lumps) {
    final subGroups = _subGrouped[category]!;
    final groupNames = subGroups.keys.toList()..sort();
    final ungroupedLumps =
        lumps.where((l) => l.groupName == null).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...groupNames.map((groupName) {
          final groupKey = '${category.name}:$groupName';
          final isGroupExpanded = _expandedGroups.contains(groupKey);
          final groupLumps = subGroups[groupName]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(left: 48),
                leading: const Icon(Icons.folder, size: 20),
                title: Text(
                  '$groupName (${groupLumps.length})',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Icon(
                  isGroupExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                ),
                onTap: () {
                  setState(() {
                    if (isGroupExpanded) {
                      _expandedGroups.remove(groupKey);
                    } else {
                      _expandedGroups.add(groupKey);
                    }
                  });
                },
              ),
              if (isGroupExpanded)
                ...groupLumps.map((lump) => _buildLumpTile(lump, 72)),
            ],
          );
        }),
        ...ungroupedLumps.map((lump) => _buildLumpTile(lump, 48)),
      ],
    );
  }

  Widget _buildLumpTile(CategorizedLump lump, double leftPadding) {
    final isSelected = _selectedIndex == lump.index;
    final isMarker = lump.isMarker;

    return ListTile(
      dense: true,
      selected: isSelected,
      contentPadding: EdgeInsets.only(left: leftPadding),
      leading: isMarker
          ? Icon(
              Icons.bookmark_outline,
              size: 16,
              color: Theme.of(context).colorScheme.outline,
            )
          : null,
      title: Text(
        lump.info.name,
        style: TextStyle(
          fontFamily: 'monospace',
          color: isMarker
              ? Theme.of(context).colorScheme.outline
              : null,
          fontStyle: isMarker ? FontStyle.italic : null,
        ),
      ),
      subtitle: Text(
        isMarker ? 'marker' : '${lump.info.size} bytes',
        style: TextStyle(
          color: isMarker
              ? Theme.of(context).colorScheme.outline
              : null,
        ),
      ),
      onTap: () {
        setState(() {
          _selectedIndex = lump.index;
        });
        widget.onLumpSelected(
          lump.index,
          lump.info,
          lump.category,
        );
      },
    );
  }
}

abstract final class _CategoryDisplay {
  static IconData icon(LumpCategory category) {
    return switch (category) {
      LumpCategory.maps => Icons.map,
      LumpCategory.graphics => Icons.image,
      LumpCategory.sprites => Icons.pest_control,
      LumpCategory.flats => Icons.texture,
      LumpCategory.sounds => Icons.volume_up,
      LumpCategory.music => Icons.music_note,
      LumpCategory.palettes => Icons.palette,
      LumpCategory.colormaps => Icons.gradient,
      LumpCategory.textures => Icons.wallpaper,
      LumpCategory.markers => Icons.bookmark,
      LumpCategory.other => Icons.file_present,
    };
  }

  static String name(LumpCategory category) {
    return switch (category) {
      LumpCategory.maps => 'Maps',
      LumpCategory.graphics => 'Graphics',
      LumpCategory.sprites => 'Sprites',
      LumpCategory.flats => 'Flats',
      LumpCategory.sounds => 'Sounds',
      LumpCategory.music => 'Music',
      LumpCategory.palettes => 'Palettes',
      LumpCategory.colormaps => 'Colormaps',
      LumpCategory.textures => 'Textures',
      LumpCategory.markers => 'Markers',
      LumpCategory.other => 'Other',
    };
  }
}
