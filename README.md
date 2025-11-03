# 🛠️ systechtools

> **Collection de scripts PowerShell pour la maintenance et le diagnostic système** | Hébergé sur GitHub RAW avec exécution distante

---

## 📋 Table des matières

- [🚀 Démarrage rapide](#-démarrage-rapide)
- [📦 Scripts disponibles](#-scripts-disponibles)
- [🎯 Fonctionnalités](#-fonctionnalités)
- [💾 Installation](#-installation)
- [🔧 Utilisation](#-utilisation)
- [📊 Exemples](#-exemples)
- [⚙️ Configuration](#-configuration)
- [📝 Licence](#-licence)

---

## 🚀 Démarrage rapide

### Une seule commande pour tout lancer :

```powershell
iwr 'https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1' -UseBasicParsing | iex
```

**⚠️ Exécutez PowerShell en tant qu'administrateur**

---

## 📦 Scripts disponibles

### 1️⃣ **menu-selector.ps1** 🎯 Le Hub Central

| Aspect | Détails |
|--------|---------|
| **Fonction** | Gestionnaire de scripts avec interface interactive |
| **Utilité** | Point d'entrée unique pour tous les outils |
| **Privilèges** | Admin recommandé |
| **Taille** | ~3.5 KB |
| **Temps exec** | < 1 sec |

**Caractéristiques :**
- ✅ Interface élégante avec bannière
- ✅ Menu interactif intuitif
- ✅ Descriptions détaillées des scripts
- ✅ Gestion des erreurs robuste
- ✅ Exécution sécurisée en local

---

### 2️⃣ **maintenance-system.ps1** 🔧 Diagnostic & Réparation

| Aspect | Détails |
|--------|---------|
| **Fonction** | Maintenance système complète |
| **Utilité** | Diagnostics, réparations, nettoyage |
| **Privilèges** | **Admin obligatoire** |
| **Taille** | ~20 KB |
| **Temps exec** | 5-60 min (selon options) |

**3 Sections principales :**

**Diagnostics 📊**
- Santé disque dur (SMART)
- Espace disque disponible
- Services critiques Windows
- Utilisation mémoire RAM

**Réparations 🔨**
- DISM Image Health Restore
- SFC (System File Check)
- Vérification intégrité fichiers système

**Nettoyage 🧹**
- Vidage fichiers temporaires
- Cache Windows Update
- Espace disque libéré

---

### 3️⃣ **jitter.ps1** 🌐 Analyseur Réseau

| Aspect | Détails |
|--------|---------|
| **Fonction** | Mesure de latence et stabilité réseau |
| **Utilité** | Diagnostic connexion internet |
| **Privilèges** | Utilisateur standard |
| **Taille** | ~6.5 KB |
| **Temps exec** | 2-5 min |

**Mesures effectuées :**
- 🎯 Latence moyenne (ping)
- 📊 Jitter (écart-type)
- 📈 Min/Max latence
- 🎮 Évaluation qualité (gaming, vidéo, etc)

---

## 🎯 Fonctionnalités

### ✨ Avantages principaux

```
┌─────────────────────────────────────────┐
│  🌍 Accès distant        │  GitHub RAW  │
│  🔒 Sécurisé             │  HTTPS       │
│  ⚡ Rapide               │  < 1 sec     │
│  🎨 Interface moderne    │  Bannières   │
│  👤 Multi-utilisateur    │  Interactif  │
│  📱 Responsive           │  Tous OS     │
└─────────────────────────────────────────┘
```

### 🔐 Sécurité

- ✅ Pas de données sensibles
- ✅ Pas de chemins hardcodés
- ✅ Vérification admin automatique
- ✅ Téléchargement sécurisé HTTPS
- ✅ Exécution temporaire (fichiers supprimés)

---

## 💾 Installation

### Option 1 : Exécution Directe (Recommandée)

**Aucune installation requise !** Copie/colle simplement :

```powershell
# Ouvrir PowerShell en tant qu'Admin
iwr 'https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1' -UseBasicParsing | iex
```

### Option 2 : Cloner le Repo

```powershell
# Si vous voulez tous les fichiers localement
git clone https://github.com/Xn4m3d/systechtools.git
cd systechtools

# Puis exécuter
.\menu-selector.ps1
```

### Option 3 : Téléchargement Manuel

1. Aller sur [GitHub Releases](https://github.com/Xn4m3d/systechtools/releases)
2. Télécharger les scripts
3. Exécuter `menu-selector.ps1`

---

## 🔧 Utilisation

### Workflow Principal

```
┌──────────────────────────────────────┐
│  Exécuter menu-selector.ps1          │
└──────────────────┬───────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
        ▼          ▼          ▼
   [1] jitter  [2] maint.  [0] Quitter
   [2] maint.  [3] répar.
   [3] autre   [4] nettoyer
```

### Exemples de Commande

#### 🌐 Tester la latence (défaut)

```powershell
.\jitter.ps1
# Lance le menu interactif
```

#### 🌐 Tester une adresse spécifique

```powershell
.\jitter.ps1 -ComputerName "8.8.8.8" -Count 50 -BufferSize 1250
```

#### 🔧 Lancer la maintenance

```powershell
.\maintenance-system.ps1
# Menu interactif avec 8 options
```

#### 🚀 Tout depuis le menu central

```powershell
.\menu-selector.ps1
# Interface unifiée
```

---

## 📊 Exemples

### Exemple 1 : Diagnostic Complet

```powershell
# Commande
iwr 'https://..../menu-selector.ps1' -UseBasicParsing | iex

# Résultat
╔════════════════════════════════════════════════════════════════╗
║             🛠️  GESTIONNAIRE DE SCRIPTS SYSTÈME               ║
╚════════════════════════════════════════════════════════════════╝

📋 SCRIPTS DISPONIBLES
═══════════════════════════════════════════════════════════════

  1. jitter                    (6.5 KB)
     └─ Analyseur de latence réseau et jitter

  2. maintenance-system        (20 KB)
     └─ Diagnostic et maintenance système complète

  0. QUITTER

═══════════════════════════════════════════════════════════════
Sélectionnez un script (0-2): 2
```

### Exemple 2 : Résultat Jitter

```
╔════════════════════════════════════════════════════════════════╗
║                     ✓ RÉSULTATS ANALYSE                        ║
╚════════════════════════════════════════════════════════════════╝

📊 STATISTIQUES
════════════════════════════════════════════════════════════════

  Hôte testé . . . . . . . . . . . . 8.8.8.8
  Pings réussis . . . . . . . . . . 100/100

  Latence moyenne . . . . . . . . . 25.45 ms
  Latence minimale . . . . . . . . . 24 ms
  Latence maximale . . . . . . . . . 28 ms

  Jitter (écart-type) . . . . . . . . 1.23 ms

📈 ANALYSE DE QUALITÉ
════════════════════════════════════════════════════════════════

  ✓ EXCELLENTE stabilité de connexion
    Votre connexion est très stable et fiable pour:
    • Jeux en ligne compétitifs
    • Appels vidéo/audio haute qualité
    • Transactions financières
```

---

## ⚙️ Configuration

### Variables d'environnement

```powershell
# Mode verbose (voir tous les détails)
$VerbosePreference = 'Continue'

# Exécution script
.\script.ps1 -ComputerName "google.com" -Count 100
```

### Paramètres personnalisés

#### jitter.ps1
- `-ComputerName` : Adresse IP ou nom d'hôte (défaut: 8.8.8.8)
- `-Count` : Nombre de pings (défaut: 100)
- `-BufferSize` : Taille données (défaut: 1250)

#### maintenance-system.ps1
- Menu interactif : Sélectionnez les options manuellement
- Support complet DISM et SFC

---

## 📋 Prérequis

| Élément | Exigence |
|---------|----------|
| **OS** | Windows 7+ (Win 10/11 recommandé) |
| **PowerShell** | v3.0+ |
| **Internet** | Connexion pour téléchargement RAW |
| **Privilèges** | Admin pour maintenance-system.ps1 |
| **Antivirus** | Aucun bloquage PowerShell |

---

## 🆘 Dépannage

### ❌ Erreur : "Accès refusé"

```powershell
# Solution : Ouvrir PowerShell en Admin
# Windows 10/11 : Win+X → Windows PowerShell (Admin)
# Windows 7 : Clic droit → Exécuter en tant qu'administrateur
```

### ❌ Erreur : "Impossible de télécharger"

```powershell
# Vérifier connexion internet
Test-NetConnection -ComputerName github.com -Port 443

# Vérifier proxy
[System.Net.ServicePointManager]::DefaultProxy
```

### ❌ Erreur : "Execution policy"

```powershell
# Solution temporaire
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Ou utiliser iex directement (déjà inclus)
```

---

## 📞 Support & Contribution

### Signaler un Bug

1. Ouvrir [GitHub Issues](https://github.com/Xn4m3d/systechtools/issues)
2. Décrire le problème
3. Joindre les logs/erreurs

### Contribuer

```bash
git clone https://github.com/Xn4m3d/systechtools.git
git checkout -b feature/mon-feature
git commit -am "Ajout: ma nouvelle fonctionnalité"
git push origin feature/mon-feature
```

---

## 📊 Statistiques

| Métrique | Valeur |
|----------|--------|
| Scripts | 3 |
| Taille totale | ~30 KB |
| Lignes de code | ~800 |
| Temps de réponse | < 1s |
| Support Windows | 7, 8, 10, 11 |
| Status | ✅ Production |

---

## 📝 Licence

MIT License - Libre d'utilisation

---

## 🎯 Feuille de route

- ✅ Menu central
- ✅ Diagnostic système
- ✅ Analyseur jitter
- 🔄 Monitoring temps réel
- 🔄 Interface web (beta)
- 🔄 Rapports PDF

---

## 💡 Conseils d'Utilisation

### Pour IT/Techniciens

1. **Avant intervention** : Lancer diagnostic complet
2. **Pendant maintenance** : Utiliser réparations ciblées
3. **Après nettoyage** : Relancer diagnostics pour vérifier

### Pour Utilisateurs

1. **Hebdomadaire** : Nettoyage fichiers temp
2. **Mensuel** : Diagnostic complet
3. **Au besoin** : Test latence réseau

---

## 🔗 Liens Utiles

- 🌐 [GitHub Repository](https://github.com/Xn4m3d/systechtools)
- 📚 [Documentation PowerShell](https://docs.microsoft.com/powershell/)
- 🐛 [Signaler un bug](https://github.com/Xn4m3d/systechtools/issues)
- ⭐ [Laisser une étoile](https://github.com/Xn4m3d/systechtools)

---

<div align="center">

### 🚀 Prêt à l'emploi !

Copie/colle la commande ci-dessous dans PowerShell (Admin)

```powershell
iwr 'https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/menu-selector.ps1' -UseBasicParsing | iex
```

**⭐ N'oublie pas de laisser une étoile sur GitHub !**

---

*Dernière mise à jour: 2025-11-03*  
*Version: 1.0 - Production Ready* ✅

</div>
