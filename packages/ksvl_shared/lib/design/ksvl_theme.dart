// CupertinoPageTransitionsBuilder lives in the Cupertino library; iOS users
// expect the interactive back-swipe it provides.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ksvl_palette.dart';
import 'ksvl_semantics.dart';
import 'ksvl_tokens.dart';
import 'ksvl_typography.dart';

/// The single source of truth for how KSVL surfaces look.
///
/// Both the admin app and the customer storefront build their [ThemeData] from
/// here, so a change to a radius or a brand step lands in both at once.
class KsvlTheme {
  KsvlTheme._();

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData of(Brightness brightness) => _build(brightness);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final k = isLight ? KsvlColors.light : KsvlColors.dark;

    final surface = isLight ? KsvlPalette.neutral0 : KsvlPalette.dark800;
    final surfaceContainer =
        isLight ? KsvlPalette.neutral50 : KsvlPalette.dark700;
    final onBrand = isLight ? Colors.white : KsvlPalette.neutral900;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: k.brand,
      onPrimary: onBrand,
      primaryContainer: k.brandSoft,
      onPrimaryContainer: k.onBrandSoft,
      secondary: k.success,
      onSecondary: isLight ? Colors.white : KsvlPalette.neutral900,
      secondaryContainer: k.successSoft,
      onSecondaryContainer: k.success,
      tertiary: k.info,
      onTertiary: Colors.white,
      tertiaryContainer: k.infoSoft,
      onTertiaryContainer: k.info,
      error: k.danger,
      onError: Colors.white,
      errorContainer: k.dangerSoft,
      onErrorContainer: k.danger,
      surface: surface,
      onSurface: k.textPrimary,
      surfaceContainerLowest: surface,
      surfaceContainerLow: k.surfaceSunken,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: k.surfaceSubtle,
      surfaceContainerHighest: k.surfaceSubtle,
      onSurfaceVariant: k.textSecondary,
      outline: k.borderStrong,
      outlineVariant: k.border,
      shadow: k.shadow,
      scrim: k.overlayScrim,
      inverseSurface: isLight ? KsvlPalette.neutral900 : KsvlPalette.neutral50,
      onInverseSurface: isLight ? Colors.white : KsvlPalette.neutral900,
      inversePrimary: isLight ? KsvlPalette.brand300 : KsvlPalette.brand500,
    );

    final textTheme = KsvlType.textTheme(
      primary: k.textPrimary,
      secondary: k.textSecondary,
      muted: k.textMuted,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: textTheme,
      extensions: [k],
      scaffoldBackgroundColor: k.surfaceSunken,
      canvasColor: surface,
      splashFactory: InkSparkle.splashFactory,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Web and desktop get a plain fade; a zoom transition on a storefront
      // reads as a stutter.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: k.textPrimary,
        surfaceTintColor: Colors.transparent,
        shadowColor: k.shadow.withValues(alpha: 0.12),
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleSpacing: KsvlSpace.lg,
        iconTheme: IconThemeData(color: k.textPrimary, size: 24),
        actionsIconTheme: IconThemeData(color: k.textSecondary, size: 24),
        titleTextStyle: textTheme.titleLarge,
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      ),

      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: k.shadow.withValues(alpha: 0.10),
        elevation: 0,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: KsvlRadius.allMd,
          side: BorderSide(color: k.border),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: k.brand,
          foregroundColor: onBrand,
          disabledBackgroundColor: k.surfaceSubtle,
          disabledForegroundColor: k.textDisabled,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: KsvlSpace.xl,
            vertical: KsvlSpace.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
          textStyle: textTheme.labelLarge,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return Colors.black.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return Colors.white.withValues(alpha: 0.10);
            }
            return null;
          }),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: k.brand,
          foregroundColor: onBrand,
          minimumSize: const Size(64, 50),
          shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: k.brand,
          backgroundColor: Colors.transparent,
          disabledForegroundColor: k.textDisabled,
          minimumSize: const Size(64, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: KsvlSpace.xl,
            vertical: KsvlSpace.md,
          ),
          side: BorderSide(color: k.brand.withValues(alpha: 0.55), width: 1.5),
          shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
          textStyle: textTheme.labelLarge,
        ).copyWith(
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: k.border, width: 1.5);
            }
            if (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed)) {
              return BorderSide(color: k.brand, width: 1.5);
            }
            return BorderSide(color: k.brand.withValues(alpha: 0.55), width: 1.5);
          }),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: k.brand,
          minimumSize: const Size(48, 44),
          padding: const EdgeInsets.symmetric(horizontal: KsvlSpace.md),
          shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allXs),
          textStyle: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: k.textSecondary,
          minimumSize: const Size(44, 44),
          shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allXs),
        ),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: k.brand,
        foregroundColor: onBrand,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 6,
        highlightElevation: 2,
        extendedTextStyle: textTheme.labelLarge?.copyWith(color: onBrand),
        shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allMd),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? KsvlPalette.neutral50 : KsvlPalette.dark700,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KsvlSpace.lg,
          vertical: KsvlSpace.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: KsvlRadius.allSm,
          borderSide: BorderSide(color: k.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: KsvlRadius.allSm,
          borderSide: BorderSide(color: k.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: KsvlRadius.allSm,
          borderSide: BorderSide(color: k.brand, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: KsvlRadius.allSm,
          borderSide: BorderSide(color: k.danger, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: KsvlRadius.allSm,
          borderSide: BorderSide(color: k.danger, width: 1.8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: KsvlRadius.allSm,
          borderSide: BorderSide(color: k.border.withValues(alpha: 0.6)),
        ),
        prefixIconColor: k.textMuted,
        suffixIconColor: k.textMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(color: k.textMuted),
        labelStyle: textTheme.bodyMedium?.copyWith(color: k.textSecondary),
        floatingLabelStyle: textTheme.labelMedium?.copyWith(color: k.brand),
        helperStyle: textTheme.bodySmall,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: k.danger,
          fontWeight: FontWeight.w600,
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: k.surfaceSubtle,
        selectedColor: k.brand,
        checkmarkColor: onBrand,
        disabledColor: k.surfaceSubtle,
        side: BorderSide(color: k.border),
        labelStyle: textTheme.labelMedium?.copyWith(color: k.textPrimary),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(color: onBrand),
        padding: const EdgeInsets.symmetric(
          horizontal: KsvlSpace.md,
          vertical: KsvlSpace.sm,
        ),
        shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allPill),
        showCheckmark: false,
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return k.textDisabled;
          if (states.contains(WidgetState.selected)) return Colors.white;
          return isLight ? Colors.white : KsvlPalette.neutral400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return k.surfaceSubtle;
          }
          if (states.contains(WidgetState.selected)) return k.success;
          return isLight ? KsvlPalette.neutral300 : KsvlPalette.dark500;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return k.success.withValues(alpha: 0.10);
          }
          return k.textMuted.withValues(alpha: 0.08);
        }),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return k.brand;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(onBrand),
        side: BorderSide(color: k.borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(6)),
        ),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return k.brand;
          return k.borderStrong;
        }),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: k.shadow.withValues(alpha: 0.16),
        indicatorColor: k.brandSoft,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: KsvlRadius.allPill,
        ),
        elevation: 3,
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontSize: 12,
            letterSpacing: 0.1,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? k.brand : k.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? k.brand : k.textMuted,
          );
        }),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: k.brand,
        unselectedLabelColor: k.textMuted,
        labelStyle: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelMedium,
        indicatorColor: k.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: k.border,
        overlayColor: WidgetStateProperty.all(
          k.brand.withValues(alpha: 0.06),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: k.border,
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        iconColor: k.textSecondary,
        textColor: k.textPrimary,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodySmall,
        shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surface,
        modalBarrierColor: k.overlayScrim,
        showDragHandle: false,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: KsvlRadius.topSheet,
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allLg),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isLight ? KsvlPalette.neutral900 : KsvlPalette.neutral50,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: isLight ? Colors.white : KsvlPalette.neutral900,
          fontWeight: FontWeight.w600,
        ),
        actionTextColor: isLight ? KsvlPalette.brand300 : KsvlPalette.brand600,
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.all(KsvlSpace.lg),
        elevation: 4,
        shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
      ),

      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isLight ? KsvlPalette.neutral900 : KsvlPalette.neutral50,
          borderRadius: KsvlRadius.allXs,
        ),
        textStyle: textTheme.bodySmall?.copyWith(
          color: isLight ? Colors.white : KsvlPalette.neutral900,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: KsvlSpace.sm,
          vertical: KsvlSpace.xs,
        ),
        waitDuration: const Duration(milliseconds: 500),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: k.brand,
        linearTrackColor: k.surfaceSubtle,
        circularTrackColor: k.surfaceSubtle,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          k.textMuted.withValues(alpha: 0.35),
        ),
        radius: const Radius.circular(KsvlRadius.pill),
        thickness: WidgetStateProperty.all(6),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 3,
        textStyle: textTheme.bodyMedium?.copyWith(color: k.textPrimary),
        shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surface),
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
          ),
        ),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all(textTheme.labelMedium),
          shape: WidgetStateProperty.all(
            const RoundedRectangleBorder(borderRadius: KsvlRadius.allSm),
          ),
        ),
      ),
    );
  }

  /// Status-bar / nav-bar styling applied before `runApp`.
  static SystemUiOverlayStyle overlayStyle(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isLight ? KsvlPalette.neutral0 : KsvlPalette.dark800,
      systemNavigationBarIconBrightness:
          isLight ? Brightness.dark : Brightness.light,
      systemNavigationBarDividerColor: Colors.transparent,
    );
  }
}
