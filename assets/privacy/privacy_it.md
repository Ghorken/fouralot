# Informativa sulla Privacy

**App:** 4alot
**Ultimo aggiornamento:** 20 marzo 2026

---

## 1. Introduzione

4alot è un gioco di Forza 4 per Android. Questa Informativa sulla Privacy spiega quali informazioni (se presenti) vengono raccolte durante l'utilizzo dell'app e come vengono gestite.

Il nostro principio fondamentale: **raccogliamo il minimo indispensabile**, solo ciò che è strettamente necessario per il funzionamento dell'app.

---

## 2. Informazioni Raccolte

### 2.1 Dati Personali

Non raccogliamo **nessun dato personale**. L'app non richiede account, registrazione o accesso. Si gioca in modo completamente anonimo.

### 2.2 Dati di Gioco (Solo Modalità Multiplayer Online)

Quando si utilizza la modalità **multiplayer via Internet**, i seguenti dati temporanei vengono inviati al Firebase Realtime Database (ospitato da Google nella regione Europe-West-1):

- Un codice stanza generato casualmente di 5 cifre
- Stato del gioco: posizioni del tabellone, piazzamento pezzi e mosse
- Modalità di gioco selezionata

Questi dati esistono **solo per la durata della sessione di gioco** e vengono cancellati automaticamente e definitivamente dai server Firebase non appena il giocatore ospite si disconnette.

### 2.3 Dati di Rete Locale (Modalità LAN)

Nella modalità **LAN/Wi-Fi**, i dati di gioco vengono scambiati **direttamente tra i dispositivi** sulla rete locale tramite una connessione TCP sulla porta 4242. Nessun dato viene inviato a server esterni. L'indirizzo IP locale viene utilizzato per la connessione diretta, ma non viene mai memorizzato né trasmesso al di fuori della rete locale.

### 2.4 Gioco Locale e Modalità AI

Queste modalità funzionano **interamente sul dispositivo**. Nessun dato viene trasmesso.

---

## 3. Dati che Non Raccogliamo

Non raccogliamo:

- Nomi, indirizzi email o altri identificatori personali
- Identificatori del dispositivo (IMEI, advertising ID, ecc.)
- Dati di geolocalizzazione
- Statistiche di utilizzo o analitiche
- Segnalazioni di crash
- Contatti, foto, dati della fotocamera o del microfono
- Dati pubblicitari o di marketing
- Cronologia di gioco o statistiche

---

## 4. Servizi di Terze Parti

### 4.1 Firebase Realtime Database (Google)

Il multiplayer via Internet utilizza il **Firebase Realtime Database**, un servizio fornito da Google LLC. Quando questa funzionalità è in uso, i dati di gioco temporanei transitano attraverso l'infrastruttura di Google.

- Informativa sulla privacy di Firebase: [https://firebase.google.com/support/privacy](https://firebase.google.com/support/privacy)
- Informativa sulla privacy di Google: [https://policies.google.com/privacy?hl=it](https://policies.google.com/privacy?hl=it)

Firebase è utilizzato **esclusivamente** per trasmettere le mosse di gioco tra due giocatori. Non vengono utilizzati Firebase Analytics, Crashlytics, Authentication o altri servizi Firebase.

### 4.2 Google Fonts

L'app utilizza il font **Orbitron** tramite il pacchetto Flutter `google_fonts`. I file del font possono essere scaricati dai server di Google al primo avvio, a seconda del comportamento di cache della piattaforma.

- Privacy di Google Fonts: [https://developers.google.com/fonts/faq/privacy](https://developers.google.com/fonts/faq/privacy)

---

## 5. Permessi

L'app richiede i seguenti permessi Android:

| Permesso | Finalità |
|---|---|
| `INTERNET` | Necessario per il multiplayer via Internet e il caricamento dei font |
| `ACCESS_NETWORK_STATE` | Necessario per ottenere l'indirizzo IP locale per il multiplayer LAN |

Non vengono richiesti altri permessi. L'app non accede a fotocamera, microfono, posizione, contatti o alcun archivio di file.

---

## 6. Conservazione dei Dati

- I **dati del multiplayer via Internet** vengono cancellati automaticamente da Firebase al termine della sessione di gioco (disconnessione dell'host).
- **Nessun altro dato** viene conservato da noi, né localmente né su alcun server.

---

## 7. Privacy dei Minori

4alot è un gioco adatto a tutti i pubblici e a tutte le età. Non raccogliamo consapevolmente informazioni personali da minori o da qualsiasi altro utente.

---

## 8. Sicurezza

Tutti i dati di gioco trasmessi tramite Firebase viaggiano via HTTPS. La comunicazione LAN avviene tramite TCP all'interno della rete locale. Non memorizziamo dati sensibili, il che riduce al minimo i rischi per la sicurezza.

---

## 9. I Tuoi Diritti

Poiché non raccogliamo dati personali, generalmente non vi è nulla da consultare, correggere o cancellare. Per qualsiasi domanda relativa alla privacy, contattaci all'indirizzo indicato di seguito.

In conformità al Regolamento (UE) 2016/679 (GDPR), hai il diritto di richiedere informazioni su eventuali dati che ti riguardano e di chiederne la cancellazione. Per esercitare tali diritti, contatta l'indirizzo email indicato nella sezione 11.

---

## 10. Modifiche a Questa Informativa

Potremmo aggiornare la presente Informativa sulla Privacy di tanto in tanto. Eventuali modifiche saranno comunicate aggiornando la data di "Ultimo aggiornamento" in cima a questo documento.

---

## 11. Contatti

Per qualsiasi domanda relativa alla presente Informativa sulla Privacy, puoi contattarci a:

**Email:** smithingsthings@gmail.com

---

*Questa informativa si applica a tutte le versioni di 4alot su tutte le piattaforme supportate.*