import 'package:flutter/material.dart';

enum PosterThemeType {
  magazine('现代杂志风', Icons.auto_awesome_rounded),
  parchment('古典传奇风', Icons.history_edu_rounded),
  cyber('赛博霓虹风', Icons.memory_rounded),
  dossier('绝密档案风', Icons.folder_special_rounded);

  final String label;
  final IconData icon;
  const PosterThemeType(this.label, this.icon);
}

class PosterStyle {
  final Color bgColor;
  final Gradient? bgGradient;
  final Color cardBgColor;
  final Color borderColor;
  final Color cardBorderColor;
  final Color textColor;
  final Color subtextColor;
  final Color accentColor;
  final double borderRadius;
  final double borderWidth;
  final double imageRadius;
  final String headerLabel;

  const PosterStyle({
    required this.bgColor,
    this.bgGradient,
    required this.cardBgColor,
    required this.borderColor,
    required this.cardBorderColor,
    required this.textColor,
    required this.subtextColor,
    required this.accentColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.imageRadius,
    required this.headerLabel,
  });
}

PosterStyle getPosterThemeStyle(PosterThemeType type) {
  switch (type) {
    case PosterThemeType.magazine:
      return const PosterStyle(
        bgColor: Color(0xFFF8FAFC),
        cardBgColor: Colors.white,
        borderColor: Color(0xFFE2E8F0),
        cardBorderColor: Color(0xFFE2E8F0),
        textColor: Color(0xFF0F172A),
        subtextColor: Color(0xFF64748B),
        accentColor: Color(0xFF6366F1),
        borderRadius: 16.0,
        borderWidth: 1.5,
        imageRadius: 12.0,
        headerLabel: 'MODERN EDITORIAL ARCHIVE',
      );
    case PosterThemeType.parchment:
      return const PosterStyle(
        bgColor: Color(0xFFF4ECD8),
        bgGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF9F5EA), Color(0xFFEFE6CF)],
        ),
        cardBgColor: Color(0x70E5D9C3),
        borderColor: Color(0xFF8C6D46),
        cardBorderColor: Color(0xFFBCA685),
        textColor: Color(0xFF2C221E),
        subtextColor: Color(0xFF6B5848),
        accentColor: Color(0xFFB45309),
        borderRadius: 8.0,
        borderWidth: 2.5,
        imageRadius: 6.0,
        headerLabel: '❖ CHRONICLE OF HEROES ❖',
      );
    case PosterThemeType.cyber:
      return const PosterStyle(
        bgColor: Color(0xFF090D16),
        bgGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF080C14), Color(0xFF0F172A)],
        ),
        cardBgColor: Color(0xFF141C2E),
        borderColor: Color(0xFF00F0FF),
        cardBorderColor: Color(0xFF1E293B),
        textColor: Colors.white,
        subtextColor: Color(0xFF94A3B8),
        accentColor: Color(0xFF00F0FF),
        borderRadius: 4.0,
        borderWidth: 2.0,
        imageRadius: 2.0,
        headerLabel: '[SYSTEM: DECRYPTED SPECIMEN]',
      );
    case PosterThemeType.dossier:
      return const PosterStyle(
        bgColor: Color(0xFFEAE2D0),
        cardBgColor: Color(0xFFDFD4BE),
        borderColor: Color(0xFF5C5248),
        cardBorderColor: Color(0xFFBFB39C),
        textColor: Color(0xFF1F1D1A),
        subtextColor: Color(0xFF5E564D),
        accentColor: Color(0xFF991B1B),
        borderRadius: 2.0,
        borderWidth: 2.0,
        imageRadius: 2.0,
        headerLabel: '【 TOP SECRET // CLASSIFIED DOSSIER 】',
      );
  }
}
