# VS Code Complete Setup

```
██████╗  ██████╗ ██╗  ██╗██╗  ██╗ █████╗ ███╗   ██╗███████╗
██╔══██╗██╔═══██╗██║ ██╔╝██║  ██║██╔══██╗████╗  ██║╚══███╔╝
██████╔╝██║   ██║█████╔╝ ███████║███████║██╔██╗ ██║  ███╔╝
██╔══██╗██║   ██║██╔═██╗ ██╔══██║██╔══██║██║╚██╗██║ ███╔╝
██║  ██║╚██████╔╝██║  ██╗██║  ██║██║  ██║██║ ╚████║███████╗
╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚══════╝
```

**Comprehensive VS Code Extension Installer & Configuration Manager**

Automasi lengkap untuk setup VS Code dengan extension management yang canggih, marketplace-style search, dan konfigurasi optimal untuk development environment.

---

## 🚀 Features

### 🔍 **Marketplace-Style Search**
- **Smart Search**: Cari extension berdasarkan nama, ID, atau deskripsi
- **Category Browsing**: Jelajahi extension berdasarkan kategori (AI, JavaScript, Python, dll.)
- **Popular Extensions**: Akses cepat ke top 10 extension terpopuler
- **Real-time Status**: Lihat status installed/not installed secara real-time

### 📦 **Extension Management**
- **Install Individual**: Install extension satu per satu dengan feedback
- **Batch Operations**: Install/uninstall multiple extensions sekaligus
- **Interactive Mode**: Pilih extension dengan sistem shopping cart
- **Auto Detection**: Deteksi otomatis extension yang sudah terinstall

### ⚙️ **Configuration Management**
- **Smart Settings**: Generate settings.json optimal untuk setiap extension
- **Keybinding Protection**: Pastikan Ctrl+A tetap untuk "Select All"
- **Theme Integration**: Konfigurasi tema dan UI secara otomatis
- **Language-Specific**: Pengaturan khusus untuk setiap bahasa pemrograman

### 🛡️ **Quality Assurance**
- **ShellCheck Compliant**: 100% code quality standards
- **Error Handling**: Penanganan error yang robust
- **Backup Support**: Backup otomatis konfigurasi existing
- **Validation**: Validasi setiap langkah instalasi

---

## 📋 Requirements

- **OS**: Linux, macOS, Windows (dengan WSL/Git Bash)
- **VS Code**: Visual Studio Code harus sudah terinstall
- **Shell**: Bash 4.0+
- **Tools**: `curl`, `grep`, `cut` (biasanya sudah tersedia)

---

## 🔧 Installation

### Method 1: Direct Run
```bash
# Download dan jalankan langsung
chmod +x vscode-complete-setup.sh
./vscode-complete-setup.sh
```

### Method 2: Clone Repository
```bash
# Clone repository
git clone https://github.com/rokhanz/vscode-installer.git
cd vscode-installer

# Make executable dan run
chmod +x vscode-complete-setup.sh
./vscode-complete-setup.sh
```

---

## 🎮 Usage Guide

### 🏠 Main Menu

Setelah menjalankan script, Anda akan melihat menu utama:

```
🎯 Menu Utama VS Code Complete Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. 📦 Install Extensions
2. 🗑️  Uninstall Extensions
3. 🔍 Search Extensions
4. 🔧 Manage Settings.json
5. 🚪 Exit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1. 📦 Install Extensions

#### **Default Mode (Otomatis)**
```bash
# Pilih: 1 → 1
# Install otomatis extension populer untuk development
```

**Extensions yang diinstall secara default:**
- Python development stack
- JavaScript/TypeScript tools
- Git integration
- Code formatters & linters
- Themes & UI enhancements

#### **Interactive Mode**
```bash
# Pilih: 1 → 2
# Shopping cart system untuk memilih extension
```

### 2. 🗑️ Uninstall Extensions

#### **Smart Detection**
```bash
# Pilih: 2
# Otomatis detect extension terinstall dan kategorikan
```

### 3. 🔍 Search Extensions

#### **Keyword Search**
```bash
# Pilih: 3 → ketik keyword
# Contoh: "python", "git", "theme", "javascript"
```

**Actions pada hasil search:**
- **Ketik nomor**: Manage extension (install/uninstall)
- **`install 2`**: Install extension nomor 2 langsung
- **`uninstall 3`**: Uninstall extension nomor 3 langsung
- **`info 1`**: Lihat detail extension nomor 1

#### **Browse by Category**
```bash
# Pilih: 3 → 2
# Jelajahi 9 kategori extension
```

**Available Categories:**
1. 🤖 AI & Machine Learning
2. 💻 JavaScript & Node.js
3. 🐍 Python Development
4. 🌐 Web Development
5. 🔤 Other Languages
6. ✏️ Editor Enhancements
7. 🎨 Themes & UI
8. 🔧 DevOps & Tools
9. 📊 Data & Database

#### **Popular Extensions**
```bash
# Pilih: 3 → 3
# Lihat top 10 extension terpopuler
```

### 4. 🔧 Manage Settings.json

#### **Create Default Settings**
```bash
# Pilih: 4 → 1
# Generate settings.json optimal
```

#### **Advanced Configuration**
```bash
# Pilih: 4 → 6
# Konfigurasi lanjutan per extension
```

---

## 🎯 Quick Start Examples

### 💡 **Scenario 1: Python Developer Setup**
```bash
# Run script
./vscode-complete-setup.sh

# Quick setup
1 → 1  # Install default extensions (includes Python stack)

# Custom search untuk Python tools
3 → "python" → pilih extension tambahan

# Configure settings
4 → 1  # Generate optimal settings
```

### 💡 **Scenario 2: JavaScript Developer Setup**
```bash
# Custom JavaScript setup
3 → 2 → 2  # Browse JavaScript category
→ "install all"  # Install semua JavaScript tools

# Search untuk tools tambahan
3 → "react" → install extension React
```

### 💡 **Scenario 3: Full Stack Developer**
```bash
# Install popular extensions first
3 → 3 → "install all"  # Install top 10 extensions

# Add specific tools per language
3 → 2 → 3  # Python category → install needed
3 → 2 → 2  # JavaScript category → install needed
```

---

## 🛠️ Troubleshooting

### ❌ **Common Issues**

#### **"VS Code CLI not found"**
```bash
# Install VS Code CLI
# Through VS Code: Ctrl+Shift+P → "Shell Command: Install 'code' command in PATH"

# Manual (Linux/macOS):
sudo ln -s "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code
```

#### **"Permission denied"**
```bash
# Make script executable
chmod +x vscode-complete-setup.sh
```

#### **"Extension install failed"**
```bash
# Check VS Code is closed
# Check internet connection
# Try manual install:
code --install-extension extension.id
```

---

## 📊 Extension Categories

### 🤖 **AI & Machine Learning**
- GitHub Copilot
- Tabnine
- IntelliCode

### 💻 **JavaScript & Node.js**
- ES6+ syntax support
- React/Vue/Angular tools
- Node.js debugging

### 🐍 **Python Development**
- Python language server
- Jupyter notebooks
- Django/Flask support

### 🌐 **Web Development**
- HTML/CSS/SCSS tools
- Live Server
- Auto rename tag

### ✏️ **Editor Enhancements**
- Multi-cursor editing
- Bracket colorizers
- Indent guides

### 🎨 **Themes & UI**
- Popular color themes
- Icon themes
- Custom workbench themes

---

## 🤝 Contributing

### 📝 **Add New Extensions**
1. Fork repository
2. Edit `EXTENSION_INFO` array
3. Add ke appropriate category
4. Test dengan ShellCheck
5. Submit pull request

### 🐛 **Report Issues**
- Use GitHub Issues
- Include OS info
- Include error messages

---

## 📄 License

MIT License - feel free to use, modify, and distribute.

---

## 👨‍💻 Author

**ROKHANZ**
- GitHub: [@rokhanz](https://github.com/rokhanz)

---

## ⭐ Support

Jika project ini bermanfaat, berikan ⭐ star di GitHub!

**Happy coding! 🚀**
