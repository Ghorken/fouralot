import 'package:flutter/widgets.dart';
import 'package:fouralot/models/game_models.dart';

class AppLocalizations {
  final Locale locale;

  const AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    final loc = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(loc != null, 'AppLocalizations not found in context');
    return loc!;
  }

  bool get _it => locale.languageCode.toLowerCase().startsWith('it');

  String get chooseOpponent => _it ? 'SCEGLI AVVERSARIO' : 'CHOOSE OPPONENT';
  String get localLabel => _it ? 'LOCALE' : 'LOCAL';
  String get localSubtitle =>
      _it ? 'Due giocatori, stesso telefono' : 'Two players, same device';
  String get lanSubtitle => _it
      ? 'Rete locale (sotto lo stesso Wi-Fi)'
      : 'Local network (same Wi-Fi)';
  String get internetSubtitle =>
      _it ? 'Gioca online a distanza' : 'Play online remotely';
  String get vsComputerLabel => _it ? 'VS COMPUTER' : 'VS COMPUTER';
  String get vsComputerSubtitle =>
      _it ? "Gioca contro l'intelligenza artificiale" : 'Play against AI';

  String get onlineConnectionTitle =>
      _it ? 'CONNESSIONE ONLINE' : 'ONLINE CONNECTION';
  String get yourIpTitle => _it ? 'Il tuo IP' : 'Your IP';
  String yourIpBody(String ip) => _it
      ? "Condividi questo IP con l'altro giocatore: $ip"
      : 'Share this IP with the other player: $ip';
  String get internetMultiplayerTitle =>
      _it ? 'Multiplayer Internet' : 'Internet Multiplayer';
  String get internetMultiplayerBody => _it
      ? 'Crea una stanza e condividi il codice, oppure inserisci un codice per unirti.'
      : 'Create a room and share the code, or enter a code to join.';
  String get roomCode => _it ? 'CODICE STANZA' : 'ROOM CODE';
  String get createMatch => _it ? 'CREA PARTITA' : 'CREATE MATCH';
  String get host => _it ? 'OSPITA' : 'HOST';
  String get join => _it ? 'UNISCITI' : 'JOIN';
  String get connect => _it ? 'CONNETTI' : 'CONNECT';
  String get roomCodeHint => _it
      ? 'Inserisci codice stanza (es. 12345)'
      : 'Enter room code (e.g. 12345)';
  String get hostIpHint => _it
      ? "Inserisci IP dell'host (es. 192.168.1.10)"
      : 'Enter host IP (e.g. 192.168.1.10)';
  String get chooseGameMode =>
      _it ? 'SCEGLI MODALITÀ DI GIOCO' : 'CHOOSE GAME MODE';
  String get viewHostMode => _it ? 'VEDI MODALITÀ HOST' : 'VIEW HOST MODE';
  String get statusConnecting =>
      _it ? '⏳ Connessione in corso...' : '⏳ Connecting...';
  String get statusHosting =>
      _it ? '⏳ In attesa di un giocatore...' : '⏳ Waiting for a player...';
  String get statusConnected => _it ? '✅ Connesso!' : '✅ Connected!';
  String get statusDisconnected => _it ? '❌ Disconnesso' : '❌ Disconnected';
  String get statusError =>
      _it ? '❌ Errore di connessione' : '❌ Connection error';

  String get hostModeTitle => _it ? 'MODALITÀ HOST' : 'HOST MODE';
  String get gameModeTitle => _it ? 'MODALITÀ DI GIOCO' : 'GAME MODE';
  String get modeAcceptedByPlayer2 =>
      _it ? 'Modalità accettata dal giocatore 2' : 'Mode accepted by player 2';
  String get waitTitle => _it ? 'ATTENDI' : 'WAIT';
  String get waitForAcceptance => _it
      ? "Resta in attesa che l'avversario accetti la modalità di gioco."
      : 'Wait for the opponent to accept the game mode.';
  String get waitingHostMode => _it
      ? "In attesa che l'host scelga la modalità..."
      : 'Waiting for the host to choose the mode...';
  String get acceptMode => _it ? 'ACCETTA MODALITÀ' : 'ACCEPT MODE';
  String aiLevelToFace(int level) =>
      _it ? 'Livello IA da affrontare: $level' : 'AI level to face: $level';

  String modeName(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return _it ? 'NORMALE' : 'NORMAL';
      case GameMode.fourDirections:
        return _it ? '4 DIREZIONI' : '4 DIRECTIONS';
      case GameMode.blocks:
        return _it ? 'BLOCCHI' : 'BLOCKS';
    }
  }

  String modeDescription(GameMode mode) {
    switch (mode) {
      case GameMode.normal:
        return _it
            ? "Le regole classiche del Forza 4. Inserisci le pedine dall'alto e forma una fila di 4."
            : 'Classic Connect Four rules. Drop pieces from the top and make a row of 4.';
      case GameMode.fourDirections:
        return _it
            ? "Inserisci le pedine da qualsiasi lato della griglia toccando le frecce ↑↓←→. La pedina scivola fino al lato opposto o a un'altra pedina."
            : 'Insert pieces from any side of the grid using arrows ↑↓←→. The piece slides until the opposite side or another piece.';
      case GameMode.blocks:
        return _it
            ? 'Come 4 Direzioni (usa le frecce ↑↓←→), ma ogni giocatore ha 3 blocchi da posizionare al posto di una mossa. Le pedine si fermano anche sui blocchi.'
            : 'Like 4 Directions (use arrows ↑↓←→), but each player has 3 blocks to place instead of a move. Pieces stop on blocks too.';
    }
  }

  String get exitDialogTitle =>
      _it ? 'USCIRE DALLA PARTITA?' : 'LEAVE THE MATCH?';
  String get exitDialogMessage => _it
      ? 'Se esci adesso la partita verrà persa.'
      : 'If you leave now, the match will be lost.';
  String get cancel => _it ? 'ANNULLA' : 'CANCEL';
  String get exit => _it ? 'ESCI' : 'EXIT';
  String get opponentRetiredVictory => _it
      ? "L'avversario si è ritirato. Vittoria assegnata."
      : 'The opponent surrendered. Victory awarded.';
  String get invalidColumn => _it
      ? "Colonna piena, scegli un'altra colonna"
      : 'Column is full, choose another one';
  String get invalidBlockPlacement =>
      _it ? 'Non puoi piazzare un blocco qui' : 'You cannot place a block here';
  String get invalidSideMove => _it
      ? 'Mossa non valida: riga/colonna piena'
      : 'Invalid move: row/column is full';
  String aiLevelDefeated(int current, int next) => _it
      ? 'IA livello $current sconfitta. Prossimo livello: $next'
      : 'AI level $current defeated. Next level: $next';
  String get you => _it ? 'TU' : 'YOU';
  String playerN(int n) => _it ? 'Giocatore $n' : 'Player $n';
  String get yourTurn => _it ? 'IL TUO TURNO' : 'YOUR TURN';
  String get aiThinking => _it ? 'IA PENSA...' : 'AI THINKING...';
  String get opponent => _it ? 'AVVERSARIO' : 'OPPONENT';
  String aiLevelChip(int level) => _it ? 'IA LV $level' : 'AI LV $level';
  String get blocksLabel => _it ? 'Blocchi: ' : 'Blocks: ';
  String get placeBlock => _it ? 'PIAZZA BLOCCO' : 'PLACE BLOCK';
  String get draw => _it ? 'PAREGGIO!' : 'DRAW!';
  String aiWinsLevel(int level) =>
      _it ? '🤖 IA VINCE · LV $level' : '🤖 AI WINS · LV $level';
  String youWinLevel(int level) =>
      _it ? '🏆 HAI VINTO! · LV $level' : '🏆 YOU WON! · LV $level';
  String get youWin => _it ? '🏆 HAI VINTO!' : '🏆 YOU WON!';
  String get youLose => _it ? '😔 HAI PERSO!' : '😔 YOU LOST!';
  String playerWins(int? winner) =>
      _it ? 'GIOCATORE $winner VINCE!' : 'PLAYER $winner WINS!';
  String get menu => _it ? 'MENU' : 'MENU';
  String get newMatch => _it ? 'NUOVA PARTITA' : 'NEW MATCH';
  String get rematch => _it ? 'RIVINCITA' : 'REMATCH';

  String get coinFlipTitle => _it ? 'LANCIO DELLA MONETA' : 'COIN FLIP';
  String get coinFlipFlipping => _it ? 'Lancio in corso...' : 'Flipping...';
  String get coinFlipTapToContinue =>
      _it ? 'Tocca per continuare' : 'Tap to continue';
  String get coinFlipYouStart => _it ? 'Inizi tu!' : 'You go first!';
  String get coinFlipOpponentStarts =>
      _it ? "L'avversario inizia!" : 'Opponent goes first!';
  String get coinFlipAiStarts =>
      _it ? "L'IA inizia!" : 'The AI goes first!';
  String coinFlipPlayerStarts(int player) =>
      _it ? 'Inizia il Giocatore $player!' : 'Player $player goes first!';
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'it' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

extension AppLocX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
