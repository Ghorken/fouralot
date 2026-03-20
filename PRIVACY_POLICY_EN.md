# Privacy Policy

**App:** 4alot
**Last updated:** March 20, 2026

---

## 1. Introduction

4alot is a Connect Four game for Android, iOS, macOS, Windows, Linux, and Web. This Privacy Policy explains what information (if any) is collected when you use the app, and how it is handled.

Our core principle: **we collect as little data as possible**, only what is strictly necessary for the app to function.

---

## 2. Information We Collect

### 2.1 Personal Data

We do **not** collect any personal data. The app requires no account, no registration, and no login. You play completely anonymously.

### 2.2 Gameplay Data (Online Multiplayer Only)

When you use **Internet multiplayer** mode, the following temporary data is sent to Firebase Realtime Database (hosted by Google in the Europe-West-1 region):

- A randomly generated 5-digit room code
- Game state: board positions, piece placements, and moves
- Game mode selection

This data exists **only for the duration of the game session**. It is automatically and permanently deleted from Firebase servers as soon as the host player disconnects.

### 2.3 Local Network Data (LAN Mode)

When you use **LAN/Wi-Fi** mode, game data is exchanged **directly between devices** on your local network via a TCP connection on port 4242. No data is sent to any external server. Your local IP address is used for the direct connection but is never stored or transmitted outside your local network.

### 2.4 Local Play and AI Mode

These modes work **entirely on-device**. No data is transmitted anywhere.

---

## 3. Data We Do Not Collect

We do **not** collect:

- Names, email addresses, or any other personal identifiers
- Device identifiers (IMEI, advertising ID, etc.)
- Location data
- Usage statistics or analytics
- Crash reports
- Contacts, photos, camera, or microphone data
- Advertising or marketing data
- Game history or statistics

---

## 4. Third-Party Services

### 4.1 Firebase Realtime Database (Google)

Internet multiplayer uses **Firebase Realtime Database**, a service provided by Google LLC. When this feature is used, temporary game data passes through Google's infrastructure.

- Firebase Privacy Policy: [https://firebase.google.com/support/privacy](https://firebase.google.com/support/privacy)
- Google Privacy Policy: [https://policies.google.com/privacy](https://policies.google.com/privacy)

Firebase is used **solely** to relay game moves between two players. No Firebase Analytics, Crashlytics, Authentication, or any other Firebase service is used.

### 4.2 Google Fonts

The app uses the **Orbitron** font via the `google_fonts` Flutter package. Font files may be fetched from Google's servers on first use depending on your platform's caching behavior.

- Google Fonts Privacy: [https://developers.google.com/fonts/faq/privacy](https://developers.google.com/fonts/faq/privacy)

---

## 5. Permissions

The app requests the following Android permissions:

| Permission | Purpose |
|---|---|
| `INTERNET` | Required for Internet multiplayer and loading fonts |
| `ACCESS_NETWORK_STATE` | Required to obtain the local IP address for LAN multiplayer |

No other permissions are requested. The app does not access the camera, microphone, location, contacts, or any file storage.

---

## 6. Data Retention

- **Internet multiplayer data** is deleted automatically from Firebase when the game session ends (host disconnects).
- **No other data** is stored by us, either locally or on any server.

---

## 7. Children's Privacy

4alot is a general-audience game suitable for all ages. We do not knowingly collect any personal information from children or any other users.

---

## 8. Security

All game data transmitted via Firebase travels over HTTPS. LAN communication occurs over TCP within your local network. We do not store any sensitive data, which minimizes security risk.

---

## 9. Your Rights

Since we do not collect personal data, there is generally nothing to access, correct, or delete. If you have any privacy-related questions, contact us at the address below.

---

## 10. Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected by updating the "Last updated" date at the top of this document.

---

## 11. Contact

If you have any questions about this Privacy Policy, please contact us at:

**Email:** smithingsthings@gmail.com

---

*This policy applies to all versions of 4alot on all supported platforms.*
