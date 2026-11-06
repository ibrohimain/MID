import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/safe_mutate.dart';
import '../../core/theme/mid_colors.dart';
import '../../data/mid_store.dart';
import '../../models/app_user.dart';
import '../../models/domain.dart';
import '../../models/user_role.dart';
import '../../widgets/page_scaffold.dart';
import '../../widgets/section_header.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({
    super.key,
    required this.user,
    required this.store,
  });

  final AppUser user;
  final MidStore store;

  @override
  Widget build(BuildContext context) {
    final canPublish = user.role.isLeadership;
    final list = canPublish
        ? store.announcements
        : store.announcementsFor(user);

    return PageScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "E'lonlar va yangiliklar",
            subtitle: canPublish
                ? 'Xodim, shogirt, o‘quvchi yoki barchaga e’lon qiling'
                : 'Sizga yo‘naltirilgan e’lonlar',
            action: canPublish
                ? FilledButton.icon(
                    onPressed: () => _edit(context),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text("E'lon berish"),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          if (list.isEmpty)
            const SurfaceBox(child: Text('Hozircha e’lon yo‘q'))
          else
            ...list.map((a) {
              final author = store.userById(a.authorId);
              return Padding(
                key: ValueKey(a.id),
                padding: const EdgeInsets.only(bottom: 10),
                child: SurfaceBox(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              a.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          TagChip(
                            text: a.audience.label,
                            color: MidColors.teal,
                          ),
                          if (canPublish) ...[
                            IconButton(
                              onPressed: () => _edit(context, existing: a),
                              icon: const Icon(Icons.edit_outlined, size: 20),
                            ),
                            IconButton(
                              onPressed: () => _delete(context, a),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: MidColors.coral,
                                size: 20,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(a.body),
                      const SizedBox(height: 8),
                      Text(
                        '${author?.fullName ?? ''} · ${shortDate(a.createdAt)}',
                        style: const TextStyle(color: MidColors.navyMuted),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, Announcement a) async {
    final ok = await confirmDelete(
      context,
      title: "E'lonni o'chirish",
      message: '«${a.title}» o‘chirilsinmi?',
    );
    if (!ok) return;
    await safeMutate(context, () => store.deleteAnnouncement(a.id));
  }

  Future<void> _edit(BuildContext context, {Announcement? existing}) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final body = TextEditingController(text: existing?.body ?? '');
    var audience = existing?.audience ?? AnnouncementAudience.barcha;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? "Yangi e'lon" : "E'lonni tahrirlash"),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Sarlavha'),
                ),
                TextField(
                  controller: body,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Matn'),
                ),
                DropdownButtonFormField<AnnouncementAudience>(
                  value: audience,
                  items: AnnouncementAudience.values
                      .map(
                        (a) => DropdownMenuItem(
                          value: a,
                          child: Text(a.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => audience = v ?? audience),
                  decoration: const InputDecoration(labelText: 'Kimga'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Bekor'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(existing == null ? 'E’lon qilish' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );

    if (ok == true && title.text.trim().isNotEmpty) {
      await safeMutate(context, () async {
        if (existing == null) {
          await store.addAnnouncement(
            title: title.text.trim(),
            body: body.text.trim(),
            authorId: user.id,
            audience: audience,
          );
        } else {
          await store.updateAnnouncement(
            id: existing.id,
            title: title.text.trim(),
            body: body.text.trim(),
            audience: audience,
          );
        }
      });
    }
  }
}
