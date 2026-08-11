import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// Date + time-window picker honouring the store's delivery scheduling rules
/// (lead time, daily open/close window and how many days ahead are bookable).
class DeliverySlotPicker extends StatefulWidget {
  const DeliverySlotPicker({
    super.key,
    required this.settings,
    required this.selected,
    required this.onSelected,
  });

  final DeliverySettings settings;
  final DeliverySlot? selected;
  final ValueChanged<DeliverySlot> onSelected;

  @override
  State<DeliverySlotPicker> createState() => _DeliverySlotPickerState();
}

class _DeliverySlotPickerState extends State<DeliverySlotPicker> {
  late final DateTime _now;
  late final List<DeliverySlot> _slots;
  late final List<DateTime> _days;
  late DateTime _activeDay;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _slots = buildDeliverySlots(widget.settings, now: _now);
    _days = <DateTime>[];
    for (final s in _slots) {
      if (!_days.any((d) => d == s.day)) _days.add(s.day);
    }
    _activeDay = widget.selected?.day ??
        (_days.isNotEmpty ? _days.first : DateTime(_now.year));
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    if (_slots.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(KsvlSpace.md),
        decoration: BoxDecoration(
          color: k.warningSoft,
          borderRadius: KsvlRadius.allSm,
        ),
        child: Text(
          'No delivery windows are open right now. Please try again later.',
          style: text.bodySmall?.copyWith(color: k.textPrimary),
        ),
      );
    }

    final daySlots =
        _slots.where((s) => s.day == _activeDay).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, _) => const SizedBox(width: KsvlSpace.sm),
            itemBuilder: (context, i) {
              final day = _days[i];
              final sample = _slots.firstWhere((s) => s.day == day);
              final selected = day == _activeDay;
              return _DayChip(
                title: sample.dayLabel(_now),
                subtitle: '${sample.start.day} '
                    '${_monthShort(sample.start.month)}',
                selected: selected,
                onTap: () => setState(() => _activeDay = day),
              );
            },
          ),
        ),
        const SizedBox(height: KsvlSpace.md),
        Wrap(
          spacing: KsvlSpace.sm,
          runSpacing: KsvlSpace.sm,
          children: [
            for (final slot in daySlots)
              _TimeChip(
                label: slot.timeLabel,
                selected: _isSame(slot, widget.selected),
                onTap: () => widget.onSelected(slot),
              ),
          ],
        ),
      ],
    );
  }

  bool _isSame(DeliverySlot a, DeliverySlot? b) =>
      b != null && a.start == b.start && a.end == b.end;

  static String _monthShort(int m) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][m - 1];
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KsvlRadius.allSm,
        child: AnimatedContainer(
          duration: KsvlMotion.fast,
          width: 84,
          padding: const EdgeInsets.symmetric(
            horizontal: KsvlSpace.sm,
            vertical: KsvlSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? k.brandSoft : Colors.transparent,
            borderRadius: KsvlRadius.allSm,
            border: Border.all(
              color: selected ? k.brand : k.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.titleSmall?.copyWith(
                  color: selected ? k.onBrandSoft : k.textPrimary,
                ),
              ),
              Text(subtitle, style: text.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: KsvlRadius.allPill,
        child: AnimatedContainer(
          duration: KsvlMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: KsvlSpace.md,
            vertical: KsvlSpace.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? k.brand : Colors.transparent,
            borderRadius: KsvlRadius.allPill,
            border: Border.all(
              color: selected ? k.brand : k.border,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: text.labelMedium?.copyWith(
              color: selected ? Colors.white : k.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
