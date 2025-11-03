# SYSTECHTOOLS - Suite de Maintenance Système

Suite de scripts PowerShell pour la maintenance, le diagnostic et l'optimisation de systèmes Windows.

## Contenu

### Scripts Principaux

#### `menu-selector.ps1`
Menu centralisé pour exécuter les scripts disponibles sur le dépôt.
- Lance les autres scripts via GitHub RAW URLs
- Interface interactive avec numérotation
- Supporte l'exécution à distance

**Utilisation :**
```powershell
.\menu-selector.ps1
```

Ou en ligne de commande (téléchargement + exécution) :
```powershell
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1'))
```

#### `maintenance-system.ps1`
Script complet de maintenance système avec diagnostics et réparations.

**Fonctionnalités :**

**NETTOYAGE (5 options) :**
- Suppression fichiers temporaires (Temp, AppData, $env:TEMP)
- Vidage cache Windows Update
- Vidage corbeille
- Disk Cleanup (nettoyage approfondi)
- **AUTO NETTOYAGE** : Exécute tous les nettoyages

**REPARATION (3 options) :**
- SFC /scannow : Réparation fichiers système
- DISM RestoreHealth : Réparation image Windows
- **AUTO REPARATION** : Exécute toutes les réparations

**OPTIMISATION (2 options) :**
- Défragmentation/optimisation disque
- Vidage journaux d'événements (System, Application, Security)

**MODE AUTO COMPLET :**
- Exécute toutes les opérations en une seule commande
- Idéal pour diagnostiquer et réparer les PC problématiques

**Utilisation :**
```powershell
.\maintenance-system.ps1
```

Options du menu :
```
1 - Fichiers temporaires
2 - Cache Windows Update  
3 - Corbeille
4 - Disk Cleanup
5 - AUTO : Tous les nettoyages
6 - SFC (fichiers système)
7 - DISM (image Windows)
8 - AUTO : Toutes les réparations
9 - Défragmentation
10 - Journaux d'événements
11 - AUTO COMPLET (tout faire)
0 - Quitter
```

#### `jitter.ps1`
Script d'ajout de délai aléatoire avec gestion de la durée.

**Utilisation :**
```powershell
.\jitter.ps1
```

### Script de Configuration

#### `setup.ps1`
Générateur automatique du menu-selector.ps1.
- Scanne le dépôt pour les scripts disponibles
- Génère automatiquement les URLs GitHub RAW
- Crée un menu interactif fonctionnel

**Utilisation :**
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope CurrentUser
.\setup.ps1
```

## Installation

### Option 1 : Clonage Git
```bash
git clone https://github.com/Xn4m3d/systechtools.git
cd systechtools
```

### Option 2 : Téléchargement direct
Téléchargez les fichiers `.ps1` depuis le dépôt.

## Configuration requise

- **Windows 7/10/11 ou Server 2012+**
- **PowerShell 3.0+**
- **Privilèges administrateur** (pour la plupart des opérations)

## Exécution

### Mode Local
```powershell
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
.\menu-selector.ps1
```

### Mode Distant (GitHub)
```powershell
Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1'))
```

## Nouveautés - Version Actuelle

### Ajouts Récents
- ✅ Menu centralisé (menu-selector.ps1)
- ✅ Modes AUTO par catégorie
- ✅ Mode AUTO COMPLET pour diagnostics rapides
- ✅ Défragmentation disque intégrée
- ✅ Vidage journaux d'événements
- ✅ Rapport de synthèse avec durée
- ✅ Meilleure gestion des erreurs

### Fonctionnalités Conservées
- ✅ Nettoyage fichiers temporaires
- ✅ Vidage cache Windows Update
- ✅ SFC et DISM
- ✅ Vérification privilèges administrateur
- ✅ Logs détaillés

## Amélioration de la Politique d'Exécution

### Résoudre "Cannot be loaded. The file is not digitally signed"

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

**Solution 3 (Ligne de commande) :**
```powershell
powershell -ExecutionPolicy Bypass -File ".\maintenance-system.ps1"
```

## Utilisation pour PC Problématiques

Exemple : PC avec beaucoup d'espace disque utilisé et problèmes système

```powershell
# 1. Charger le script
.\maintenance-system.ps1

# 2. Sélectionner option 11 pour AUTO COMPLET
# Cela va :
# - Nettoyer les fichiers temporaires
# - Vider le cache Windows Update
# - Vider la corbeille
# - Disk Cleanup
# - Réparation SFC
# - Réparation DISM
# - Défragmentation
# - Vidage des journaux

# 3. Attendre la fin (rapport affichera ce qui a été fait)
```

**Résultats attendus :**
- 5-50 GB libérés selon l'état du système
- Fichiers système réparés
- Disque optimisé
- Journal récapitulatif avec durée

## Développement

### Structure des Scripts
- Vérification privilèges admin au démarrage
- Fonctions utilitaires réutilisables
- Logging complèt pour diagnostics
- Gestion d'erreurs robuste

### Améliorations Futures
- Sauvegarde des rapports en fichier
- Export des logs en CSV
- Scheduling automatique
- Statistiques d'économies disque

## Support et Contribution

Pour signaler des bugs ou proposer des améliorations :
1. Créez une issue sur GitHub
2. Testez les scripts en environnement contrôlé
3. Proposez des pull requests

## Licence

Libre d'utilisation pour usage personnel et professionnel.

## Auteur

**Xn4m3d**  
GitHub: https://github.com/Xn4m3d/systechtools

## Notes de Sécurité

⚠️ **Important :**
- Ces scripts modifient le système - testez d'abord sur une machine de test
- Les modes AUTO exécutent des opérations substantielles sans confirmation
- Sauvegardez les données critiques avant utilisation
- Utilisez toujours depuis une console PowerShell en administrateur
- Les scripts téléchargés depuis GitHub sont d'abord examinés avant exécution

## Changelog

### v2.0 (Actuelle)
- Ajout menu-selector centralisé
- Modes AUTO pour nettoyage et réparation
- Mode AUTO COMPLET
- Défragmentation intégrée
- Vidage journaux d'événements
- Meilleure interface utilisateur
- Rapport de synthèse

### v1.0
- Scripts de base
- SFC et DISM
- Nettoyage fichiers temporaires
- Windows Update cleanup
