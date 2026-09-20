# Google Calendar OAuth — configuration Bloom

## Diagnostic actuel (vérifié dans le dépôt)

| Élément | État |
|--------|------|
| `applicationId` / package réel | **`com.example.bloom`** (`android/app/build.gradle.kts` + APK) |
| Message UI « com.example » | Truncation visuelle de **`com.example.bloom`** — ce n’est pas un autre package |
| `google-services.json` | **Absent** |
| `GOOGLE_SERVER_CLIENT_ID` (Web) | **Non fourni** au build (aucune valeur réelle dans le dépôt) |
| Client OAuth Android Cloud | **À créer / vérifier manuellement** (hors dépôt) |
| Client OAuth Web Cloud | **À créer manuellement** puis passer en dart-define |
| Permission `INTERNET` | Présente dans `AndroidManifest.xml` |

### Cause exacte de l’échec actuel

Bloom tourne **sans** `google-services.json`. Sur Android, `google_sign_in` exige alors le **Client ID Web** en `serverClientId`.

Ce client n’est **pas** configuré → catégorie diagnostic :

```text
Server Client ID incorrect / manquant
```

Même après ajout du client Web, le client **Android** doit correspondre à :

```text
package = com.example.bloom
+
SHA-1 du keystore debug utilisé par flutter run
```

Sinon → `ApiException: 10` / `OAuth Android incorrect`.

**Le réseau n’est pas la cause principale** tant que OAuth n’est pas configuré.

### Package `com.example.bloom`

C’est encore le package Flutter par défaut. **On ne le renomme pas** dans cette correction :

- l’APK et le code Kotlin (`MainActivity`) l’utilisent déjà ;
- tout client OAuth déjà créé avec ce package resterait valide ;
- un rename obligerait à recréer les clients Google Cloud.

Si tu renommes plus tard (ex. `com.alice.bloom`), mets à jour Gradle + clients OAuth en même temps.

---

## SHA debug (ne pas coller dans le code)

Récupère **toujours** le SHA de la machine qui exécute `flutter run` :

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

Sur la machine de développement actuelle (indicatif, peut différer ailleurs) :

- SHA-1 : `8F:A9:36:19:8C:9A:C0:D4:E0:36:AC:37:E0:75:44:57:E7:C2:D6:C1`
- SHA-256 : `40:C2:9E:0D:7A:90:C9:55:A4:5F:18:FF:E7:D5:6C:E2:64:E7:6F:7B:57:74:68:F9:13:21:38:41:85:E8:B1:ED`

---

## Étapes manuelles Google Cloud Console

1. [Google Cloud Console](https://console.cloud.google.com/) → ton projet
2. **APIs & Services → Library** → activer **Google Calendar API**
3. **OAuth consent screen** → ajouter ton compte comme **utilisateur de test**
4. **Credentials → Create OAuth client ID**
   - Type **Android**
     - Package name : `com.example.bloom`
     - SHA-1 : celui de `keytool` / `signingReport` sur **ta** machine
   - Type **Web application**
     - Copier le Client ID (`….apps.googleusercontent.com`)
5. Lancer Bloom avec le client **Web** (pas Android) :

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=COLLER_ICI_LE_CLIENT_WEB.apps.googleusercontent.com
```

Où récupérer le Client ID Web :

```text
Google Cloud Console
→ APIs & Services
→ Credentials
→ OAuth 2.0 Client IDs
→ entrée de type « Web application »
→ Client ID
```

Ne jamais committer de secret OAuth. Le Client ID Web se passe en dart-define.

---

## Vérification dans Bloom

1. Accueil → ⚙️ → Google Calendar  
2. En debug : bloc **Diagnostic OAuth** (package + Server Client ID manquant/configuré)  
3. **Connecter Google** → compte → permissions → état **Connecté**

## Catégories d’erreur (debug)

| Diagnostic | Signification |
|------------|----------------|
| Utilisateur a annulé | Picker fermé |
| Server Client ID incorrect / manquant | Pas de `GOOGLE_SERVER_CLIENT_ID` |
| OAuth Android incorrect | package / SHA-1 / clients Cloud |
| Connexion réseau impossible | DNS / offline / ApiException 7 |
| Permission refusée | Consent scopes |
| Token indisponible | Session sans access token |
