import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// The four promises, closing the storefront.
///
/// It sits at the *end* of the grid rather than pinned above the nav bar: a
/// permanent band would cost a phone another 56px of shelf forever, and these
/// are reassurances for someone who has finished looking, not navigation.
class TrustStrip extends StatelessWidget {
  const TrustStrip({super.key});

  static const List<_Promise> _promises = <_Promise>[
    _Promise(Icons.eco_outlined, '100% Natural', 'Pure & healthy'),
    _Promise(Icons.local_shipping_outlined, 'Fast Delivery', 'Same-day local'),
    _Promise(Icons.verified_user_outlined, 'Secure Payment', 'UPI & cash'),
    _Promise(Icons.support_agent_rounded, 'Real Support', 'We pick up'),
  ];

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KsvlSpace.md,
        vertical: KsvlSpace.md,
      ),
      decoration: BoxDecoration(
        color: k.successSoft,
        borderRadius: KsvlRadius.allMd,
        border: Border.all(color: k.success.withValues(alpha: 0.18)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Four across needs ~86px each before the labels start truncating;
          // below that they pair up instead of shrinking to illegibility.
          final perRow = constraints.maxWidth >= 344 ? 4 : 2;
          return Column(
            children: [
              for (var start = 0; start < _promises.length; start += perRow)
                Padding(
                  padding: EdgeInsets.only(
                    top: start == 0 ? 0 : KsvlSpace.md,
                  ),
                  child: Row(
                    children: [
                      for (var i = start;
                          i < start + perRow && i < _promises.length;
                          i++)
                        Expanded(child: _PromiseTile(promise: _promises[i])),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

@immutable
class _Promise {
  const _Promise(this.icon, this.title, this.caption);

  final IconData icon;
  final String title;
  final String caption;
}

class _PromiseTile extends StatelessWidget {
  const _PromiseTile({required this.promise});

  final _Promise promise;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Semantics(
      label: '${promise.title}. ${promise.caption}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(promise.icon, size: 18, color: k.success),
          const SizedBox(height: 5),
          Text(
            promise.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: k.textPrimary,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            promise.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
              color: k.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
