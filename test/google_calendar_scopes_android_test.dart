import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bloom/models/google_oauth_failure.dart';
import 'package:bloom/services/google_calendar/google_calendar_scope_flow.dart';
import 'package:bloom/services/google_calendar/google_sign_in_config.dart';
import 'package:bloom/services/google_calendar/live_google_calendar_backend.dart';

void main() {
  group('skipCanAccessScopesCheck', () {
    test('Android saute canAccessScopes', () {
      expect(
        skipCanAccessScopesCheck(
          platform: TargetPlatform.android,
          isWeb: false,
        ),
        isTrue,
      );
    });

    test('iOS / desktop ne sautent pas', () {
      expect(
        skipCanAccessScopesCheck(platform: TargetPlatform.iOS, isWeb: false),
        isFalse,
      );
      expect(
        skipCanAccessScopesCheck(
          platform: TargetPlatform.macOS,
          isWeb: false,
        ),
        isFalse,
      );
    });
  });

  group('ensureCalendarScopesGranted', () {
    test('Android appelle requestScopes directement (jamais canAccessScopes)',
        () async {
      var canAccessCalls = 0;
      var requestCalls = 0;

      final granted = await ensureCalendarScopesGranted(
        scopes: GoogleSignInConfig.calendarScopes,
        platform: TargetPlatform.android,
        isWeb: false,
        canAccessScopes: (scopes) async {
          canAccessCalls++;
          throw StateError('canAccessScopes ne doit pas être appelé sur Android');
        },
        requestScopes: (scopes) async {
          requestCalls++;
          expect(scopes, GoogleSignInConfig.calendarScopes);
          return true;
        },
      );

      expect(granted, isTrue);
      expect(canAccessCalls, 0);
      expect(requestCalls, 1);
    });

    test('iOS peut court-circuiter via canAccessScopes', () async {
      var requestCalls = 0;
      final granted = await ensureCalendarScopesGranted(
        scopes: GoogleSignInConfig.calendarScopes,
        platform: TargetPlatform.iOS,
        isWeb: false,
        canAccessScopes: (_) async => true,
        requestScopes: (_) async {
          requestCalls++;
          return false;
        },
      );
      expect(granted, isTrue);
      expect(requestCalls, 0);
    });

    test('iOS tombe sur requestScopes si canAccessScopes UnimplementedError',
        () async {
      var requestCalls = 0;
      final granted = await ensureCalendarScopesGranted(
        scopes: GoogleSignInConfig.calendarScopes,
        platform: TargetPlatform.iOS,
        isWeb: false,
        canAccessScopes: (_) async {
          throw UnimplementedError('canAccessScopes() has not been implemented.');
        },
        requestScopes: (_) async {
          requestCalls++;
          return true;
        },
      );
      expect(granted, isTrue);
      expect(requestCalls, 1);
    });

    test('refus requestScopes renvoie false', () async {
      final granted = await ensureCalendarScopesGranted(
        scopes: GoogleSignInConfig.calendarScopes,
        platform: TargetPlatform.android,
        isWeb: false,
        requestScopes: (_) async => false,
      );
      expect(granted, isFalse);
    });
  });

  group('error mapping', () {
    final backend = LiveGoogleCalendarBackend();

    test('UnimplementedError n’est pas une erreur réseau', () {
      final kind = backend.classifyGenericForTest(
        UnimplementedError('canAccessScopes() has not been implemented.'),
      );
      expect(kind, GoogleOAuthFailureKind.unknown);
      expect(kind.userMessage.toLowerCase(), isNot(contains('internet')));
    });

    test('ApiException 7 / network_error reste réseau', () {
      final kind = backend.classifyPlatformForTest(
        PlatformException(
          code: 'network_error',
          message: 'com.google.android.gms.common.api.ApiException: 7:',
        ),
      );
      expect(kind, GoogleOAuthFailureKind.network);
      expect(kind.userMessage.toLowerCase(), contains('internet'));
    });

    test('permission / access_denied → autorisation refusée', () {
      final kind = backend.classifyPlatformForTest(
        PlatformException(code: 'sign_in_failed', message: 'access_denied'),
      );
      expect(kind, GoogleOAuthFailureKind.permissionDenied);
    });
  });
}
