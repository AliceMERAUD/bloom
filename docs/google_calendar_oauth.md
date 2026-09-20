# Google Calendar OAuth — configuration Bloom

## Diagnostic (code + environnement local)

| Élément | État |
|--------|------|
| `applicationId` | **`com.example.bloom`** (ne pas renommer) |
| `google-services.json` | **Absent** (volontaire) |
| `GOOGLE_SERVER_CLIENT_ID` | À fournir au build (Client ID **Web**, jamais inventé dans le code) |
| Scopes | `calendar.events` + `calendar.readonly` uniquement |
| Permission `INTERNET` | Présente |

### Flux code (google_sign_in 6.x)

```text
Connecter Google
  → GoogleSignIn.signIn()          // sélecteur de compte (scopes initiaux vides)
  → GoogleSignIn.requestScopes()   // autorisation Calendar
  → Calendar API (access token)
```

Le code **n’empêche pas** d’appeler `signIn()` si le Server Client ID manque.
Sans `google-services.json`, Play Services peut toutefois renvoyer
`ApiException: 10` **avant** le sélecteur tant que le Client ID Web + client
Android Cloud ne sont pas corrects.

### SHA debug

Récupérer **sur la machine qui exécute** `flutter run` / `flutter build apk --debug`
(même keystore debug si release signe encore en debug) :

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android

cd android && ./gradlew signingReport
```

Ne pas coller le SHA-1 dans le code Dart.

---

## À vérifier manuellement dans Google Cloud

Bloom **ne peut pas** accéder à ton projet Cloud. Vérifie :

1. **APIs & Services → Library** → **Google Calendar API** = activée  
2. **Credentials → OAuth client ID → Android**
   - Package : `com.example.bloom`
   - SHA-1 : celui de `keytool` / `signingReport` ci-dessus  
3. **Credentials → OAuth client ID → Web application**
   - Copier le Client ID (`….apps.googleusercontent.com`)  
4. Les deux clients dans **le même projet**  
5. **OAuth consent screen** : ton compte en utilisateur de test  

Lancement :

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=COLLER_LE_CLIENT_WEB.apps.googleusercontent.com
```

Où trouver le Client ID Web :

```text
Google Cloud Console → APIs & Services → Credentials
→ OAuth 2.0 Client IDs → type « Web application » → Client ID
```

Ne pas utiliser le Client ID **Android** comme `serverClientId`.

---

## Catégories d’erreur Bloom

| Diagnostic | Signification |
|------------|----------------|
| Server Client ID manquant | Pas de `GOOGLE_SERVER_CLIENT_ID` / config incomplète |
| Package ou SHA-1 non reconnu | Client Android Cloud incorrect |
| Server Client ID invalide | Mauvais client Web / mauvais projet |
| Google Calendar API non activée | API désactivée dans Cloud |
| Utilisateur a annulé | Picker fermé |
| Autorisation Google Calendar refusée | `requestScopes` refusé |
| Connexion réseau impossible | Offline / ApiException 7 |
