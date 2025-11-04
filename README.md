# SYSTECHTOOLS - Suite de Maintenance Système v2.1+

Suite de scripts PowerShell pour la maintenance, le diagnostic et l'optimisation avancée de systèmes Windows. Version locale significativement enrichie par rapport à la version GitHub.

---

## 📋 Contenu du Projet

### Scripts Principaux Publiés

#### **menu-selector.ps1**
Menu centralisé amélioré pour exécuter tous les scripts disponibles.

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

#### **maintenance-system.ps1** ⭐ (VERSION FORTEMENT AMÉLIORÉE)
Script complet de maintenance système avec 17 options et logging avancé.

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

**GESTION (2 options) :**
- 1️⃣5️⃣ Gestion utilisateurs et groupes locaux (créer, supprimer, admin, etc.)
- 1️⃣6️⃣ Mass Gravel - Activation Windows (via get.activated.win)

**MODE COMPLET :**
- 1️⃣7️⃣ **AUTO COMPLET** - Exécute toutes les opérations (17 en 1)
- 0️⃣ Quitter

**Caractéristiques Avancées :**
- ✅ Vérification automatique des privilèges administrateur
- ✅ Logging détaillé avec timestamps (INFO, SUCCESS, WARNING, ERROR, ACTION)
- ✅ Rapport de synthèse avec durée d'exécution
- ✅ Gestion des erreurs robuste et non-bloquante
- ✅ Détection automatique HDD vs SSD pour optimisation
- ✅ Gestion avancée des services Windows
- ✅ Support de gestion utilisateurs et groupes
- ✅ Intégration Mass Gravel pour activation

**Utilisation :**
```powershell
.\maintenance-system.ps1
```

**Résultats attendus (Mode 17 - AUTO COMPLET) :**
- 5-100 GB libérés selon l'état du système
- Fichiers système réparés
- Image Windows restaurée
- Disque optimisé
- Journal récapitulatif avec durée

---

#### **jitter.ps1** ⭐ (VERSION FORTEMENT AMÉLIORÉE)
Analyseur professionnel de latence réseau et stabilité de connexion.

**Fonctionnalités :**
- Analyse jitter avec menu interactif complet
- Calcul écart-type (jitter) en millisecondes
- Statistiques complètes (min, max, moyenne)
- Évaluation automatique de qualité (4 niveaux)
- Banne artistique en Unicode/couleurs
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

### Script de Configuration

#### **setup.ps1**
Générateur automatique du menu-selector.ps1 (utilisé pour maintenance du menu uniquement).

**Fonctionnalités :**
- Scanne le dossier local pour tous les scripts .ps1
- Génère automatiquement les URLs GitHub RAW
- Crée un menu-selector.ps1 parfaitement à jour
- Affiche les URLs générées
- Note de sécurité intégrée

**Utilisation :**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\setup.ps1
```

**Prochaines étapes suggérées :**
```powershell
git add menu-selector.ps1
git commit -m 'Update menu-selector with new scripts'
git push
```

**⚠️ NOTE :** Ce script est **exclu des push** (dans .gitignore) - c'est un outil de maintenance local uniquement.

---

## 🔍 État du Projet vs GitHub

### ✅ Nouvelles Fonctionnalités depuis v2.0

#### maintenance-system.ps1
- ✅ Nettoyage Spool Imprimante (Nouvelle)
- ✅ Réparation Packages AppX (Nouvelle)
- ✅ Réparation menu contextuel (Nouvelle)
- ✅ Export liste applications vers fichier (Nouvelle)
- ✅ Gestion complète utilisateurs et groupes (Nouvelle)
- ✅ Intégration Mass Gravel / Activation Windows (Nouvelle)
- ✅ Augmentation de 11 à 17 options du menu principal
- ✅ Logging amélioré avec 5 types de messages
- ✅ Rapport détaillé avec temps d'exécution

#### jitter.ps1
- ✅ Interface complètement repensée (bannière ASCII + couleurs)
- ✅ Menu interactif paramétré (3 questions)
- ✅ Calcul professionnel du jitter (écart-type)
- ✅ Analyse automatique de qualité (4 niveaux)
- ✅ Recommandations contextuelles (jeux, streaming, etc.)
- ✅ Support mode paramétré + interactif
- ✅ Code source de ~10KB (vs ~2KB avant)

### 🔄 Améliorations Globales
- ✅ Version spécifiée à v2.1+ dans tous les scripts
- ✅ Meilleure structure et lisibilité du code
- ✅ Gestion d'erreurs plus robuste
- ✅ Interface utilisateur professionnelle (couleurs, symboles)
- ✅ Logging structuré avec timestamps

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

### PC Problématique avec Espace Disque Plein

```powershell
# 1. Lancer le script
.\maintenance-system.ps1

# 2. Sélectionner option 17 (AUTO COMPLET)

# 3. Résultats :
# - Fichiers temporaires supprimés
# - Cache Windows Update vidé
# - Spool imprimante nettoyé
# - Corbeille vidée
# - Disk Cleanup exécuté
# - SFC /scannow complété
# - DISM RestoreHealth + ComponentCleanup
# - AppX packages réparés
# - Disque défragmenté/optimisé (HDD/SSD)
# - Journaux événements vidés
# - Menu contextuel réparé
# - Rapport final avec durée totale

# Résultat : 10-100 GB libérés typiquement
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

---

## 🚀 Fonctionnalités Avancées

### Gestion Utilisateurs (Option 15)
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

### Activation Windows (Option 16)
- Intégration Mass Gravel
- Lancement sécurisé avec confirmation
- Exécution dans nouvelle fenêtre PowerShell élevée

---

## 📈 Améliorations Futures Envisagées

- 📝 Sauvegarde des rapports en fichier (texte + CSV)
- 📊 Graphiques de statistiques disque
- ⏰ Scheduling automatique (tâches planifiées)
- 📧 Notification email de résultats
- 🔄 Versionning des rapports
- 🌐 Interface Web de monitoring
- 🐍 Version Python pour Linux/macOS

---

## 🔒 Notes de Sécurité

⚠️ **Important :**
- Ces scripts **modifient le système** - testez d'abord en environnement contrôlé
- Les modes AUTO exécutent des opérations substantielles **sans confirmation supplémentaire**
- **Sauvegardez les données critiques** avant utilisation
- Toujours exécuter depuis **PowerShell en administrateur**
- Scripts téléchargés : vérifiez le contenu avant exécution
- Mass Gravel (Option 16) : demande de confirmation explicite

---

## 📝 Changelog

### v2.1+ (Actuelle - Version Locale Enrichie)

**maintenance-system.ps1 :**
- ✅ 6 options de nettoyage (était 5)
- ✅ 4 options de réparation (était 3) - ajout AppX
- ✅ 4 options d'optimisation (était 2) - menu contextuel, export apps
- ✅ 2 options de gestion (NEW) - utilisateurs, Mass Gravel
- ✅ Total : 17 options (était 11)
- ✅ Logging amélioré
- ✅ Nettoyage Spool imprimante
- ✅ Gestion utilisateurs complète
- ✅ Réparation menu contextuel

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

### v2.0 (GitHub - Versions Antérieures)
- Menu centralisé basique
- Modes AUTO par catégorie
- Défragmentation intégrée
- Vidage journaux
- Rapport de synthèse

### v1.0 (Initial)
- Scripts de base
- SFC et DISM
- Nettoyage fichiers temporaires

---

## 💬 Support et Contribution

Pour signaler des bugs ou proposer des améliorations :
1. Créez une **issue** sur GitHub
2. Testez les scripts en environnement contrôlé
3. Proposez des **pull requests**

Signaler les bugs spécifiques à la version locale enrichie.

---

## 📄 Licence

Libre d'utilisation pour usage personnel et professionnel.

---

## 👤 Auteur

**Xn4m3d**
- GitHub: https://github.com/Xn4m3d/systechtools
- Repository: https://github.com/Xn4m3d/systechtools

---

## 📌 Fichiers du Projet

| Fichier | Statut | Description |
|---------|--------|-------------|
| `menu-selector.ps1` | 📌 Push | Menu centralisé (auto-généré) |
| `maintenance-system.ps1` | 📌 Push | Script maintenance principal (v2.1+) |
| `jitter.ps1` | 📌 Push | Analyseur jitter réseau (v2.1+) |
| `setup.ps1` | ❌ Git Ignored | Générateur menu (outil local) |
| `README.md` | 📌 Push | Documentation (ce fichier) |
| `.git/` | ❌ Git Ignored | Dossier Git |
| `.gitignore` | 📌 Push | Fichiers ignorés (setup.ps1) |

---

## 🎯 Résumé des Changements Locaux

Votre version locale contient **significativement plus de contenu** que la version GitHub :

### maintenance-system.ps1
- **+50%** d'options de menu (11 → 17)
- **Nettoyage Spool Imprimante** (nouveau)
- **Réparation AppX Packages** (nouveau)
- **Gestion Utilisateurs** (nouveau complet)
- **Réparation Menu Contextuel** (nouveau)
- **Mass Gravel Integration** (nouveau)
- **Logging professionnel** (amélioré)

### jitter.ps1
- **Refonte complète** de l'interface
- **Menu interactif** 3-questions
- **Analyse qualité professionnel** (4 niveaux)
- **Support paramétré** (-ComputerName, -Count, -BufferSize)
- **Code ~500% plus volumineux** (10KB vs 2KB)

### Recommandations
✅ Validez bien sur une VM avant push GitHub
✅ Documentez bien les nouvelles fonctionnalités
✅ Testez tous les modes (surtout AUTO COMPLET et Mass Gravel)
✅ Versionnez proprement (v2.1 ou v3.0 selon politique)