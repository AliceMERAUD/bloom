import 'package:flutter/material.dart';

import '../../models/sport_bag_item.dart';
import '../../services/sport_activity_service.dart';
import '../../services/sport_bag_service.dart';

/// Bottom sheet / embeddable checklist for a sport bag.
class SportBagChecklistView extends StatefulWidget {
  final String? sportId;
  final bool showReset;

  const SportBagChecklistView({
    super.key,
    this.sportId,
    this.showReset = true,
  });

  @override
  State<SportBagChecklistView> createState() => _SportBagChecklistViewState();
}

class _SportBagChecklistViewState extends State<SportBagChecklistView> {
  List<SportBagItem> _items = [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _items = SportBagService.checklistFor(widget.sportId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sportName = widget.sportId == null
        ? null
        : SportActivityService.getById(widget.sportId!)?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  sportName == null
                      ? 'Checklist du sac'
                      : 'Sac — $sportName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (widget.showReset)
                TextButton(
                  onPressed: () async {
                    await SportBagService.resetChecked(sportId: widget.sportId);
                    if (mounted) _reload();
                  },
                  child: const Text('Réinitialiser'),
                ),
            ],
          ),
        ),
        if (_items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('Aucun objet dans le sac pour ce sport.'),
          )
        else
          ..._items.map(
            (item) => CheckboxListTile(
              value: item.checked,
              onChanged: (_) async {
                await SportBagService.toggleChecked(item.id);
                if (mounted) _reload();
              },
              title: Text(item.name),
              subtitle: Text(item.isGeneral ? 'Général' : 'Spécifique'),
            ),
          ),
      ],
    );
  }
}

Future<void> showSportBagChecklistSheet(
  BuildContext context, {
  String? sportId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: SportBagChecklistView(sportId: sportId),
            );
          },
        ),
      );
    },
  );
}
