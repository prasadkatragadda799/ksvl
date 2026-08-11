import '../models/delivery_settings.dart';

/// A single bookable delivery window, e.g. "Today, 2:00 PM – 3:00 PM".
class DeliverySlot {
  const DeliverySlot({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  /// Calendar day the slot falls on (midnight).
  DateTime get day => DateTime(start.year, start.month, start.day);

  String get timeLabel => '${_fmt(start)} – ${_fmt(end)}';

  String dayLabel(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final diff = day.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    const week = [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ];
    return '${week[start.weekday - 1]} ${start.day}';
  }

  String fullLabel(DateTime now) => '${dayLabel(now)}, $timeLabel';

  static String _fmt(DateTime t) {
    final h24 = t.hour;
    final period = h24 >= 12 ? 'PM' : 'AM';
    var h = h24 % 12;
    if (h == 0) h = 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }
}

/// Builds all selectable delivery slots for [settings], honouring the lead
/// time (earliest start = now + leadHours), daily open/close window, and how
/// many days ahead the customer may book.
List<DeliverySlot> buildDeliverySlots(
  DeliverySettings settings, {
  DateTime? now,
}) {
  final current = now ?? DateTime.now();
  final earliest = current.add(Duration(hours: settings.slotLeadHours));
  final slots = <DeliverySlot>[];

  for (var dayOffset = 0; dayOffset < settings.advanceDays; dayOffset++) {
    final base = DateTime(
      current.year,
      current.month,
      current.day,
    ).add(Duration(days: dayOffset));

    for (var hour = settings.slotOpenHour;
        hour + settings.slotDurationHours <= settings.slotCloseHour;
        hour += settings.slotDurationHours) {
      final start = DateTime(base.year, base.month, base.day, hour);
      final end = start.add(Duration(hours: settings.slotDurationHours));
      // Drop windows that start before the lead-time cutoff.
      if (start.isBefore(earliest)) continue;
      slots.add(DeliverySlot(start: start, end: end));
    }
  }
  return slots;
}
