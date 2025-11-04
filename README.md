# 🔧 Maintenance Système v2.2 - Guide Complet

Un script PowerShell professionnel pour optimiser et maintenir votre système Windows. Navigation au clavier, multi-sélection et mode personnalisé.

---

## 📋 Table des Matières

- [Installation](#installation)
- [Utilisation](#utilisation)
- [Options Détaillées](#options-détaillées)
- [Mode Auto Personnalisé](#mode-auto-personnalisé)
- [FAQ](#faq)

---

## 🚀 Installation

### Prérequis
- Windows 7+ (recommandé Windows 10/11)
- Droits administrateur
- PowerShell 5.0+

### Lancement
```powershell
# Télécharger le script
# Clic droit → Exécuter avec PowerShell
# OU en PowerShell Admin:
.\maintenance-system.ps1
```

**Attention**: Le script demandera automatiquement les droits admin s'il ne les possède pas.

---

## 📖 Utilisation

### Navigation
- **Flèches ↑↓**: Naviguer entre les options
- **Entrée**: Sélectionner une option
- **Espace**: Cocher/Décocher (en mode multi-sélection)
- **ESC**: Annuler (en mode multi-sélection)

### Écrans Principaux

**Menu Principal**
```
Choisissez une option (0-17)
```

**Mode Auto Personnalisé (Option 17)**
```
Navigation: FLECHES ↑↓ | Selection: ESPACE | Valider: ENTREE | Annuler: ESC
```

---

## 🔍 Options Détaillées

### 🟢 NETTOYAGE

#### **Option 1: Fichiers temporaires**
**Action**: Supprime tous les fichiers temporaires
- Vide `C:\Windows\Temp\*`
- Vide `C:\Users\*\AppData\Local\Temp\*`
- Vide `%TEMP%\*`

**Espace libéré**: Généralement 100 MB à 5 GB

---

#### **Option 2: Cache Windows Update**
**Actions**:
1. Arrête les services Windows Update (wuauserv, bits)
2. Vide le cache `C:\Windows\SoftwareDistribution\*`
3. Redémarre les services

**Espace libéré**: Généralement 100 MB à 2 GB

**Durée**: ~30 secondes

---

#### **Option 3: Spool Imprimante**
**Actions**:
1. Arrête le service Spooler
2. Vide `C:\Windows\System32\spool\PRINTERS\*`
3. Redémarre le service Spooler

**Utilité**: Répare les problèmes d'impression, libère de l'espace

**Espace libéré**: Généralement 10 MB à 500 MB

---

#### **Option 4: Corbeille**
**Action**: Vide complètement la corbeille Windows

**Espace libéré**: Variable selon contenu

**Durée**: Quelques secondes

---

#### **Option 5: Disk Cleanup**
**Actions**: Nettoie les répertoires système non essentiels
- Vide `C:\Windows\Prefetch\*`
- Vide `C:\Windows\System32\dllcache\*`
- Vide `C:\ProgramData\Package Cache\*`

**Espace libéré**: Généralement 50 MB à 1 GB

---

#### **Option 6: AUTO - Tous les nettoyages**
**Actions**: Exécute automatiquement les options 1 + 2 + 3 + 4 + 5

**Durée totale**: ~1-2 minutes

**Espace libéré total**: Généralement 500 MB à 10 GB

---

### 🔧 RÉPARATION

#### **Option 7: SFC (Réparation fichiers)**
**Action**: Lance `sfc /scannow` (System File Checker)
- Scanne les fichiers système
- Répare les fichiers corrompus automatiquement
- Nécessite une connexion Internet

**Durée**: 15-30 minutes ⏱️

**Impact**: Critique pour la stabilité Windows

---

#### **Option 8: DISM (Réparation image)**
**Actions**:
1. Lance `DISM /Online /Cleanup-Image /RestoreHealth`
2. Lance `DISM /Online /Cleanup-Image /StartComponentCleanup`

**Utilité**: Répare l'image Windows complète

**Durée**: 10-20 minutes

**Impact**: Corrige les problèmes profonds de Windows

---

#### **Option 9: Packages AppX**
**Action**: Répare tous les packages Microsoft (Store, Mail, etc.)

**Utilité**: Répare les applications Windows cassées

**Durée**: 2-5 minutes

---

#### **Option 10: AUTO - Toutes les réparations**
**Actions**: Exécute automatiquement les options 7 + 8 + 9

**Durée totale**: 30-50 minutes ⏱️

**Impact**: Restaure la stabilité complète de Windows

---

### ⚡ OPTIMISATION

#### **Option 11: Defrag/TRIM**
**Actions**:
- **Pour SSD**: Lance TRIM (optimisation SSD)
- **Pour HDD**: Lance défragmentation complète

**Détection automatique** du type de disque

**Durée SSD**: ~2-5 minutes

**Durée HDD**: ~30-60 minutes

**Impact**: Améliore les performances de 10-30%

---

#### **Option 12: Journaux d'événements**
**Actions**: Vide les journaux Windows
- Vide le journal "System"
- Vide le journal "Application"
- Vide le journal "Security"

**Espace libéré**: Généralement 50 MB à 500 MB

**Durée**: ~5 secondes

---

#### **Option 13: Menu contextuel**
**Actions**:
1. Répare la clé de registre du menu clic droit
2. Redémarre l'Explorateur Windows

**Utilité**: Répare les problèmes "Envoyer vers", clics droits cassés

**Durée**: ~5 secondes

---

#### **Option 14: Export applications**
**Action**: Exporte la liste de toutes les applications installées

**Sortie**: Fichier `liste_applications.txt` sur le Bureau

**Utilité**: Sauvegarde les logiciels installés, utile pour réinstallation

---

### 🔴 OUTILS EXTERNES

#### **Option 15: MASS GRAVE ACTIVATION**
**Action**: Lance l'outil d'activation Windows MASS GRAVE
- Télécharge et exécute depuis Internet
- S'ouvre dans une nouvelle fenêtre PowerShell

**Utilité**: Active Windows (pour versions non activées)

**Note**: Outils tiers - À utiliser à vos risques

---

#### **Option 16: WinUtil**
**Action**: Lance WinUtil - Suite complète d'optimisation Windows
- Télécharge depuis christitus.com
- S'ouvre dans une nouvelle fenêtre PowerShell

**Utilité**: Interface graphique pour optimisation avancée

---

### 🎯 MODE PERSONNALISÉ

#### **Option 17: AUTO PERSONNALISE**
**Fonctionnalité**: Menu multi-sélection pour choisir vos actions

**Actions disponibles dans ce mode**:
1. Fichiers temporaires
2. Cache Windows Update
3. Spool Imprimante
4. Corbeille
5. Disk Cleanup
6. SFC (Réparation fichiers)
7. DISM
8. AppX
9. Defrag/TRIM
10. Journaux d'événements

**Note**: Les options 13 (Menu) et 14 (Export) ne sont PAS disponibles en mode auto (lancez-les individuellement)

**Flux**:
1. Sélectionner option 17
2. Cocher les actions avec ESPACE
3. Valider avec ENTREE
4. Confirmer les actions longues (SFC, MASS GRAVE, WinUtil)
5. Lancement automatique

---

### ⏹️ CONTRÔLE

#### **Option 0: Quitter**
**Action**: Génère un rapport final et quitte le script

**Rapport affiche**:
- ✓ Actions effectuées
- ✗ Erreurs rencontrées
- ⏱️ Durée totale d'exécution

---

## 🔄 Mode Auto Personnalisé - Guide Détaillé

### Sélection
```
Navigation: FLECHES ↑↓ | Selection: ESPACE | Valider: ENTREE | Annuler: ESC

► [ ] 1. Fichiers temporaires
  [ ] 2. Cache Windows Update
  [✓] 3. Spool Imprimante
  ...

Selectionnees: 1 option(s)
```

### Pré-Configuration
Avant le lancement, le script demande confirmation pour:
- **Option 7 (SFC)**: "Duree: 15-30 minutes - Confirmer? (O/N)"
- **Option 15 (MASS GRAVE)**: "Activation Windows - Confirmer? (O/N)"
- **Option 16 (WinUtil)**: "Interface graphique - Confirmer? (O/N)"

### Lancement
Les actions s'exécutent automatiquement, le rapport final s'affiche à la fin.

---

## 📊 Gains Typiques

### Espace libéré
- **Nettoyage complet**: 1-10 GB
- **Après DISM**: 2-5 GB supplémentaires
- **Après Defrag**: Pas d'espace mais +10-30% vitesse

### Temps
- **Nettoyage complet**: 2-3 minutes
- **Réparation complète**: 50-60 minutes
- **Optimisation disque**: 30-120 minutes (selon taille)

---

## ❓ FAQ

### Q: Le script nécessite les droits admin?
**A**: Oui, tous les droits admin sont nécessaires. Le script les demande automatiquement au démarrage.

### Q: Puis-je annuler en cours d'exécution?
**A**: Non, une fois lancée, une action se poursuit. Mais chaque action est indépendante.

### Q: Les données seront-elles supprimées?
**A**: Seulement les fichiers temporaires et caches. Les données utilisateur ne sont jamais touchées.

### Q: Combien d'espace vais-je libérer?
**A**: Entre 500 MB et 20 GB selon votre système. Les mises à jour Windows prennent beaucoup d'espace.

### Q: Est-ce dangereux?
**A**: Non. Les actions sont sûres et recommandées par Microsoft. Les erreurs sont loggées.

### Q: Faut-il redémarrer après?
**A**: Pas obligatoire, mais recommandé après SFC ou DISM pour pleine efficacité.

### Q: SFC dit "intégrité partiellement intégrée"?
**A**: C'est normal si Windows ne peut réparer certains fichiers. Peut nécessiter une réinstallation Windows.

---

## 📝 Exemple d'Utilisation

```
Choisissez une option (0-17): 17

[Menu de sélection]
Navigation: FLECHES ↑↓ | Selection: ESPACE | Valider: ENTREE

► [ ] 1. Fichiers temporaires
  [ ] 2. Cache Windows Update
  [ ] 3. Spool Imprimante
  ...

[Appuyer ESPACE sur option 1]

► [✓] 1. Fichiers temporaires
  [ ] 2. Cache Windows Update

[Appuyer ENTREE pour valider]

╔════════════════════════════════════════════════════════════════╗
║           PRE-CONFIGURATION AVANT LANCEMENT                    ║
╚════════════════════════════════════════════════════════════════╝

Appuyez ENTREE pour lancer

═══════════════════════════════════════════════════════════════

1. NETTOYAGE FICHIERS TEMPORAIRES

OK Temp nettoy: 2.5 GB

[Fin]

Rapport Final:
✓ Actions: 1
  ├─ 1. Nettoyage Temp: 2.5 GB

Duree: 0m 15s
```

---

## 📞 Support

Pour les bugs, suggestions, ou améliorations:
- Ouvrir une issue sur GitHub
- Vérifier les logs dans le rapport final

---

## 📄 Licence

Licence publique - Libre d'utilisation

---

**Maintenance Système v2.2** - Optimisez votre Windows! 🚀