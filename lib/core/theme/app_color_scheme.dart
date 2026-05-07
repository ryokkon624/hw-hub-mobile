import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  final Color surface;
  final Color surfaceCard;
  final Color surfaceSubtle;
  final Color surfaceLogin;

  final Color border;
  final Color borderSubtle;

  final Color textHeading;
  final Color textBody;
  final Color textMuted;
  final Color textBrand;
  final Color textNavInactive;
  final Color textNavInactiveMobile;

  final Color primary;
  final Color primaryHover;
  final Color primary50;
  final Color primaryText;
  final Color primaryBorder;
  final Color primaryRing;
  final Color onPrimary;

  final Color accentSoft;
  final Color accentBorder;
  final Color accentBadgeBg;
  final Color accentBadgeText;

  final Color sidebar;
  final Color sidebarLogo;
  final Color sidebarActive;
  final Color sidebarActiveBg;
  final Color sidebarHoverBg;
  final Color sidebarNav;
  final Color sidebarBorder;

  final Color danger;
  final Color dangerSoft;
  final Color dangerBorder;
  final Color dangerBtn;
  final Color dangerBtnHover;

  final Color info;
  final Color infoSoft;

  final Color warning;

  final Color swipeAction;
  final Color swipeDelete;
  final Color swipeBack;
  final Color swipeDisabled;
  final Color swipeSelf;
  final Color swipeMembers;

  final Color storeSuper;
  final Color storeSuperSoft;
  final Color storeSuperBorder;
  final Color storeSuperText;

  final Color storeOnline;
  final Color storeOnlineSoft;
  final Color storeOnlineBorder;
  final Color storeOnlineText;

  final Color storeDrug;
  final Color storeDrugSoft;
  final Color storeDrugBorder;
  final Color storeDrugText;

  final Color onboardingFrom;
  final Color onboardingTo;

  final Color statusActiveBg;
  final Color statusActiveText;
  final Color statusActiveBorder;

  final Color statusPendingBg;
  final Color statusPendingText;
  final Color statusPendingBorder;

  final Color paletteEmeraldSoft;
  final Color paletteEmeraldBorder;
  final Color paletteEmeraldText;

  final Color paletteBlueSoft;
  final Color paletteBlueBorder;
  final Color paletteBlueText;

  final Color paletteAmberSoft;
  final Color paletteAmberBorder;
  final Color paletteAmberText;

  final Color paletteVioletSoft;
  final Color paletteVioletBorder;
  final Color paletteVioletText;

  final Color paletteRoseSoft;
  final Color paletteRoseBorder;
  final Color paletteRoseText;

  const AppColorScheme({
    required this.surface,
    required this.surfaceCard,
    required this.surfaceSubtle,
    required this.surfaceLogin,
    required this.border,
    required this.borderSubtle,
    required this.textHeading,
    required this.textBody,
    required this.textMuted,
    required this.textBrand,
    required this.textNavInactive,
    required this.textNavInactiveMobile,
    required this.primary,
    required this.primaryHover,
    required this.primary50,
    required this.primaryText,
    required this.primaryBorder,
    required this.primaryRing,
    required this.onPrimary,
    required this.accentSoft,
    required this.accentBorder,
    required this.accentBadgeBg,
    required this.accentBadgeText,
    required this.sidebar,
    required this.sidebarLogo,
    required this.sidebarActive,
    required this.sidebarActiveBg,
    required this.sidebarHoverBg,
    required this.sidebarNav,
    required this.sidebarBorder,
    required this.danger,
    required this.dangerSoft,
    required this.dangerBorder,
    required this.dangerBtn,
    required this.dangerBtnHover,
    required this.info,
    required this.infoSoft,
    required this.warning,
    required this.swipeAction,
    required this.swipeDelete,
    required this.swipeBack,
    required this.swipeDisabled,
    required this.swipeSelf,
    required this.swipeMembers,
    required this.storeSuper,
    required this.storeSuperSoft,
    required this.storeSuperBorder,
    required this.storeSuperText,
    required this.storeOnline,
    required this.storeOnlineSoft,
    required this.storeOnlineBorder,
    required this.storeOnlineText,
    required this.storeDrug,
    required this.storeDrugSoft,
    required this.storeDrugBorder,
    required this.storeDrugText,
    required this.onboardingFrom,
    required this.onboardingTo,
    required this.statusActiveBg,
    required this.statusActiveText,
    required this.statusActiveBorder,
    required this.statusPendingBg,
    required this.statusPendingText,
    required this.statusPendingBorder,
    required this.paletteEmeraldSoft,
    required this.paletteEmeraldBorder,
    required this.paletteEmeraldText,
    required this.paletteBlueSoft,
    required this.paletteBlueBorder,
    required this.paletteBlueText,
    required this.paletteAmberSoft,
    required this.paletteAmberBorder,
    required this.paletteAmberText,
    required this.paletteVioletSoft,
    required this.paletteVioletBorder,
    required this.paletteVioletText,
    required this.paletteRoseSoft,
    required this.paletteRoseBorder,
    required this.paletteRoseText,
  });

  factory AppColorScheme.light() => AppColorScheme(
        surface: AppColors.surfaceLight,
        surfaceCard: AppColors.surfaceCardLight,
        surfaceSubtle: AppColors.surfaceSubtleLight,
        surfaceLogin: AppColors.surfaceLoginLight,
        border: AppColors.borderLight,
        borderSubtle: AppColors.borderSubtleLight,
        textHeading: AppColors.textHeadingLight,
        textBody: AppColors.textBodyLight,
        textMuted: AppColors.textMutedLight,
        textBrand: AppColors.textBrandLight,
        textNavInactive: AppColors.textNavInactiveLight,
        textNavInactiveMobile: AppColors.textNavInactiveMobileLight,
        primary: AppColors.primaryLight,
        primaryHover: AppColors.primaryHoverLight,
        primary50: AppColors.primary50Light,
        primaryText: AppColors.primaryTextLight,
        primaryBorder: AppColors.primaryBorderLight,
        primaryRing: AppColors.primaryRingLight,
        onPrimary: AppColors.onPrimaryLight,
        accentSoft: AppColors.accentSoftLight,
        accentBorder: AppColors.accentBorderLight,
        accentBadgeBg: AppColors.accentBadgeBgLight,
        accentBadgeText: AppColors.accentBadgeTextLight,
        sidebar: AppColors.sidebarLight,
        sidebarLogo: AppColors.sidebarLogoLight,
        sidebarActive: AppColors.sidebarActiveLight,
        sidebarActiveBg: AppColors.sidebarActiveBgLight,
        sidebarHoverBg: AppColors.sidebarHoverBgLight,
        sidebarNav: AppColors.sidebarNavLight,
        sidebarBorder: AppColors.sidebarBorderLight,
        danger: AppColors.dangerLight,
        dangerSoft: AppColors.dangerSoftLight,
        dangerBorder: AppColors.dangerBorderLight,
        dangerBtn: AppColors.dangerBtnLight,
        dangerBtnHover: AppColors.dangerBtnHoverLight,
        info: AppColors.infoLight,
        infoSoft: AppColors.infoSoftLight,
        warning: AppColors.warningLight,
        swipeAction: AppColors.swipeActionLight,
        swipeDelete: AppColors.swipeDeleteLight,
        swipeBack: AppColors.swipeBackLight,
        swipeDisabled: AppColors.swipeDisabledLight,
        swipeSelf: AppColors.swipeSelfLight,
        swipeMembers: AppColors.swipeMembersLight,
        storeSuper: AppColors.storeSuperLight,
        storeSuperSoft: AppColors.storeSuperSoftLight,
        storeSuperBorder: AppColors.storeSuperBorderLight,
        storeSuperText: AppColors.storeSuperTextLight,
        storeOnline: AppColors.storeOnlineLight,
        storeOnlineSoft: AppColors.storeOnlineSoftLight,
        storeOnlineBorder: AppColors.storeOnlineBorderLight,
        storeOnlineText: AppColors.storeOnlineTextLight,
        storeDrug: AppColors.storeDrugLight,
        storeDrugSoft: AppColors.storeDrugSoftLight,
        storeDrugBorder: AppColors.storeDrugBorderLight,
        storeDrugText: AppColors.storeDrugTextLight,
        onboardingFrom: AppColors.onboardingFromLight,
        onboardingTo: AppColors.onboardingToLight,
        statusActiveBg: AppColors.statusActiveBgLight,
        statusActiveText: AppColors.statusActiveTextLight,
        statusActiveBorder: AppColors.statusActiveBorderLight,
        statusPendingBg: AppColors.statusPendingBgLight,
        statusPendingText: AppColors.statusPendingTextLight,
        statusPendingBorder: AppColors.statusPendingBorderLight,
        paletteEmeraldSoft: AppColors.paletteEmeraldSoftLight,
        paletteEmeraldBorder: AppColors.paletteEmeraldBorderLight,
        paletteEmeraldText: AppColors.paletteEmeraldTextLight,
        paletteBlueSoft: AppColors.paletteBlueSoftLight,
        paletteBlueBorder: AppColors.paletteBlueBorderLight,
        paletteBlueText: AppColors.paletteBlueTextLight,
        paletteAmberSoft: AppColors.paletteAmberSoftLight,
        paletteAmberBorder: AppColors.paletteAmberBorderLight,
        paletteAmberText: AppColors.paletteAmberTextLight,
        paletteVioletSoft: AppColors.paletteVioletSoftLight,
        paletteVioletBorder: AppColors.paletteVioletBorderLight,
        paletteVioletText: AppColors.paletteVioletTextLight,
        paletteRoseSoft: AppColors.paletteRoseSoftLight,
        paletteRoseBorder: AppColors.paletteRoseBorderLight,
        paletteRoseText: AppColors.paletteRoseTextLight,
      );

  factory AppColorScheme.dark() => AppColorScheme(
        surface: AppColors.surfaceDark,
        surfaceCard: AppColors.surfaceCardDark,
        surfaceSubtle: AppColors.surfaceSubtleDark,
        surfaceLogin: AppColors.surfaceLoginDark,
        border: AppColors.borderDark,
        borderSubtle: AppColors.borderSubtleDark,
        textHeading: AppColors.textHeadingDark,
        textBody: AppColors.textBodyDark,
        textMuted: AppColors.textMutedDark,
        textBrand: AppColors.textBrandDark,
        textNavInactive: AppColors.textNavInactiveDark,
        textNavInactiveMobile: AppColors.textNavInactiveMobileDark,
        primary: AppColors.primaryDark,
        primaryHover: AppColors.primaryHoverDark,
        primary50: AppColors.primary50Dark,
        primaryText: AppColors.primaryTextDark,
        primaryBorder: AppColors.primaryBorderDark,
        primaryRing: AppColors.primaryRingDark,
        onPrimary: AppColors.onPrimaryDark,
        accentSoft: AppColors.accentSoftDark,
        accentBorder: AppColors.accentBorderDark,
        accentBadgeBg: AppColors.accentBadgeBgDark,
        accentBadgeText: AppColors.accentBadgeTextDark,
        sidebar: AppColors.sidebarDark,
        sidebarLogo: AppColors.sidebarLogoDark,
        sidebarActive: AppColors.sidebarActiveDark,
        sidebarActiveBg: AppColors.sidebarActiveBgDark,
        sidebarHoverBg: AppColors.sidebarHoverBgDark,
        sidebarNav: AppColors.sidebarNavDark,
        sidebarBorder: AppColors.sidebarBorderDark,
        danger: AppColors.dangerDark,
        dangerSoft: AppColors.dangerSoftDark,
        dangerBorder: AppColors.dangerBorderDark,
        dangerBtn: AppColors.dangerBtnDark,
        dangerBtnHover: AppColors.dangerBtnHoverDark,
        info: AppColors.infoDark,
        infoSoft: AppColors.infoSoftDark,
        warning: AppColors.warningDark,
        swipeAction: AppColors.swipeActionDark,
        swipeDelete: AppColors.swipeDeleteDark,
        swipeBack: AppColors.swipeBackDark,
        swipeDisabled: AppColors.swipeDisabledDark,
        swipeSelf: AppColors.swipeSelfDark,
        swipeMembers: AppColors.swipeMembersDark,
        storeSuper: AppColors.storeSuperDark,
        storeSuperSoft: AppColors.storeSuperSoftDark,
        storeSuperBorder: AppColors.storeSuperBorderDark,
        storeSuperText: AppColors.storeSuperTextDark,
        storeOnline: AppColors.storeOnlineDark,
        storeOnlineSoft: AppColors.storeOnlineSoftDark,
        storeOnlineBorder: AppColors.storeOnlineBorderDark,
        storeOnlineText: AppColors.storeOnlineTextDark,
        storeDrug: AppColors.storeDrugDark,
        storeDrugSoft: AppColors.storeDrugSoftDark,
        storeDrugBorder: AppColors.storeDrugBorderDark,
        storeDrugText: AppColors.storeDrugTextDark,
        onboardingFrom: AppColors.onboardingFromDark,
        onboardingTo: AppColors.onboardingToDark,
        statusActiveBg: AppColors.statusActiveBgDark,
        statusActiveText: AppColors.statusActiveTextDark,
        statusActiveBorder: AppColors.statusActiveBorderDark,
        statusPendingBg: AppColors.statusPendingBgDark,
        statusPendingText: AppColors.statusPendingTextDark,
        statusPendingBorder: AppColors.statusPendingBorderDark,
        paletteEmeraldSoft: AppColors.paletteEmeraldSoftDark,
        paletteEmeraldBorder: AppColors.paletteEmeraldBorderDark,
        paletteEmeraldText: AppColors.paletteEmeraldTextDark,
        paletteBlueSoft: AppColors.paletteBlueSoftDark,
        paletteBlueBorder: AppColors.paletteBlueBorderDark,
        paletteBlueText: AppColors.paletteBlueTextDark,
        paletteAmberSoft: AppColors.paletteAmberSoftDark,
        paletteAmberBorder: AppColors.paletteAmberBorderDark,
        paletteAmberText: AppColors.paletteAmberTextDark,
        paletteVioletSoft: AppColors.paletteVioletSoftDark,
        paletteVioletBorder: AppColors.paletteVioletBorderDark,
        paletteVioletText: AppColors.paletteVioletTextDark,
        paletteRoseSoft: AppColors.paletteRoseSoftDark,
        paletteRoseBorder: AppColors.paletteRoseBorderDark,
        paletteRoseText: AppColors.paletteRoseTextDark,
      );

  @override
  AppColorScheme copyWith({
    Color? surface,
    Color? surfaceCard,
    Color? surfaceSubtle,
    Color? surfaceLogin,
    Color? border,
    Color? borderSubtle,
    Color? textHeading,
    Color? textBody,
    Color? textMuted,
    Color? textBrand,
    Color? textNavInactive,
    Color? textNavInactiveMobile,
    Color? primary,
    Color? primaryHover,
    Color? primary50,
    Color? primaryText,
    Color? primaryBorder,
    Color? primaryRing,
    Color? onPrimary,
    Color? accentSoft,
    Color? accentBorder,
    Color? accentBadgeBg,
    Color? accentBadgeText,
    Color? sidebar,
    Color? sidebarLogo,
    Color? sidebarActive,
    Color? sidebarActiveBg,
    Color? sidebarHoverBg,
    Color? sidebarNav,
    Color? sidebarBorder,
    Color? danger,
    Color? dangerSoft,
    Color? dangerBorder,
    Color? dangerBtn,
    Color? dangerBtnHover,
    Color? info,
    Color? infoSoft,
    Color? warning,
    Color? swipeAction,
    Color? swipeDelete,
    Color? swipeBack,
    Color? swipeDisabled,
    Color? swipeSelf,
    Color? swipeMembers,
    Color? storeSuper,
    Color? storeSuperSoft,
    Color? storeSuperBorder,
    Color? storeSuperText,
    Color? storeOnline,
    Color? storeOnlineSoft,
    Color? storeOnlineBorder,
    Color? storeOnlineText,
    Color? storeDrug,
    Color? storeDrugSoft,
    Color? storeDrugBorder,
    Color? storeDrugText,
    Color? onboardingFrom,
    Color? onboardingTo,
    Color? statusActiveBg,
    Color? statusActiveText,
    Color? statusActiveBorder,
    Color? statusPendingBg,
    Color? statusPendingText,
    Color? statusPendingBorder,
    Color? paletteEmeraldSoft,
    Color? paletteEmeraldBorder,
    Color? paletteEmeraldText,
    Color? paletteBlueSoft,
    Color? paletteBlueBorder,
    Color? paletteBlueText,
    Color? paletteAmberSoft,
    Color? paletteAmberBorder,
    Color? paletteAmberText,
    Color? paletteVioletSoft,
    Color? paletteVioletBorder,
    Color? paletteVioletText,
    Color? paletteRoseSoft,
    Color? paletteRoseBorder,
    Color? paletteRoseText,
  }) {
    return AppColorScheme(
      surface: surface ?? this.surface,
      surfaceCard: surfaceCard ?? this.surfaceCard,
      surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
      surfaceLogin: surfaceLogin ?? this.surfaceLogin,
      border: border ?? this.border,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      textHeading: textHeading ?? this.textHeading,
      textBody: textBody ?? this.textBody,
      textMuted: textMuted ?? this.textMuted,
      textBrand: textBrand ?? this.textBrand,
      textNavInactive: textNavInactive ?? this.textNavInactive,
      textNavInactiveMobile: textNavInactiveMobile ?? this.textNavInactiveMobile,
      primary: primary ?? this.primary,
      primaryHover: primaryHover ?? this.primaryHover,
      primary50: primary50 ?? this.primary50,
      primaryText: primaryText ?? this.primaryText,
      primaryBorder: primaryBorder ?? this.primaryBorder,
      primaryRing: primaryRing ?? this.primaryRing,
      onPrimary: onPrimary ?? this.onPrimary,
      accentSoft: accentSoft ?? this.accentSoft,
      accentBorder: accentBorder ?? this.accentBorder,
      accentBadgeBg: accentBadgeBg ?? this.accentBadgeBg,
      accentBadgeText: accentBadgeText ?? this.accentBadgeText,
      sidebar: sidebar ?? this.sidebar,
      sidebarLogo: sidebarLogo ?? this.sidebarLogo,
      sidebarActive: sidebarActive ?? this.sidebarActive,
      sidebarActiveBg: sidebarActiveBg ?? this.sidebarActiveBg,
      sidebarHoverBg: sidebarHoverBg ?? this.sidebarHoverBg,
      sidebarNav: sidebarNav ?? this.sidebarNav,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      dangerBorder: dangerBorder ?? this.dangerBorder,
      dangerBtn: dangerBtn ?? this.dangerBtn,
      dangerBtnHover: dangerBtnHover ?? this.dangerBtnHover,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
      warning: warning ?? this.warning,
      swipeAction: swipeAction ?? this.swipeAction,
      swipeDelete: swipeDelete ?? this.swipeDelete,
      swipeBack: swipeBack ?? this.swipeBack,
      swipeDisabled: swipeDisabled ?? this.swipeDisabled,
      swipeSelf: swipeSelf ?? this.swipeSelf,
      swipeMembers: swipeMembers ?? this.swipeMembers,
      storeSuper: storeSuper ?? this.storeSuper,
      storeSuperSoft: storeSuperSoft ?? this.storeSuperSoft,
      storeSuperBorder: storeSuperBorder ?? this.storeSuperBorder,
      storeSuperText: storeSuperText ?? this.storeSuperText,
      storeOnline: storeOnline ?? this.storeOnline,
      storeOnlineSoft: storeOnlineSoft ?? this.storeOnlineSoft,
      storeOnlineBorder: storeOnlineBorder ?? this.storeOnlineBorder,
      storeOnlineText: storeOnlineText ?? this.storeOnlineText,
      storeDrug: storeDrug ?? this.storeDrug,
      storeDrugSoft: storeDrugSoft ?? this.storeDrugSoft,
      storeDrugBorder: storeDrugBorder ?? this.storeDrugBorder,
      storeDrugText: storeDrugText ?? this.storeDrugText,
      onboardingFrom: onboardingFrom ?? this.onboardingFrom,
      onboardingTo: onboardingTo ?? this.onboardingTo,
      statusActiveBg: statusActiveBg ?? this.statusActiveBg,
      statusActiveText: statusActiveText ?? this.statusActiveText,
      statusActiveBorder: statusActiveBorder ?? this.statusActiveBorder,
      statusPendingBg: statusPendingBg ?? this.statusPendingBg,
      statusPendingText: statusPendingText ?? this.statusPendingText,
      statusPendingBorder: statusPendingBorder ?? this.statusPendingBorder,
      paletteEmeraldSoft: paletteEmeraldSoft ?? this.paletteEmeraldSoft,
      paletteEmeraldBorder: paletteEmeraldBorder ?? this.paletteEmeraldBorder,
      paletteEmeraldText: paletteEmeraldText ?? this.paletteEmeraldText,
      paletteBlueSoft: paletteBlueSoft ?? this.paletteBlueSoft,
      paletteBlueBorder: paletteBlueBorder ?? this.paletteBlueBorder,
      paletteBlueText: paletteBlueText ?? this.paletteBlueText,
      paletteAmberSoft: paletteAmberSoft ?? this.paletteAmberSoft,
      paletteAmberBorder: paletteAmberBorder ?? this.paletteAmberBorder,
      paletteAmberText: paletteAmberText ?? this.paletteAmberText,
      paletteVioletSoft: paletteVioletSoft ?? this.paletteVioletSoft,
      paletteVioletBorder: paletteVioletBorder ?? this.paletteVioletBorder,
      paletteVioletText: paletteVioletText ?? this.paletteVioletText,
      paletteRoseSoft: paletteRoseSoft ?? this.paletteRoseSoft,
      paletteRoseBorder: paletteRoseBorder ?? this.paletteRoseBorder,
      paletteRoseText: paletteRoseText ?? this.paletteRoseText,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColorScheme(
      surface: l(surface, other.surface),
      surfaceCard: l(surfaceCard, other.surfaceCard),
      surfaceSubtle: l(surfaceSubtle, other.surfaceSubtle),
      surfaceLogin: l(surfaceLogin, other.surfaceLogin),
      border: l(border, other.border),
      borderSubtle: l(borderSubtle, other.borderSubtle),
      textHeading: l(textHeading, other.textHeading),
      textBody: l(textBody, other.textBody),
      textMuted: l(textMuted, other.textMuted),
      textBrand: l(textBrand, other.textBrand),
      textNavInactive: l(textNavInactive, other.textNavInactive),
      textNavInactiveMobile: l(textNavInactiveMobile, other.textNavInactiveMobile),
      primary: l(primary, other.primary),
      primaryHover: l(primaryHover, other.primaryHover),
      primary50: l(primary50, other.primary50),
      primaryText: l(primaryText, other.primaryText),
      primaryBorder: l(primaryBorder, other.primaryBorder),
      primaryRing: l(primaryRing, other.primaryRing),
      onPrimary: l(onPrimary, other.onPrimary),
      accentSoft: l(accentSoft, other.accentSoft),
      accentBorder: l(accentBorder, other.accentBorder),
      accentBadgeBg: l(accentBadgeBg, other.accentBadgeBg),
      accentBadgeText: l(accentBadgeText, other.accentBadgeText),
      sidebar: l(sidebar, other.sidebar),
      sidebarLogo: l(sidebarLogo, other.sidebarLogo),
      sidebarActive: l(sidebarActive, other.sidebarActive),
      sidebarActiveBg: l(sidebarActiveBg, other.sidebarActiveBg),
      sidebarHoverBg: l(sidebarHoverBg, other.sidebarHoverBg),
      sidebarNav: l(sidebarNav, other.sidebarNav),
      sidebarBorder: l(sidebarBorder, other.sidebarBorder),
      danger: l(danger, other.danger),
      dangerSoft: l(dangerSoft, other.dangerSoft),
      dangerBorder: l(dangerBorder, other.dangerBorder),
      dangerBtn: l(dangerBtn, other.dangerBtn),
      dangerBtnHover: l(dangerBtnHover, other.dangerBtnHover),
      info: l(info, other.info),
      infoSoft: l(infoSoft, other.infoSoft),
      warning: l(warning, other.warning),
      swipeAction: l(swipeAction, other.swipeAction),
      swipeDelete: l(swipeDelete, other.swipeDelete),
      swipeBack: l(swipeBack, other.swipeBack),
      swipeDisabled: l(swipeDisabled, other.swipeDisabled),
      swipeSelf: l(swipeSelf, other.swipeSelf),
      swipeMembers: l(swipeMembers, other.swipeMembers),
      storeSuper: l(storeSuper, other.storeSuper),
      storeSuperSoft: l(storeSuperSoft, other.storeSuperSoft),
      storeSuperBorder: l(storeSuperBorder, other.storeSuperBorder),
      storeSuperText: l(storeSuperText, other.storeSuperText),
      storeOnline: l(storeOnline, other.storeOnline),
      storeOnlineSoft: l(storeOnlineSoft, other.storeOnlineSoft),
      storeOnlineBorder: l(storeOnlineBorder, other.storeOnlineBorder),
      storeOnlineText: l(storeOnlineText, other.storeOnlineText),
      storeDrug: l(storeDrug, other.storeDrug),
      storeDrugSoft: l(storeDrugSoft, other.storeDrugSoft),
      storeDrugBorder: l(storeDrugBorder, other.storeDrugBorder),
      storeDrugText: l(storeDrugText, other.storeDrugText),
      onboardingFrom: l(onboardingFrom, other.onboardingFrom),
      onboardingTo: l(onboardingTo, other.onboardingTo),
      statusActiveBg: l(statusActiveBg, other.statusActiveBg),
      statusActiveText: l(statusActiveText, other.statusActiveText),
      statusActiveBorder: l(statusActiveBorder, other.statusActiveBorder),
      statusPendingBg: l(statusPendingBg, other.statusPendingBg),
      statusPendingText: l(statusPendingText, other.statusPendingText),
      statusPendingBorder: l(statusPendingBorder, other.statusPendingBorder),
      paletteEmeraldSoft: l(paletteEmeraldSoft, other.paletteEmeraldSoft),
      paletteEmeraldBorder: l(paletteEmeraldBorder, other.paletteEmeraldBorder),
      paletteEmeraldText: l(paletteEmeraldText, other.paletteEmeraldText),
      paletteBlueSoft: l(paletteBlueSoft, other.paletteBlueSoft),
      paletteBlueBorder: l(paletteBlueBorder, other.paletteBlueBorder),
      paletteBlueText: l(paletteBlueText, other.paletteBlueText),
      paletteAmberSoft: l(paletteAmberSoft, other.paletteAmberSoft),
      paletteAmberBorder: l(paletteAmberBorder, other.paletteAmberBorder),
      paletteAmberText: l(paletteAmberText, other.paletteAmberText),
      paletteVioletSoft: l(paletteVioletSoft, other.paletteVioletSoft),
      paletteVioletBorder: l(paletteVioletBorder, other.paletteVioletBorder),
      paletteVioletText: l(paletteVioletText, other.paletteVioletText),
      paletteRoseSoft: l(paletteRoseSoft, other.paletteRoseSoft),
      paletteRoseBorder: l(paletteRoseBorder, other.paletteRoseBorder),
      paletteRoseText: l(paletteRoseText, other.paletteRoseText),
    );
  }
}
