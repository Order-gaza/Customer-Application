import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Extension on BuildContext that provides theme-aware colors.
/// Use `context.cx.scaffold`, `context.cx.card`, etc. instead of
/// hardcoded AppColors.scaffoldDark / AppColors.cardDark.
extension ThemeColorsExtension on BuildContext {
  _Cx get cx => _Cx(Theme.of(this).brightness == Brightness.dark);
}

class _Cx {
  final bool _dark;
  const _Cx(this._dark);

  // ── Surfaces ──
  Color get scaffold => _dark ? AppColors.scaffoldDark : const Color(0xFFF8F8F8);
  Color get card => _dark ? AppColors.cardDark : Colors.white;
  Color get surface => _dark ? AppColors.darkSurface : const Color(0xFFF0F0F0);
  Color get appBar => _dark ? AppColors.charcoalBlack : Colors.white;
  Color get bottomNav => _dark ? AppColors.charcoalBlack : Colors.white;

  // ── Text ──
  Color get textPrimary => _dark ? Colors.white : const Color(0xFF1A1A2E);
  Color get textSecondary => _dark ? AppColors.textSecondary : const Color(0xFF6B7280);
  Color get textHint => _dark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF);

  // ── Dividers / Borders ──
  Color get divider => _dark ? AppColors.divider : const Color(0xFFE5E7EB);
  Color get border => _dark ? AppColors.divider.withValues(alpha: 0.3) : const Color(0xFFE5E7EB);

  // ── Shimmer ──
  Color get shimmerBase => _dark ? AppColors.shimmerBase : const Color(0xFFE0E0E0);
  Color get shimmerHighlight => _dark ? AppColors.shimmerHighlight : const Color(0xFFF5F5F5);

  // ── Search bar ──
  Color get searchBg => _dark ? AppColors.darkSurface : const Color(0xFFF0F0F0);

  // ── Shadows ──
  Color get shadow => _dark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.06);

  // ── Icon colors ──
  Color get iconDefault => _dark ? Colors.white : const Color(0xFF374151);
  Color get iconMuted => _dark ? Colors.white.withValues(alpha: 0.4) : const Color(0xFF9CA3AF);
}
