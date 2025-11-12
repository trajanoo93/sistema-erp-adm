// lib/design_system.dart
// ========================================
// DESIGN SYSTEM - ERP DELIVERY
// Sistema de componentes reutilizáveis
// Baseado na identidade visual do sidebar
// ========================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ========================================
// 1. PALETA DE CORES
// ========================================
class AppColors {
  // Cor primária (laranja GO)
  static const Color primary = Color(0xFFF28C38);
  static const Color primaryLight = Color(0xFFFFB366);
  static const Color primaryDark = Color(0xFFE67A25);
  
  // Tons de laranja para backgrounds e estados
  static Color primaryOpacity5 = primary.withOpacity(0.05);
  static Color primaryOpacity8 = primary.withOpacity(0.08);
  static Color primaryOpacity12 = primary.withOpacity(0.12);
  static Color primaryOpacity15 = primary.withOpacity(0.15);
  static Color primaryOpacity25 = primary.withOpacity(0.25);
  static Color primaryOpacity35 = primary.withOpacity(0.35);
  
  // Cores de status (consistentes com o sistema)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);
  
  // Backgrounds
  static const Color bgPrimary = Color(0xFFF8F9FA);
  static const Color bgSecondary = Color(0xFFFFFFFF);
  static const Color bgCard = Color(0xFFFFFFFF);
  
  // Textos
  static const Color textPrimary = Color(0xFF000000);
  static Color textSecondary = Colors.grey[600]!;
  static Color textTertiary = Colors.grey[500]!;
  static const Color textOnPrimary = Colors.white;
  
  // Borders e divisores
  static Color borderLight = Colors.black.withOpacity(0.06);
  static Color borderMedium = Colors.black.withOpacity(0.12);
  static Color divider = Colors.black.withOpacity(0.08);
  
  // Sombras
  static Color shadow = Colors.black.withOpacity(0.06);
  static Color shadowMedium = Colors.black.withOpacity(0.10);
  
  // Gradientes
  static LinearGradient sidebarGradient = LinearGradient(
    colors: [Colors.white, Colors.orange.shade50.withOpacity(0.55)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient cardGradient = LinearGradient(
    colors: [Colors.white, Colors.orange.shade50.withOpacity(0.15)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient dividerGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black.withOpacity(0.08), Colors.transparent],
  );
}

// ========================================
// 2. TIPOGRAFIA
// ========================================
class AppTypography {
  // Títulos de páginas
  static TextStyle pageTitle = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  
  static TextStyle sectionTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle cardTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Subtítulos
  static TextStyle subtitle1 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static TextStyle subtitle2 = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  // Body text
  static TextStyle bodyLarge = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodySmall = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  
  // Labels e botões
  static TextStyle buttonLarge = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle buttonMedium = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle buttonSmall = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle labelSmall = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  // Caption
  static TextStyle caption = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}

// ========================================
// 3. ESPAÇAMENTOS
// ========================================
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
}

// ========================================
// 4. BORDER RADIUS
// ========================================
class AppRadius {
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double full = 999.0;
}

// ========================================
// 5. COMPONENTES - BUTTONS
// ========================================
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.isLoading = false,
    this.fullWidth = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();
    final padding = _getPadding();
    final textStyle = _getTextStyle();
    final iconSize = _getIconSize();

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: Material(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: colors['border'] != null
                  ? Border.all(color: colors['border']!, width: 1.2)
                  : null,
            ),
            child: Row(
              mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(colors['text']),
                    ),
                  )
                else if (icon != null) ...[
                  Icon(icon, size: iconSize, color: colors['text']),
                  const SizedBox(width: 8),
                ],
                Text(label, style: textStyle.copyWith(color: colors['text'])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, Color?> _getColors() {
    switch (variant) {
      case AppButtonVariant.primary:
        return {
          'bg': AppColors.primary,
          'text': Colors.white,
          'border': null,
        };
      case AppButtonVariant.secondary:
        return {
          'bg': AppColors.primaryOpacity12,
          'text': AppColors.primary,
          'border': AppColors.primaryOpacity35,
        };
      case AppButtonVariant.outline:
        return {
          'bg': Colors.transparent,
          'text': AppColors.primary,
          'border': AppColors.primary,
        };
      case AppButtonVariant.ghost:
        return {
          'bg': Colors.transparent,
          'text': AppColors.textPrimary,
          'border': null,
        };
      case AppButtonVariant.danger:
        return {
          'bg': AppColors.error,
          'text': Colors.white,
          'border': null,
        };
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    }
  }

  TextStyle _getTextStyle() {
    switch (size) {
      case AppButtonSize.small:
        return AppTypography.buttonSmall;
      case AppButtonSize.medium:
        return AppTypography.buttonMedium;
      case AppButtonSize.large:
        return AppTypography.buttonLarge;
    }
  }

  double _getIconSize() {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }
}

enum AppButtonVariant { primary, secondary, outline, ghost, danger }
enum AppButtonSize { small, medium, large }

// ========================================
// 6. COMPONENTES - CARDS
// ========================================
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool hasGradient;
  final bool hasShadow;
  final VoidCallback? onTap;

  const AppCard({
    Key? key,
    required this.child,
    this.padding,
    this.hasGradient = false,
    this.hasShadow = true,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: hasGradient ? AppColors.cardGradient : null,
            color: hasGradient ? null : AppColors.bgCard,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: hasShadow
                ? [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}

// Card com título
class AppCardWithTitle extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  final EdgeInsets? padding;

  const AppCardWithTitle({
    Key? key,
    required this.title,
    required this.child,
    this.action,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.cardTitle),
              if (action != null) action!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ========================================
// 7. COMPONENTES - INPUT FIELDS
// ========================================
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final int? maxLines;

  const AppTextField({
    Key? key,
    required this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          maxLines: maxLines,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 20, color: AppColors.primary)
                : null,
            suffixIcon: suffixIcon != null
                ? IconButton(
                    icon: Icon(suffixIcon, size: 20, color: AppColors.textSecondary),
                    onPressed: onSuffixTap,
                  )
                : null,
            filled: true,
            fillColor: Colors.grey.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
      ],
    );
  }
}

// ========================================
// 8. COMPONENTES - BADGES & CHIPS
// ========================================
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  const AppBadge({
    Key? key,
    required this.label,
    this.variant = AppBadgeVariant.primary,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colors = _getColors();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors['bg'],
        borderRadius: BorderRadius.circular(AppRadius.xs),
        border: Border.all(color: colors['border']!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors['text']),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: colors['text'],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getColors() {
    switch (variant) {
      case AppBadgeVariant.primary:
        return {
          'bg': AppColors.primaryOpacity12,
          'text': AppColors.primary,
          'border': AppColors.primaryOpacity35,
        };
      case AppBadgeVariant.success:
        return {
          'bg': AppColors.success.withOpacity(0.12),
          'text': AppColors.success,
          'border': AppColors.success.withOpacity(0.35),
        };
      case AppBadgeVariant.error:
        return {
          'bg': AppColors.error.withOpacity(0.12),
          'text': AppColors.error,
          'border': AppColors.error.withOpacity(0.35),
        };
      case AppBadgeVariant.warning:
        return {
          'bg': AppColors.warning.withOpacity(0.12),
          'text': AppColors.warning,
          'border': AppColors.warning.withOpacity(0.35),
        };
      case AppBadgeVariant.neutral:
        return {
          'bg': Colors.grey.withOpacity(0.12),
          'text': Colors.grey[700]!,
          'border': Colors.grey.withOpacity(0.35),
        };
    }
  }
}

enum AppBadgeVariant { primary, success, error, warning, neutral }

// ========================================
// 9. COMPONENTES - STAT CARD
// ========================================
class AppStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final String? subtitle;
  final VoidCallback? onTap;

  const AppStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.subtitle,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      hasGradient: true,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor ?? AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelSmall),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.cardTitle),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTypography.caption),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// 10. COMPONENTES - ICON BUTTON
// ========================================
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final double size;
  final String? tooltip;

  const AppIconButton({
    Key? key,
    required this.icon,
    this.onPressed,
    this.color,
    this.size = 20,
    this.tooltip,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final button = Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: (color ?? AppColors.primary).withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: (color ?? AppColors.primary).withOpacity(0.35),
        ),
      ),
      child: Icon(
        icon,
        size: size,
        color: color ?? AppColors.primary,
      ),
    );

    return tooltip != null
        ? Tooltip(message: tooltip!, child: InkWell(onTap: onPressed, child: button))
        : InkWell(onTap: onPressed, child: button);
  }
}

// ========================================
// 11. COMPONENTES - DIVIDER
// ========================================
class AppDivider extends StatelessWidget {
  final bool hasGradient;

  const AppDivider({Key? key, this.hasGradient = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: hasGradient
          ? BoxDecoration(gradient: AppColors.dividerGradient)
          : BoxDecoration(color: AppColors.divider),
    );
  }
}

// ========================================
// 12. COMPONENTES - EMPTY STATE
// ========================================
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    Key? key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryOpacity8,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: actionLabel!,
                onPressed: onAction,
                variant: AppButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ========================================
// 13. COMPONENTES - LOADING
// ========================================
class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLoadingIndicator({
    Key? key,
    this.size = 40,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(color ?? AppColors.primary),
        ),
      ),
    );
  }
}

// ========================================
// 14. COMPONENTES - PAGE HEADER
// ========================================
class AppPageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final List<Widget>? breadcrumbs;

  const AppPageHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.action,
    this.breadcrumbs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (breadcrumbs != null) ...[
          Row(
            children: breadcrumbs!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.pageTitle),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle!, style: AppTypography.subtitle1),
                  ],
                ],
              ),
            ),
            if (action != null) action!,
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppDivider(),
      ],
    );
  }
}

// ========================================
// 15. COMPONENTES - DROPDOWN MENU
// ========================================
class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? hint;

  const AppDropdown({
    Key? key,
    required this.label,
    this.value,
    required this.items,
    this.onChanged,
    this.hint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              isExpanded: true,
              hint: hint != null
                  ? Text(hint!, style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textTertiary,
                    ))
                  : null,
              style: AppTypography.bodyMedium,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}

// ========================================
// 16. HELPERS - SNACKBAR
// ========================================
class AppSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackbarType type = AppSnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final colors = _getColors(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(colors['icon'], color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: colors['bg'],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        duration: duration,
      ),
    );
  }

  static Map<String, dynamic> _getColors(AppSnackbarType type) {
    switch (type) {
      case AppSnackbarType.success:
        return {'bg': AppColors.success, 'icon': Icons.check_circle};
      case AppSnackbarType.error:
        return {'bg': AppColors.error, 'icon': Icons.error};
      case AppSnackbarType.warning:
        return {'bg': AppColors.warning, 'icon': Icons.warning};
      case AppSnackbarType.info:
        return {'bg': AppColors.info, 'icon': Icons.info};
    }
  }
}

enum AppSnackbarType { success, error, warning, info }

// ========================================
// 17. EXEMPLO DE USO
// ========================================
/*
EXEMPLOS DE USO DOS COMPONENTES:

// 1. BOTÃO PRIMÁRIO
AppButton(
  label: 'Salvar Pedido',
  icon: Icons.save,
  onPressed: () {},
)

// 2. CARD COM TÍTULO
AppCardWithTitle(
  title: 'Detalhes do Pedido',
  child: Text('Conteúdo aqui'),
)

// 3. INPUT FIELD
AppTextField(
  label: 'Nome do Cliente',
  hint: 'Digite o nome',
  prefixIcon: Icons.person,
)

// 4. STAT CARD
AppStatCard(
  title: 'Total de Pedidos',
  value: '142',
  icon: Icons.shopping_cart,
  subtitle: '+12% este mês',
)

// 5. BADGE
AppBadge(
  label: 'Pago',
  variant: AppBadgeVariant.success,
  icon: Icons.check,
)

// 6. PAGE HEADER
AppPageHeader(
  title: 'Gerenciar Pedidos',
  subtitle: 'Visualize e gerencie todos os pedidos',
  action: AppButton(label: 'Novo Pedido', onPressed: () {}),
)

// 7. EMPTY STATE
AppEmptyState(
  icon: Icons.inbox,
  title: 'Nenhum pedido encontrado',
  message: 'Ainda não há pedidos registrados',
  actionLabel: 'Criar Primeiro Pedido',
  onAction: () {},
)

// 8. SNACKBAR
AppSnackbar.show(
  context,
  message: 'Pedido criado com sucesso!',
  type: AppSnackbarType.success,
)

// 9. DROPDOWN
AppDropdown<String>(
  label: 'Status',
  value: 'pendente',
  items: [
    DropdownMenuItem(value: 'pendente', child: Text('Pendente')),
    DropdownMenuItem(value: 'pago', child: Text('Pago')),
  ],
  onChanged: (val) {},
)

*/