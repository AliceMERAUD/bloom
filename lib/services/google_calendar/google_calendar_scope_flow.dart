import 'package:flutter/foundation.dart';

/// Decides whether to skip [GoogleSignIn.canAccessScopes] after account pick.
///
/// On Android (`google_sign_in_android` 6.2.x) `canAccessScopes` throws
/// `UnimplementedError` and must not be called — use `requestScopes` only.
bool skipCanAccessScopesCheck({
  TargetPlatform? platform,
  bool? isWeb,
}) {
  final web = isWeb ?? kIsWeb;
  final p = platform ?? defaultTargetPlatform;
  return !web && p == TargetPlatform.android;
}

/// After a successful account selection, ensure Calendar scopes are granted.
///
/// [requestScopes] is always the path used on Android.
/// On other platforms, [canAccessScopes] may short-circuit when already granted;
/// [UnimplementedError] from that check falls through to [requestScopes].
Future<bool> ensureCalendarScopesGranted({
  required Future<bool> Function(List<String> scopes) requestScopes,
  Future<bool> Function(List<String> scopes)? canAccessScopes,
  required List<String> scopes,
  TargetPlatform? platform,
  bool? isWeb,
}) async {
  final skipCheck = skipCanAccessScopesCheck(platform: platform, isWeb: isWeb);

  if (!skipCheck && canAccessScopes != null) {
    try {
      if (await canAccessScopes(scopes)) {
        return true;
      }
    } on UnimplementedError {
      // Platform stub — fall through to requestScopes.
    }
  }

  return requestScopes(scopes);
}
