import 'package:flutter/material.dart';

import '../../models/wellbeing_entry.dart';
import '../../models/wellbeing_enums.dart';
import '../../services/wellbeing_service.dart';

class WellbeingEntryScreen extends StatefulWidget {
  final DateTime initialDate;
  final WellbeingEntry? existing;

  const WellbeingEntryScreen({
    super.key,
    required this.initialDate,
    this.existing,
  });

  @override
  State<WellbeingEntryScreen> createState() => _WellbeingEntryScreenState();
}

class _WellbeingEntryScreenState extends State<WellbeingEntryScreen> {
  late DateTime selectedDate;
  Mood? mood;
  Energy? energy;
  Pain pain = Pain.none;
  Bleeding bleeding = Bleeding.none;
  PeriodMarker periodMarker = PeriodMarker.none;
  late Set<Symptom> selectedSymptoms;
  late TextEditingController noteController;
  bool saving = false;
  String? originalDateKey;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing ??
        WellbeingService.getEntryForDate(widget.initialDate);

    selectedDate = WellbeingEntry.normalizeDate(
      existing?.date ?? widget.initialDate,
    );
    originalDateKey = existing == null ? null : WellbeingEntry.dateKey(existing.date);
    mood = existing?.mood;
    energy = existing?.energy;
    pain = existing?.pain ?? Pain.none;
    bleeding = existing?.bleeding ?? Bleeding.none;
    periodMarker = existing?.periodMarker ?? PeriodMarker.none;
    selectedSymptoms = {...?existing?.symptoms};
    noteController = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;

    final normalized = WellbeingEntry.normalizeDate(picked);
    final existing = WellbeingService.getEntryForDate(normalized);

    setState(() {
      selectedDate = normalized;
      if (existing != null) {
        mood = existing.mood;
        energy = existing.energy;
        pain = existing.pain;
        bleeding = existing.bleeding;
        periodMarker = existing.periodMarker;
        selectedSymptoms = {...existing.symptoms};
        noteController.text = existing.note ?? '';
      }
    });
  }

  Future<void> _save() async {
    if (saving) return;
    setState(() => saving = true);

    final note = noteController.text.trim();
    final entry = WellbeingEntry(
      id: WellbeingEntry.dateKey(selectedDate),
      date: selectedDate,
      mood: mood,
      energy: energy,
      pain: pain,
      bleeding: bleeding,
      symptoms: selectedSymptoms.toList(),
      note: note.isEmpty ? null : note,
      periodMarker: periodMarker,
    );

    await WellbeingService.saveEntry(entry);

    final previousKey = originalDateKey;
    if (previousKey != null && previousKey != entry.id) {
      await WellbeingService.deleteEntry(previousKey);
    }

    if (!mounted) return;
    Navigator.pop(context, entry);
  }

  Future<void> _delete() async {
    final id = WellbeingEntry.dateKey(selectedDate);
    final existing = WellbeingService.getEntryForDate(selectedDate);
    if (existing == null) {
      Navigator.pop(context);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Supprimer cette journée ?'),
          content: const Text('Cette action est définitive.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    await WellbeingService.deleteEntry(id);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasExisting = WellbeingService.getEntryForDate(selectedDate) != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasExisting ? 'Modifier la journée' : 'Ma journée'),
        actions: [
          if (hasExisting)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Supprimer',
              onPressed: _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(_formatDate(selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 12),
          _sectionTitle('Humeur'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Mood.values.map((value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: mood == value,
                onSelected: (_) {
                  setState(() => mood = value);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Énergie'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Energy.values.map((value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: energy == value,
                onSelected: (_) {
                  setState(() => energy = value);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Douleur'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Pain.values.map((value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: pain == value,
                onSelected: (_) {
                  setState(() => pain = value);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Saignement'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Bleeding.values.map((value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: bleeding == value,
                onSelected: (_) {
                  setState(() => bleeding = value);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Cycle'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: PeriodMarker.values.map((value) {
              return ChoiceChip(
                label: Text(value.label),
                selected: periodMarker == value,
                onSelected: (_) {
                  setState(() => periodMarker = value);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Symptômes'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: Symptom.values.map((value) {
              final selected = selectedSymptoms.contains(value);
              return FilterChip(
                label: Text(value.label),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      selectedSymptoms.add(value);
                    } else {
                      selectedSymptoms.remove(value);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Note'),
          TextField(
            controller: noteController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Quelques mots pour toi…',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: saving ? null : _save,
              icon: const Icon(Icons.save),
              label: Text(
                saving ? 'Enregistrement…' : 'Enregistrer',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/'
        '${value.year}';
  }
}
