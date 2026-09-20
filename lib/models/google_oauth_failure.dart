import 'package:flutter/foundation.dart';

/// Categories for Google Sign-In / Calendar failures (debug + UX).
/// Never includes tokens or secrets.
enum GoogleOAuthFailureKind {
  /// User dismissed the account picker.
  cancelled,

  /// `GOOGLE_SERVER_CLIENT_ID` (Web OAuth client) not provided at build time
  /// and no `google-services.json` path is available.
  serverClientIdMissing,

  /// Typical ApiException:10 DEVELOPER_ERROR — package/SHA-1/Android client
  /// or Web serverClientId mismatch in Google Cloud.
  oauthAndroidMisconfigured,

  /// ApiException:7 / socket / DNS.
  network,

  /// Scope / consent refused (when distinguishable).
  permissionDenied,

  /// Access token unavailable after sign-in.
  tokenUnavailable,

  /// Calendar API or other unclassified failure.
  unknown,
}

extension GoogleOAuthFailureKindX on GoogleOAuthFailureKind {
  /// Short label for debug diagnostics (not a secret).
  String get debugLabel {
    switch (this) {
      case GoogleOAuthFailureKind.cancelled:
        return 'Utilisateur a annulé';
      case GoogleOAuthFailureKind.serverClientIdMissing:
        return 'Server Client ID incorrect / manquant';
      case GoogleOAuthFailureKind.oauthAndroidMisconfigured:
        return 'OAuth Android incorrect (package / SHA-1 / clients Cloud)';
      case GoogleOAuthFailureKind.network:
        return 'Connexion réseau impossible';
      case GoogleOAuthFailureKind.permissionDenied:
        return 'Permission refusée';
      case GoogleOAuthFailureKind.tokenUnavailable:
        return 'Token indisponible';
      case GoogleOAuthFailureKind.unknown:
        return 'Erreur inconnue';
    }
  }

  /// User-facing French message (SnackBar). No secrets.
  String get userMessage {
    switch (this) {
      case GoogleOAuthFailureKind.cancelled:
        return 'Connexion Google annulée.';
      case GoogleOAuthFailureKind.serverClientIdMissing:
        return 'Configuration Google incomplète.\n'
            'Le compte Google peut être sélectionné, mais l’accès à '
            'Google Calendar nécessite une configuration OAuth complète '
            '(Client ID Web / GOOGLE_SERVER_CLIENT_ID).\n'
            'Package : com.example.bloom — voir docs/google_calendar_oauth.md';
      case GoogleOAuthFailureKind.oauthAndroidMisconfigured:
        return 'La configuration Google de Bloom semble incorrecte.\n'
            'OAuth Android : vérifie package com.example.bloom, '
            'SHA-1 debug et client Web '
            '(même projet Google Cloud).\n'
            'Voir docs/google_calendar_oauth.md';
      case GoogleOAuthFailureKind.network:
        return 'Connexion Google impossible.\n'
            'Vérifie ta connexion Internet et réessaie.';
      case GoogleOAuthFailureKind.permissionDenied:
        return 'Permission Google Calendar refusée.\n'
            'Réessaie et accepte l’accès au calendrier.';
      case GoogleOAuthFailureKind.tokenUnavailable:
        return 'Session Google expirée ou token indisponible.\n'
            'Reconnecte Google Calendar dans les paramètres.';
      case GoogleOAuthFailureKind.unknown:
        return 'Connexion Google impossible.\n'
            'Vérifie ta connexion Internet et la configuration Google de Bloom.';
    }
  }
}

/// Result of classifying a sign-in / API failure.
@immutable
class GoogleOAuthFailure {
  final GoogleOAuthFailureKind kind;
  final String userMessage;

  const GoogleOAuthFailure({
    required this.kind,
    required this.userMessage,
  });

  factory GoogleOAuthFailure.fromKind(GoogleOAuthFailureKind kind) {
    return GoogleOAuthFailure(kind: kind, userMessage: kind.userMessage);
  }
}
