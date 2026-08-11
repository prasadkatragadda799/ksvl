/// Store-wide delivery rules the super admin controls.
///
/// Covers the delivery-fee "slab" (flat fee + free-delivery threshold) and the
/// scheduling window used to build customer delivery slots.
class DeliverySettings {
  const DeliverySettings({
    this.deliveryFee = 40,
    this.freeDeliveryThreshold = 499,
    this.slotLeadHours = 3,
    this.slotOpenHour = 10,
    this.slotCloseHour = 21,
    this.advanceDays = 3,
    this.slotDurationHours = 1,
  });

  /// Flat delivery fee charged below [freeDeliveryThreshold].
  final double deliveryFee;

  /// Subtotal at or above which delivery is free.
  final double freeDeliveryThreshold;

  /// Earliest a slot can begin, measured from "now" (e.g. 3 hours).
  final int slotLeadHours;

  /// First slot start hour of the day, 24h (e.g. 10 = 10 AM).
  final int slotOpenHour;

  /// Last slot end hour of the day, 24h (e.g. 21 = 9 PM).
  final int slotCloseHour;

  /// How many days ahead (including today) a customer may schedule.
  final int advanceDays;

  /// Length of each slot in hours.
  final int slotDurationHours;

  DeliverySettings copyWith({
    double? deliveryFee,
    double? freeDeliveryThreshold,
    int? slotLeadHours,
    int? slotOpenHour,
    int? slotCloseHour,
    int? advanceDays,
    int? slotDurationHours,
  }) {
    return DeliverySettings(
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDeliveryThreshold:
          freeDeliveryThreshold ?? this.freeDeliveryThreshold,
      slotLeadHours: slotLeadHours ?? this.slotLeadHours,
      slotOpenHour: slotOpenHour ?? this.slotOpenHour,
      slotCloseHour: slotCloseHour ?? this.slotCloseHour,
      advanceDays: advanceDays ?? this.advanceDays,
      slotDurationHours: slotDurationHours ?? this.slotDurationHours,
    );
  }

  Map<String, dynamic> toJson() => {
        'deliveryFee': deliveryFee,
        'freeDeliveryThreshold': freeDeliveryThreshold,
        'slotLeadHours': slotLeadHours,
        'slotOpenHour': slotOpenHour,
        'slotCloseHour': slotCloseHour,
        'advanceDays': advanceDays,
        'slotDurationHours': slotDurationHours,
      };

  factory DeliverySettings.fromJson(Map<String, dynamic> json) {
    return DeliverySettings(
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 40,
      freeDeliveryThreshold:
          (json['freeDeliveryThreshold'] as num?)?.toDouble() ?? 499,
      slotLeadHours: (json['slotLeadHours'] as num?)?.toInt() ?? 3,
      slotOpenHour: (json['slotOpenHour'] as num?)?.toInt() ?? 10,
      slotCloseHour: (json['slotCloseHour'] as num?)?.toInt() ?? 21,
      advanceDays: (json['advanceDays'] as num?)?.toInt() ?? 3,
      slotDurationHours: (json['slotDurationHours'] as num?)?.toInt() ?? 1,
    );
  }
}
