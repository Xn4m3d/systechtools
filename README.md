# Just a Little System Tools Suite (v2.2.4) 🔧

**One-liner system maintenance suite for Windows**

## ⚡ Quick Start (Copy-Paste)

```powershell
iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/launcher.ps1')
```

That's it! No installation, no files, everything from memory.

---

## 📋 What You Get

### 1️⃣ **Maintenance System** (14 Options)
- Clean: Temp files, Windows cache, Print spooler, Recycle bin, Disk
- Repair: SFC, DISM, AppX packages
- Optimize: Defrag/TRIM, Event logs, Context menu, App export
- Custom: Multi-select your own maintenance

### 2️⃣ **Jitter Test**
- Network stability analyzer
- Check your connection quality
- Perfect for gaming/streaming diagnostics

### 3️⃣ **External Tools**
- MASS GRAVE ACTIVATION (Windows activation)
- WinUtil (Advanced optimization suite)

---

## 🚀 How to Launch

### Windows 10/11 - 3 Steps:

**1. Open PowerShell (Admin)**
- Right-click Start menu → PowerShell (Admin)
- OR: Win+X → PowerShell (Admin)
- OR: Win → Type "PowerShell" → Right-click → Run as admin

**2. Copy-Paste This:**
```powershell
iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/launcher.ps1')
```

**3. Press ENTER**

---

## 📊 Main Menu

```
1. Maintenance System Tools    - Clean & repair
2. Jitter Test                 - Network stability  
3. External Tools              - Activation & tweaks
0. Exit
```

---

## ✨ Features

- ✅ **No Installation** - Runs from memory
- ✅ **No Files** - Everything downloaded on-the-fly
- ✅ **Fast** - <1 second to start
- ✅ **Safe** - No dangerous operations
- ✅ **Free** - Open source
- ✅ **Easy** - Simple menu interface

---

## 🎯 Common Tasks

### Free Up Disk Space
```
Menu → 1 → 6 (Auto clean all) → Wait 1-2 min
Result: 1-10 GB freed
```

### Repair Unstable System
```
Menu → 1 → 10 (Auto repair all) → Wait 40-50 min
Result: Full Windows stability restored
```

### Check Internet
```
Menu → 2 (Jitter test) → Default settings
Result: Network quality analyzed
```

### Fix Right-Click Menu
```
Menu → 1 → 13 (Context menu) → Done
Result: Right-click works again
```

---

## 📚 Documentation

- **[USER-GUIDE-FR.md](USER-GUIDE-FR.md)** - Full user guide in French (detailed!)
- **[WEB-ARCHITECTURE.md](WEB-ARCHITECTURE.md)** - How it works (technical)
- **[FINAL-STRUCTURE.md](FINAL-STRUCTURE.md)** - Project structure

---

## ⌨️ Keyboard Navigation

| Key | Action |
|-----|--------|
| **1-3, 0** | Select option |
| **ENTER** | Confirm |
| **ESC** | Back/Exit |
| **ARROWS** (Auto mode) | Navigate |
| **SPACE** (Auto mode) | Check option |

---

## ⚠️ Important Notes

✅ **Do**:
- Plug in power (important!)
- Run as Administrator
- Close other apps
- Be patient (some tasks take time)

❌ **Don't**:
- Close PowerShell during operation
- Use PC while defragging HDD
- Close prematurely
- Ignore warnings

---

## 🐛 Troubleshooting

**"Script won't download"**
- Check internet connection
- Make sure GitHub isn't blocked

**"Access Denied"**
- Run PowerShell as Administrator

**"Execution policy error"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## 🔒 Security

- ✅ HTTPS only
- ✅ No credentials stored
- ✅ Open source (GitHub)
- ✅ No tracking
- ✅ User context only

---

## 📊 Stats

- **File Size**: ~35 KB (all modules)
- **Download Time**: <1 second
- **Memory Usage**: <100 MB
- **Lines of Code**: ~1000 (optimized)
- **Functions**: 22+
- **Supported OS**: Windows 7-11

---

## 💡 Pro Tip: Create Desktop Shortcut

Save this as `systechtools.bat` on your Desktop:

```batch
@echo off
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (New-Object Net.WebClient).DownloadString('https://raw.githubusercontent.com/Xn4m3d/systechtools/refs/heads/main/launcher.ps1')"
pause
```

Then just double-click to launch!

---

## 📞 Support

- 🐛 **Report bugs**: GitHub Issues
- 💡 **Suggestions**: GitHub Discussions
- 📖 **Documentation**: See files in repo

---

**Version**: 2.2.1  
**Status**: ✅ Production Ready  
**License**: MIT  
**Last Updated**: November 4, 2025