# Google Calendar OAuth — configuration Bloom

Bloom pousse des tâches vers **Google Calendar** (pas de calendrier interne).
L’authentification utilise `google_sign_in` + l’API Calendar.

## Diagnostic (Phase 9)

Cause la plus fréquente de l’erreur du type
« Vérifie la configuration de l’authentification / du réseau » :

1. **Aucun `google-services.json`** dans le dépôt (volontaire pour rester léger).
2. **Aucun `serverClientId` (client OAuth Web)** fourni au build.
3. Client OAuth **Android** manquant ou SHA-1 / package incorrect dans Google Cloud.

Sur Android, sans `google-services.json`, le plugin exige le **client ID Web**
en `serverClientId` (jamais le client ID Android).

## Valeurs Bloom actuelles

| Élément | Valeur |
|--------|--------|
| `applicationId` / package | `com.example.bloom` |
| Fichier Gradle | `android/app/build.gradle.kts` |
| `google-services.json` | **absent** (pas de Firebase obligatoire) |
| Scopes | `calendar.events` + `calendar.readonly` |

### SHA debug (machine de développement actuelle)

Récupérés via `keytool` / `./gradlew signingReport` sur le keystore debug :

- **SHA-1 :** `8F:A9:36:19:8C:9A:C0:D4:E0:36:AC:37:E0:75:44:57:E7:C2:D6:C1`
- **SHA-256 :** `40:C2:9E:0D:7A:90:C9:55:A4:5F:18:FF:E7:D5:6C:E2:64:E7:6F:7B:57:74:68:F9:13:21:38:41:85:E8:B1:ED`

> Sur une autre machine, le SHA debug peut différer. Recalcule-le toujours localement.

### Recalculer le SHA debug

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android -keypass android
```

Ou :

```bash
cd android && ./gradlew signingReport
```

## Étapes manuelles Google Cloud Console

Ne pas inventer de client ID : crée-les dans **ton** projet Cloud.

1. Ouvre [Google Cloud Console](https://console.cloud.google.com/) → ton projet (ou crée-en un).
2. **APIs & Services → Library** → active **Google Calendar API**.
3. **APIs & Services → OAuth consent screen**
   - Type : External (ou Internal si Workspace)
   - Ajoute ton compte Google comme **test user** tant que l’app n’est pas vérifiée
   - Scopes : `.../auth/calendar.events` et `.../auth/calendar.readonly`
4. **APIs & Services → Credentials → Create credentials → OAuth client ID**
   - **Android**
     - Package name : `com.example.bloom`
     - SHA-1 : celui de ta machine (ci-dessus ou recalculé)
   - **Web application** (obligatoire pour Bloom sans `google-services.json`)
     - Nom libre (ex. `Bloom Web`)
     - Pas besoin d’URI de redirection pour ce flux mobile
     - Copie le **Client ID** (`….apps.googleusercontent.com`)
5. Lance Bloom en passant ce client Web :

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=TON_CLIENT_ID_WEB.apps.googleusercontent.com
```

Ou pour un APK debug :

```bash
flutter build apk --debug \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=TON_CLIENT_ID_WEB.apps.googleusercontent.com
```

## Option Firebase (alternative)

Si tu préfères Firebase :

1. Ajoute une app Android `com.example.bloom` + SHA-1 debug
2. Active Google Sign-In
3. Télécharge `google-services.json` dans `android/app/`
4. Applique le plugin Google Services Gradle (non câblé aujourd’hui)
5. Le fichier doit contenir un client OAuth **Web** (`client_type: 3`)

Sans Gradle Google Services, préfère `--dart-define=GOOGLE_SERVER_CLIENT_ID=…`.

## Vérification dans Bloom

1. Accueil → ⚙️ Paramètres → Google Calendar → **Connecter**
2. Choisir le compte → accepter les permissions
3. État **Connecté** + choix du calendrier
4. Créer une tâche datée → **Ajouter à Google Calendar**

## Sécurité

- Ne committe **jamais** de client secret, access token ou refresh token.
- Le client ID Web peut être passé en dart-define (ce n’est pas un secret serveur classique),
  mais évite de le committer en dur dans le dépôt si tu préfères.
- Les logs debug Bloom n’affichent pas les tokens.
