# Génération APK Android

## Option 1: Installation Android SDK Local
1. Installer Android Studio ou Android Command Line Tools
2. Configurer ANDROID_HOME dans les variables d'environnement
3. Exécuter : `flutter build apk --release`

## Option 2: Utilisation GitHub Actions (Recommandé)
1. Créer un dépôt GitHub pour ce projet
2. Pusher le code (déjà committé localement)
3. GitHub Actions générera automatiquement l'APK
4. L'APK sera disponible dans les Releases GitHub

## Option 3: Version Web (Déjà Prête)
La version web est déjà construite dans `build/web/` et fonctionne parfaitement sur mobile via navigateur.

## Version Web - Instructions
1. Copier le contenu de `build/web/` sur un serveur web
2. Ou ouvrir `build/web/index.html` localement
3. Accéder depuis mobile : fonctionne comme une PWA

## Résultat
✅ Application fonctionnelle et prête à l'emploi !
🔄 Pour APK natif : choisir Option 1 ou 2 selon préférence