# 4alot - Multi-modalità

App Flutter per giocare a Forza 4 con tre modalità di connessione e tre modalità di gioco.

## 🎮 Modalità di Gioco

### Normale
Regole classiche. Le pedine vengono inserite dall'alto e cadono verso il basso.

### 4 Direzioni
Le pedine possono essere inserite da qualsiasi lato della griglia (sinistra, destra, alto, basso) e scivolano fino al bordo opposto o finché non incontrano un'altra pedina.

### Blocchi
Come 4 Direzioni, ma ogni giocatore ha 3 blocchi da posizionare (invece di una mossa normale). Le pedine si fermano anche sui blocchi.

## 🔌 Modalità di Connessione

### Locale
Nessuna configurazione necessaria. I due giocatori si passano il telefono a turno.

### Online (LAN/Wi-Fi)
Un giocatore ospita (il suo IP viene mostrato), l'altro inserisce quell'IP per connettersi. Usa TCP sulla porta 4242. **Nessun server esterno necessario**: funziona solo in rete locale.

### Bluetooth
Un giocatore rende il dispositivo visibile e ospita. L'altro seleziona il dispositivo dalla lista dei dispositivi accoppiati. I due dispositivi devono essere accoppiati in anticipo dalle impostazioni Bluetooth.

## 🛠️ Setup

### Dipendenze
```bash
flutter pub get
```

### Esegui
```bash
flutter run
```

### Build Android
```bash
flutter build apk --release
```

## 📦 Dipendenze principali

- `flutter_bluetooth_serial` — Comunicazione Bluetooth
- `provider` — State management
- `google_fonts` — Font Orbitron
- `flutter_animate` — Animazioni UI

## 📁 Struttura

```
lib/
├── main.dart
├── models/
│   ├── game_models.dart     # Enums e data classes
│   └── game_state.dart      # Logica di gioco (ChangeNotifier)
├── services/
│   ├── network_service.dart # TCP per modalità online
│   └── bluetooth_service.dart # BT per modalità bluetooth
├── screens/
│   ├── home_screen.dart     # Schermata iniziale
│   ├── connection_screen.dart # Setup connessione
│   ├── game_mode_screen.dart  # Selezione modalità
│   └── game_screen.dart     # Schermata di gioco
└── widgets/
    └── game_board.dart      # Griglia di gioco
```

## ⚠️ Note

- La modalità Bluetooth richiede che i dispositivi siano già accoppiati.
- La modalità Online richiede che entrambi i dispositivi siano sulla stessa rete Wi-Fi.
- Per le mosse remote, la logica della direzione viene codificata nel campo `row` del `Move` object per le modalità 4 Direzioni e Blocchi.
