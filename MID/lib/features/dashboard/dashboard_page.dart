import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.user, required this.store});

  final AppUser user;
  final MidStore store;

  @override
  Widget build(BuildContext context) {
    return PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Salom, ${user.fullName.split(' ').first}',
            subtitle: user.role == UserRole.rahbar
                ? '${user.role.label} · ${user.sector?.label ?? ''}'
                : '${user.role.label}${user.position != null ? ' · ${user.position}' : ''}',
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, c) {
              final cols = c.maxWidth > 1000
                  ? 3
                  : c.maxWidth > 640
                      ? 2
                      : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.55,
                children: [
                  StatTile(
                    label: 'Jami xodimlar',
                    value: '${store.staffOnly.length}',
                    icon: Icons.groups_outlined,
                  ),
                  StatTile(
                    label: 'Faol loyihalar',
                    value: '${store.activeProjects.length}',
                    icon: Icons.rocket_launch_outlined,
                    accent: MidColors.coral,
                  ),
                  StatTile(
                    label: 'Kampaniya puli',
                    value: '${money(store.companyCash ~/ 1000000)} mln',
                    icon: Icons.account_balance_wallet_outlined,
                    accent: MidColors.success,
                  ),
                  StatTile(
                    label: 'Ish yuklatilgan',
                    value: '${store.loadedEmployees.length}',
                    icon: Icons.assignment_turned_in_outlined,
                    accent: MidColors.teal,
                  ),
                  StatTile(
                    label: 'Ish yuklatilmagan',
                    value: '${store.unloadedEmployees.length}',
                    icon: Icons.assignment_late_outlined,
                    accent: MidColors.warning,
                  ),
                  StatTile(
                    label: 'Zaxira',
                    value: '${money(store.reserveCash ~/ 1000000)} mln',
                    icon: Icons.savings_outlined,
                    accent: MidColors.navyMuted,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          const SectionHeader(
            title: 'Ish holati',
            subtitle: 'Javob berilgan va hali javobsiz xodimlar',
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              final dual = c.maxWidth > 800;
              final left = _PeopleBlock(
                title: 'Ishda bor (javob berilgan)',
                color: MidColors.success,
                people: store.respondedEmployees,
              );
              final right = _PeopleBlock(
                title: 'Ishda yo‘q (javobsiz)',
                color: MidColors.coral,
                people: store.noResponseEmployees,
              );
              if (!dual) {
                return Column(children: [left, const SizedBox(height: 12), right]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 12),
                  Expanded(child: right),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          SurfaceBox(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ish yuklatilmagan xodimlar',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (store.unloadedEmployees.isEmpty)
                  const Text("Hozircha barcha xodimlarga ish biriktirilgan.")
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: store.unloadedEmployees
                        .map(
                          (e) => TagChip(
                            text: '${e.fullName} · ${e.position ?? ''}',
                            color: MidColors.warning,
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeopleBlock extends StatelessWidget {
  const _PeopleBlock({
    required this.title,
    required this.color,
    required this.people,
  });

  final String title;
  final Color color;
  final List<AppUser> people;

  @override
  Widget build(BuildContext context) {
    return SurfaceBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text('${people.length}'),
            ],
          ),
          const SizedBox(height: 10),
          if (people.isEmpty)
            Text(
              "Ro'yxat bo'sh",
              style: TextStyle(color: MidColors.navyMuted),
            )
          else
            ...people.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${p.fullName} — ${p.position ?? p.role.label}'),
              ),
            ),
        ],
      ),
    );
  }
}
