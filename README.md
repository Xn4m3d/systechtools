# SYSTECHTOOLS - Suite de Maintenance Système v2.1+

Suite de scripts PowerShell pour la maintenance, le diagnostic et l'optimisation avancée de systèmes Windows.

---

## 📋 Contenu du Projet

### Scripts Disponibles

#### **menu-selector.ps1**
Menu centralisé pour exécuter tous les scripts disponibles.

**Fonctionnalités :**
- Lance les scripts via GitHub RAW URLs
- Interface interactive avec numérotation
- Exécution à distance (one-liner possible)
- Menu en boucle continu

**Utilisation :**
```powershell
.\menu-selector.ps1
```

Ou directement depuis GitHub (one-liner) :
```powershell
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1'))
```

---

#### **maintenance-system.ps1** ⭐
Script complet de maintenance système avec 17 options et mode auto personnalisé.

**NETTOYAGE (6 options) :**
- 1️⃣ Fichiers temporaires (Temp, AppData, $env:TEMP)
- 2️⃣ Cache Windows Update
- 3️⃣ Spool Imprimante
- 4️⃣ Corbeille
- 5️⃣ Disk Cleanup
- 6️⃣ **AUTO** - Tous les nettoyages

**RÉPARATION (4 options) :**
- 7️⃣ SFC /scannow (Réparation fichiers système - 15-30 min)
- 8️⃣ DISM RestoreHealth + ComponentCleanup
- 9️⃣ Repair-AppxPackages (Packages Microsoft Store)
- 🔟 **AUTO** - Toutes les réparations

**OPTIMISATION (4 options) :**
- 1️⃣1️⃣ Défragmentation/TRIM (détection HDD vs SSD automatique)
- 1️⃣2️⃣ Vidage journaux d'événements (System, Application, Security)
- 1️⃣3️⃣ Réparation menu contextuel Windows
- 1️⃣4️⃣ Export liste applications (fichier sur Bureau)

**OUTILS EXTERNES (2 options) :**
- 1️⃣5️⃣ MASS GRAVE ACTIVATION - Outil d'activation Windows
- 1️⃣6️⃣ WinUtil - Suite complète d'optimisation Windows

**MODE PERSONNALISÉ :**
- 1️⃣7️⃣ **AUTO PERSONNALISÉ** - Sélectionnez vos actions et lancez un auto mode pré-configuré
- 0️⃣ Quitter

**Caractéristiques Avancées :**
- ✅ Vérification automatique des privilèges administrateur
- ✅ Logging détaillé avec timestamps (INFO, SUCCESS, WARNING, ERROR, ACTION)
- ✅ Rapport de synthèse avec durée d'exécution
- ✅ Gestion des erreurs robuste et non-bloquante
- ✅ Détection automatique HDD vs SSD pour optimisation
- ✅ Mode auto personnalisé avec pré-configuration interactif
- ✅ Anticipation des choix utilisateur avant lancement automatique
- ✅ Support d'actions individuelles ou combinées

**Utilisation :**
```powershell
.\maintenance-system.ps1
```

**Résultats attendus (Mode AUTO) :**
- 5-100 GB libérés selon l'état du système
- Fichiers système réparés
- Image Windows restaurée
- Disque optimisé
- Journal récapitulatif avec durée

---

#### **jitter.ps1** ⭐
Analyseur professionnel de latence réseau et stabilité de connexion.

**Fonctionnalités :**
- Analyse jitter avec menu interactif complet
- Calcul écart-type (jitter) en millisecondes
- Statistiques complètes (min, max, moyenne)
- Évaluation automatique de qualité (4 niveaux)
- Bannière artistique en Unicode/couleurs
- Support mode paramétré ou interactif
- Recommandations selon le jitter (jeux, vidéo, appels, etc.)

**Paramètres:**
- Cible réseau (IP ou hostname) - défaut: 8.8.8.8
- Nombre de tentatives - défaut: 100
- Taille buffer - défaut: 1250 bytes

**Utilisation Interactif :**
```powershell
.\jitter.ps1
```

**Utilisation Paramétré :**
```powershell
.\jitter.ps1 -ComputerName "192.168.1.1" -Count 50 -BufferSize 2048
```

**Rapport Qualité :**
- 🟢 **Excellente** (< 5ms) : Jeux compétitifs, transactions
- 🔵 **Bonne** (5-15ms) : Streaming HD, vidéo, navigation
- 🟡 **Moyenne** (15-30ms) : Lag occasionnel, buffering possible
- 🔴 **Instabilité** (> 30ms) : Déconnexions fréquentes

---

## 🔗 Outils Externes Intégrés

Le menu de maintenance peut lancer directement deux outils externes populaires :

### MASS GRAVE ACTIVATION
Outil d'activation Windows rapide et simple.
- **Utilisation directe :** `irm https://get.activated.win | iex`
- **Via SYSTECHTOOLS :** Option 15 du menu maintenance-system.ps1
- Lancement sécurisé avec confirmation
- Exécution dans nouvelle fenêtre PowerShell élevée

### WinUtil
Suite complète d'optimisation et de tweaks Windows développée par Chris Titus Tech.
- **Utilisation directe :** `irm https://christitus.com/win | iex`
- **Via SYSTECHTOOLS :** Option 16 du menu maintenance-system.ps1
- Interface graphique complète
- 100+ optimisations disponibles
- Configurations de gaming, privacy, performance, etc.

---

## 🛠️ Installation

### Option 1 : Clonage Git
```bash
git clone https://github.com/Xn4m3d/systechtools.git
cd systechtools
```

### Option 2 : Téléchargement direct
Téléchargez les fichiers `.ps1` depuis le dépôt.

---

## 📋 Configuration Requise

- **Windows :** 7/10/11 ou Server 2012+
- **PowerShell :** 3.0+ (PowerShell 5.1+ recommandé pour AppX)
- **Privilèges :** Administrateur (requis pour la plupart des opérations)

---

## ▶️ Exécution

### Mode Local
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\menu-selector.ps1
```

### Mode Distant (GitHub - One-liner)
```powershell
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1'))
```

### Dépannage : "Cannot be loaded. The file is not digitally signed"

**Solution 1 (Temporaire - Recommandée) :**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\maintenance-system.ps1
```

**Solution 2 (Permanente - Utilisateur) :**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
.\maintenance-system.ps1
```

**Solution 3 (Ligne de commande directe) :**
```powershell
powershell -ExecutionPolicy Bypass -File ".\maintenance-system.ps1"
```

---

## 📊 Cas d'Usage

### Mode Auto Personnalisé - Flux Complet

```powershell
# 1. Lancer le script
.\maintenance-system.ps1

# 2. Sélectionner option 17 (AUTO PERSONNALISE)

# 3. Menu de sélection des actions
# Exemple: "1,2,3,6,11,12" pour sélectionner plusieurs actions

# 4. Pré-configuration interactive
# Le script demande les confirmations nécessaires AVANT de lancer l'auto mode:
# - Confirmation SFC (peut prendre 15-30 min)
# - Confirmation MASS GRAVE ACTIVATION
# - Confirmation WinUtil

# 5. Lancement automatique
# Une fois configuré, l'auto mode s'exécute seul sans interruption

# 6. Rapport final avec durée totale
```

### PC Problématique avec Espace Disque Plein - Preset Rapide

```powershell
# 1. Lancer le script
.\maintenance-system.ps1

# 2. Sélectionner les nettoyages rapides: "1,2,3,4,5"
# Résultat : 10-50 GB libérés typiquement

# OU pour maintenance complète: "1,2,3,4,5,7,8,11,12"
# Résultat : 20-100 GB libérés + réparations + optimisation
```

### Test de Stabilité Réseau

```powershell
# Mode interactif
.\jitter.ps1

# Ou directement :
.\jitter.ps1 -ComputerName "8.8.8.8" -Count 100 -BufferSize 1250

# Rapport : Latence, Jitter, Recommandations
```

---

## 🔧 Architecture et Structure

### Gestion des Erreurs
- Try-catch sur toutes les opérations critiques
- Logging détaillé des erreurs
- Pas d'interruption du flux pour erreurs non-bloquantes

### Logging Système
- 5 types : INFO, SUCCESS, WARNING, ERROR, ACTION
- Timestamps formatés (YYYY-MM-DD HH:MM:SS)
- Affichage coloré en temps réel
- Rapport synthétisé en fin d'exécution

### Privilèges
- Vérification automatique au démarrage
- Re-lancement avec privilèges administrateur si nécessaire
- Message d'erreur clair si droits insuffisants

### Mode Auto Personnalisé
- Sélection interactive d'actions (comma-separated)
- Pré-configuration des choix utilisateur
- Exécution sans interruption une fois lancée
- Logging complet de toutes les actions
- Rapport final détaillé

---

## 🚀 Fonctionnalités Avancées

### Gestion Utilisateurs (Via Menu Principal)
- Créer utilisateurs locaux
- Supprimer utilisateurs
- Ajouter au groupe Administrateurs
- Désactiver utilisateurs
- Changer mot de passe
- Voir utilisateurs connectés

### Optimisation Intelligente (Option 11)
- Détection automatique HDD vs SSD
- Défragmentation pour HDD
- TRIM optimisé pour SSD
- Gestion des services Windows associés

### Outils Externes (Options 15-16)
- MASS GRAVE ACTIVATION : Activation rapide Windows
- WinUtil : Interface graphique complète avec 100+ optimisations

### Mode Auto Personnalisé (Option 17)
- Sélection à la carte des actions à exécuter
- Pré-configuration interactive avant le lancement
- Anticipation des choix utilisateur
- Exécution automatique sans interruption
- Possibilité de combiner nettoyage, réparation, optimisation et outils externes

---

## 📈 Améliorations Futures Envisagées

- 📝 Sauvegarde des rapports en fichier (texte + CSV)
- 📊 Graphiques de statistiques disque
- ⏰ Scheduling automatique (tâches planifiées)
- 📧 Notification email de résultats
- 🔄 Versionning des rapports
- 🌐 Interface Web de monitoring
- 🐍 Version Python pour Linux/macOS
- 💾 Profils sauvegardés pour modes auto récurrents

---

## 🔒 Notes de Sécurité

⚠️ **Important :**
- Ces scripts **modifient le système** - testez d'abord en environnement contrôlé
- Les modes AUTO exécutent des opérations substantielles **selon votre configuration**
- **Sauvegardez les données critiques** avant utilisation
- Toujours exécuter depuis **PowerShell en administrateur**
- Scripts téléchargés : vérifiez le contenu avant exécution
- Outils externes : demande de confirmation explicite avant lancement
- SFC peut prendre 15-30 min : confirmez avant de lancer

---

## 📝 Changelog

### v2.1+

**maintenance-system.ps1 :**
- ✅ 6 options de nettoyage (était 5)
- ✅ 4 options de réparation (était 3) - ajout AppX
- ✅ 4 options d'optimisation (était 2) - menu contextuel, export apps
- ✅ 2 options d'outils externes - MASS GRAVE ACTIVATION, WinUtil
- ✅ Total : 17 options (était 11)
- ✅ **NOUVEAU : Mode auto personnalisé (Option 17)**
- ✅ Pré-configuration interactive des actions
- ✅ Logging amélioré
- ✅ Nettoyage Spool imprimante
- ✅ Gestion utilisateurs complète
- ✅ Réparation menu contextuel
- ✅ Exécution automatique sans interruption après configuration

**jitter.ps1 :**
- ✅ Refonte complète de l'interface
- ✅ Menu interactif 3-questions
- ✅ Calcul professionnel jitter
- ✅ Analyse qualité 4 niveaux
- ✅ Support mode paramétré
- ✅ Bannière artistique

**Autres :**
- ✅ Version indiquée v2.1+ dans scripts
- ✅ Meilleure structure générale
- ✅ Documentation améliorée
- ✅ Correction dénomination "MASS GRAVE ACTIVATION"
- ✅ Support mode auto personnalisé

### v2.0
- Menu centralisé basique
- Modes AUTO par catégorie
- Défragmentation intégrée
- Vidage journaux
- Rapport de synthèse

### v1.0
- Scripts de base
- SFC et DISM
- Nettoyage fichiers temporaires

---

## 💬 Support et Contribution

Pour signaler des bugs ou proposer des améliorations :
1. Créez une **issue** sur GitHub
2. Testez les scripts en environnement contrôlé
3. Proposez des **pull requests**

---

## 📄 Licence

Libre d'utilisation pour usage personnel et professionnel.

---

## 👤 Auteur

**Xn4m3d**
- GitHub: https://github.com/Xn4m3d/systechtools