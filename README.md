# 👻 Phantom

Appli de musique perso pour iPhone et PC Windows.

- **Accueil** : les tendances du moment (Audius)
- **Recherche** : chercher un son
- **Bibliothèque** : playlists, J'aime, et tes propres fichiers (mp3, m4a, flac, wav)
- Lecture écran verrouillé sur iPhone, lecture aléatoire, répéter

## Comment obtenir les applis

Les applis sont construites automatiquement par GitHub (sur ses propres Mac et PC).
Pas besoin de Xcode.

1. Mets ce dossier sur un dépôt GitHub (branche `main`).
2. Va dans l'onglet **Actions** : « Construire Phantom » se lance tout seul (~15 min).
3. Une fois fini, va dans **Releases** (à droite sur la page du dépôt). Tu y trouves :
   - `Phantom.ipa` → l'appli iPhone
   - `Phantom-Setup.exe` → l'installateur PC

## Installer sur iPhone

1. Branche l'iPhone au Mac, ouvre **Sideloadly**.
2. Glisse `Phantom.ipa` dedans, mets ton identifiant Apple, clique **Start**.
3. Sur l'iPhone : Réglages > Général > VPN et gestion de l'appareil > ton e-mail > **Faire confiance**.

⚠️ Avec un compte Apple gratuit, l'appli doit être réinstallée tous les 7 jours
(Sideloadly peut le faire tout seul en Wi-Fi si le Mac est allumé).

## Installer sur PC

Double-clique sur `Phantom-Setup.exe`. Si Windows affiche « Windows a protégé votre PC »,
clique sur **Informations complémentaires** puis **Exécuter quand même**.

## Ajouter une source de musique

Le fichier `lib/sources/custom_source.dart` est un modèle vide.
Remplis-le, puis active-le dans `lib/sources/sources.dart`.
