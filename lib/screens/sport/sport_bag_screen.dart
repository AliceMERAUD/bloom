import 'package:flutter/material.dart';

import '../../models/sport_bag_item.dart';
import '../../services/sport_activity_service.dart';
import '../../services/sport_bag_service.dart';
import 'sport_bag_checklist_sheet.dart';

class SportBagScreen extends StatefulWidget {
  /// Optional initial sport filter (`null` = general / all).
  final String? initialSportId;

  const SportBagScreen({super.key, this.initialSportId});

  @override
  State<SportBagScreen> createState() => _SportBagScreenState();
}

class _SportBagScreenState extends State<SportBagScreen> {
  /// `null` = all items, `''` = general only, otherwise sport id.
  String? _filterSportId;
  List<SportBagItem> _items = [];

  @override
  void initState() {
    super.initState();
    _filterSportId = widget.initialSportId;
    _reload();
  }

  void _reload() {
    final all = SportBagService.getAll();
    setState(() {
      if (_filterSportId == null) {
        _items = all;
      } else if (_filterSportId!.isEmpty) {
        _items = all.where((i) => i.sportId == null).toList();
      } else {
        _items = all.where((i) => i.sportId == _filterSportId).toList();
      }
    });
  }

  Future<void> _addItem() async {
    final controller = TextEditingController();
    String? sportId =
        _filterSportId != null && _filterSportId!.isNotEmpty
            ? _filterSportId
            : null;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final sports = SportActivityService.getAll(enabledOnly: true);
            return AlertDialog(
              title: const Text('Ajouter un objet'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Nom',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: sportId,
                    decoration: const InputDecoration(
                      labelText: 'Sport (optionnel)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Général'),
                      ),
                      ...sports.map(
                        (s) => DropdownMenuItem<String?>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (v) => setDialogState(() => sportId = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Ajouter'),
                ),
              ],
            );
          },
        );
      },
    );

    final name = controller.text.trim();
    controller.dispose();
    if (ok != true || name.isEmpty) return;

    await SportBagService.add(name: name, sportId: sportId);
    if (mounted) _reload();
  }

  Future<void> _delete(SportBagItem item) async {
    await SportBagService.delete(item.id);
    if (mounted) _reload();
  }

  String _sportLabel(String? sportId) {
    if (sportId == null) return 'Général';
    return SportActivityService.getById(sportId)?.name ?? 'Sport';
  }

  @override
  Widget build(BuildContext context) {
    final sports = SportActivityService.getAll(enabledOnly: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sac de sport'),
        actions: [
          IconButton(
            tooltip: 'Checklist',
            icon: const Icon(Icons.checklist),
            onPressed: () async {
              await showSportBagChecklistSheet(
                context,
                sportId: _filterSportId != null && _filterSportId!.isNotEmpty
                    ? _filterSportId
                    : null,
              );
              if (mounted) _reload();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItem,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tous'),
                  selected: _filterSportId == null,
                  onSelected: (_) {
                    setState(() => _filterSportId = null);
                    _reload();
                  },
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Général'),
                  selected: _filterSportId == '',
                  onSelected: (_) {
                    setState(() => _filterSportId = '');
                    _reload();
                  },
                ),
                ...sports.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      avatar: Icon(s.icon, size: 16),
                      label: Text(s.name),
                      selected: _filterSportId == s.id,
                      onSelected: (_) {
                        setState(() => _filterSportId = s.id);
                        _reload();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? const Center(child: Text('Sac vide pour ce filtre.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: CheckboxListTile(
                          value: item.checked,
                          onChanged: (_) async {
                            await SportBagService.toggleChecked(item.id);
                            if (mounted) _reload();
                          },
                          title: Text(item.name),
                          subtitle: Text(_sportLabel(item.sportId)),
                          secondary: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _delete(item),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
