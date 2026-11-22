import 'package:material_ui/material_ui.dart';

import '../core/format.dart';
import '../core/routes.dart';
import '../core/theme.dart';
import '../models/memory_item.dart';
import '../models/person.dart';
import '../state/archive_controller.dart';
import '../widgets/app_shell.dart';
import '../widgets/common.dart';
import '../widgets/frame_tile.dart';

/// People (m11 / w11): face groups, named by you. Automatic
/// grouping arrives with the mobile app and will run on-device only.
/// The counts come from the groups themselves.
class PeopleScreen extends StatefulWidget {
  /// Creates the people screen.
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  String? _selectedId;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _colorFor(String key) {
    switch (key) {
      case 'gold':
        return Palette.v7.gold;
      case 'cyan':
        return Palette.v7.cyan;
      case 'pink':
        return Palette.v7.pink;
      case 'green':
        return Palette.v7.green;
      case 'blue':
        return Palette.v7.blue;
      case 'muted':
      default:
        return Palette.v7.muted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final archive = AppScope.of(context).archive;
    return ListenableBuilder(
      listenable: archive,
      builder: (context, _) {
        final people = archive.people;
        final namedTotal = people
            .where((p) => p.isNamed)
            .fold(0, (sum, p) => sum + p.photoCount);
        final selected =
            _selectedId == null ? null : archive.personById(_selectedId!);
        final List<MemoryItem> selectedItems = selected == null
            ? const <MemoryItem>[]
            : archive.items
                .where((item) => item.personIds.contains(selected.id))
                .toList(growable: false);

        final body = SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Face grouping, on-device', style: AppTheme.kicker()),
              const SizedBox(height: 6),
              Text(
                'People',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${Format.count(namedTotal)} photos have people in them. '
                'Face grouping arrives with the mobile app and will run '
                'on-device only — names are yours to add.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium!
                    .copyWith(color: Palette.v7.parchment),
              ),
              const SizedBox(height: 16),
              if (people.isEmpty)
                const EmptyState(
                  icon: Icons.people_outline,
                  title: 'No people yet',
                  body:
                      'Face groups appear here when the archive holds photos of people. Automatic grouping arrives with the mobile app.',
                ),
              for (final person in people)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassCard(
                    borderColor: _selectedId == person.id
                        ? Palette.v7.gold.withValues(alpha: 0.6)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedId =
                            _selectedId == person.id ? null : person.id;
                        _nameController.text =
                            person.isNamed ? person.name! : '';
                      });
                    },
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor:
                              _colorFor(person.colorKey).withValues(alpha: 0.2),
                          child: Text(
                            person.isNamed ? person.name![0] : '?',
                            style: TextStyle(
                              color: _colorFor(person.colorKey),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                person.displayName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${Format.count(person.photoCount)} photos',
                                style: AppTheme.mono(size: 11),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _selectedId == person.id
                              ? Icons.expand_less
                              : Icons.chevron_right,
                          color: Palette.v7.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              if (selected != null) ...<Widget>[
                const SizedBox(height: 8),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        selected.isNamed
                            ? 'Rename ${selected.displayName}'
                            : 'Name this group',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                hintText: 'Name',
                              ),
                              onSubmitted: (_) => _saveName(archive, selected),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => _saveName(archive, selected),
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'In the library · ${selectedItems.length} frames',
                        style: AppTheme.kicker(),
                      ),
                      const SizedBox(height: 8),
                      if (selectedItems.isEmpty)
                        const Text(
                          'No frames with this person in the library yet.',
                          style: TextStyle(color: V7Colors.muted),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemCount: selectedItems.length,
                          itemBuilder: (context, i) => FrameTile(
                            item: selectedItems[i],
                            onTap: () => Navigator.of(context).pushNamed(
                              Routes.media,
                              arguments: selectedItems[i].id,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
        return ResponsiveScaffold(
          title: 'People',
          tabIndex: 0,
          mobile: body,
          wide: body,
        );
      },
    );
  }

  void _saveName(ArchiveController archive, Person person) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }
    archive.renamePerson(person.id, name);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Named $name')),
    );
  }
}
