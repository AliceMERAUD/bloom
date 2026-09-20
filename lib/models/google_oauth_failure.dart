import 'package:flutter/foundation.dart';

/// Categories for Google Sign-In / Calendar failures (debug + UX).
/// Never includes tokens or secrets.
enum GoogleOAuthFailureKind {
  /// User dismissed the account picker.
  cancelled,

  /// Web OAuth client (`GOOGLE_SERVER_CLIENT_ID`) missing — often required on
  /// Android when `google-services.json` is absent.
  serverClientIdMissing,

  /// ApiException:10 — package / SHA-1 / Android OAuth client not recognized.
  oauthAndroidMisconfigured,

  /// Web client ID present but rejected / mismatched project.
  serverClientIdInvalid,

  /// Calendar API disabled in the Cloud project (when detectable).
  calendarApiDisabled,

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
  String get debugLabel {
    switch (this) {
      case GoogleOAuthFailureKind.cancelled:
        return 'Utilisateur a annulé';
      case GoogleOAuthFailureKind.serverClientIdMissing:
        return 'Server Client ID manquant';
      case GoogleOAuthFailureKind.oauthAndroidMisconfigured:
        return 'Package ou SHA-1 non reconnu par Google';
      case GoogleOAuthFailureKind.serverClientIdInvalid:
        return 'Server Client ID invalide';
      case GoogleOAuthFailureKind.calendarApiDisabled:
        return 'Google Calendar API non activée';
      case GoogleOAuthFailureKind.network:
        return 'Connexion réseau impossible';
      case GoogleOAuthFailureKind.permissionDenied:
        return 'Autorisation Google Calendar refusée';
      case GoogleOAuthFailureKind.tokenUnavailable:
        return 'Token indisponible';
      case GoogleOAuthFailureKind.unknown:
        return 'Erreur inconnue';
    }
  }

  String get userMessage {
    switch (this) {
      case GoogleOAuthFailureKind.cancelled:
        return 'Connexion Google annulée.';
      case GoogleOAuthFailureKind.serverClientIdMissing:
        return 'Configuration Google incomplète.\n'
            'Sans google-services.json, Android a besoin d’un Client ID Web '
            '(GOOGLE_SERVER_CLIENT_ID) en plus du client OAuth Android '
            '(package com.example.bloom + SHA-1).\n'
            'Voir docs/google_calendar_oauth.md';
      case GoogleOAuthFailureKind.oauthAndroidMisconfigured:
        return 'Package ou SHA-1 non reconnu par Google.\n'
            'Vérifie le client OAuth Android : package com.example.bloom '
            'et le SHA-1 du build debug (keytool / signingReport).\n'
            'Voir docs/google_calendar_oauth.md';
      case GoogleOAuthFailureKind.serverClientIdInvalid:
        return 'Server Client ID invalide.\n'
            'Utilise le Client ID Web du même projet Google Cloud '
            'que le client Android (pas le Client ID Android).';
      case GoogleOAuthFailureKind.calendarApiDisabled:
        return 'Google Calendar API non activée.\n'
            'Active « Google Calendar API » dans Google Cloud Console '
            'pour ce projet.';
      case GoogleOAuthFailureKind.network:
        return 'Connexion Google impossible.\n'
            'Vérifie ta connexion Internet et réessaie.';
      case GoogleOAuthFailureKind.permissionDenied:
        return 'Autorisation Google Calendar refusée.\n'
            'Réessaie et accepte l’accès au calendrier.';
      case GoogleOAuthFailureKind.tokenUnavailable:
        return 'Session Google expirée ou token indisponible.\n'
            'Reconnecte Google Calendar dans les paramètres.';
      case GoogleOAuthFailureKind.unknown:
        return 'Une erreur inattendue est survenue lors de la connexion Google.\n'
            'Réessaie. Si le problème continue, vérifie la configuration OAuth '
            '(docs/google_calendar_oauth.md).';
    }
  }
}

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
