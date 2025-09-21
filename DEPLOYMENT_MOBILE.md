# 📱 AppServMaison - Déploiement Mobile

## 🚀 APK Android Automatique via GitHub Actions

### Option 1 : Build Automatique (Recommandé) ✅

1. **Push votre code sur GitHub**
   ```bash
   git init
   git add .
   git commit -m "Interface moderne avec onglets"
   git branch -M main
   git remote add origin https://github.com/[VOTRE-USERNAME]/AppServMaison.git
   git push -u origin main
   ```

2. **GitHub Actions se déclenche automatiquement** 
   - Build Flutter en Ubuntu
   - Tests et analyse de code
   - Génération APK Android
   - Création de release avec APK téléchargeable

3. **Téléchargez l'APK**
   - Allez dans les "Releases" de votre repo GitHub
   - Téléchargez `app-release.apk`
   - Installez sur Android (activez "Sources inconnues")

### Option 2 : Build Local (si vous avez Android SDK)

```bash
# Installer Android SDK et configurer ANDROID_HOME
flutter build apk --release
```

## 📱 Installation sur Mobile

### Android
1. Téléchargez `app-release.apk` depuis GitHub Releases
2. Paramètres Android → Sécurité → Activez "Sources inconnues"
3. Ouvrez l'APK et installez
4. L'app se connecte automatiquement à `192.168.1.175:8080`

### iPhone (PWA Alternative)
1. Ouvrez Safari sur iPhone
2. Naviguez vers `http://192.168.1.175:8080` (si vous hébergez le web)
3. Appuyez "Partager" → "Ajouter à l'écran d'accueil"
4. L'app web fonctionne comme une app native

## 🏗️ Architecture de Déploiement

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   GitHub Repo   │───▶│ GitHub Actions  │───▶│   APK Release   │
│                 │    │                 │    │                 │
│ • Code Flutter  │    │ • Build Ubuntu  │    │ • app-release.apk│
│ • PowerShell API│    │ • Flutter SDK   │    │ • Auto-install  │
│ • Workflow YAML │    │ • Android Build │    │ • Version tagging│
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🔧 Configuration Serveur

Le serveur PowerShell doit tourner en permanence pour les connexions mobiles :

```powershell
# Exécuter en administrateur
.\serveur333-api-v2.ps1
```

**Service d'écoute :** `192.168.1.175:8080`  
**Endpoints :** Serveur (arrêt/redémarrage) + Plex (contrôles)

## 🎯 Fonctionnalités Mobile

### Onglet Serveur
- ✅ État du serveur en temps réel
- 🔄 Vérification de connectivité 
- ⚡ Arrêt et redémarrage à distance
- ❌ Annulation des opérations

### Onglet Plex
- 📺 État Plex Media Server
- ▶️ Démarrage/Arrêt Plex
- 🔄 Redémarrage intelligent
- 📱 Interface tactile optimisée

## 🌐 Alternative Web (iOS/Android)

Pour iPhone ou navigateur mobile :
```bash
flutter build web --release
# Héberger le dossier build/web/ sur votre serveur
```

L'interface web fonctionne identiquement sur tous les navigateurs mobiles !