# bloom

Application Flutter locale-first (Sport, Bien-être, Puzzle, Tasks).

## Google Calendar (optionnel)

Bloom peut pousser des tâches datées vers Google Calendar.
La connexion Google nécessite une configuration OAuth manuelle :

→ voir **[docs/google_calendar_oauth.md](docs/google_calendar_oauth.md)**

Lancement typique (client OAuth **Web**, pas Android) :

```bash
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=TON_CLIENT_WEB.apps.googleusercontent.com
```

## Getting Started

```bash
flutter pub get
flutter run
```
