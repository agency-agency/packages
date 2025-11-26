# Quick Start Guide - QuickShell WebEngine COPR

Get started with QuickShell WebEngine in 5 minutes!

## 🚀 For Users

### Install from COPR

```bash
# Enable repository
sudo dnf copr enable agency-agency/web-shell

# Install QuickShell with WebEngine
sudo dnf install quickshell-webengine

# Install DankMaterialShell (optional)
sudo dnf install dms

# Install GameScope (recommended)
sudo dnf install gamescope
```

### Quick Test

```bash
# Create test QML file
cat > test.qml << 'EOF'
import QtQuick
import QtWebEngine

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    title: "QuickShell WebEngine Test"
    
    Component.onCompleted: {
        QtWebEngine.initialize()
    }
    
    WebEngineView {
        anchors.fill: parent
        url: "https://www.example.com"
    }
}
EOF

# Run it!
quickshell -c test.qml

# With GameScope for better performance
gamescope -w 800 -h 600 -f -- quickshell -c test.qml
```

**Expected result:** Browser window showing example.com

---

## 🔧 For Maintainers

### Setup COPR Repository

1. **Create COPR project:**
   - Go to https://copr.fedorainfracloud.org/
   - Login and click "New Project"
   - Name: `web-shell`
   - Owner: `agency-agency`
   - Chroots: Select Fedora 40, 41, Rawhide (x86_64)

2. **Add packages via COPR web interface:**

**Package 1: quickshell-webengine**
```
Name: quickshell-webengine
Clone URL: https://github.com/agency-agency/web-shell-copr
Committish: main
Subdirectory: quickshell-webengine
Spec File: quickshell-webengine.spec
Type: git
Method: make_srpm
```

**Package 2: dms**
```
Name: dms
Clone URL: https://github.com/agency-agency/web-shell-copr
Committish: main
Subdirectory: dms
Spec File: dms.spec
Type: git
Method: make_srpm
```

### Setup GitHub Repository

```bash
# Clone template
git clone https://github.com/agency-agency/web-shell-copr
cd web-shell-copr

# Configure Git
git config user.name "Your Name"
git config user.email "your@email.com"

# Add COPR secret to GitHub
# Settings → Secrets → Actions → New secret
# Name: COPR_CONFIG
# Value: (paste your ~/.config/copr content)
```

### First Build

```bash
# Trigger manual build
git commit --allow-empty -m "Initial build [build-webengine]"
git push

# Or use GitHub Actions UI
# Go to Actions tab → Build QuickShell WebEngine → Run workflow
```

### Monitor Build

- **GitHub Actions:** https://github.com/agency-agency/web-shell-copr/actions
- **COPR Dashboard:** https://copr.fedorainfracloud.org/coprs/agency-agency/web-shell/

---

## 🧪 For Developers

### Local Development Build

```bash
# Clone repository
git clone https://github.com/agency-agency/web-shell-copr
cd web-shell-copr/quickshell-webengine

# Install build dependencies
sudo dnf install -y \
    rpm-build rpmdevtools spectool \
    cmake ninja-build gcc-c++ \
    qt6-qtbase-devel qt6-qtwebengine-devel \
    qt6-qtwebchannel-devel

# Download sources
spectool -g -R quickshell-webengine.spec

# Build
rpmbuild -bb quickshell-webengine.spec

# Install
sudo dnf install ~/rpmbuild/RPMS/x86_64/quickshell-webengine-*.rpm
```

### Test Your Changes

```bash
# Create test application
mkdir ~/quickshell-test
cd ~/quickshell-test

cat > shell.qml << 'EOF'
import QtQuick
import QtWebEngine
import QtWebChannel

ApplicationWindow {
    visible: true
    width: 1200
    height: 800
    title: "QuickShell + React Test"
    
    Component.onCompleted: {
        QtWebEngine.initialize()
    }
    
    WebEngineView {
        id: webView
        anchors.fill: parent
        
        webChannel: WebChannel {
            id: channel
            registeredObjects: [backend]
        }
        
        url: "http://localhost:5173"  // Your Vite dev server
    }
    
    QtObject {
        id: backend
        WebChannel.id: "backend"
        
        signal dataUpdated(string json)
        
        function systemCall(command) {
            console.log("QML received:", command)
            // Handle system calls from web UI
            dataUpdated('{"status": "ok"}')
        }
    }
}
EOF

# Start your React dev server in another terminal
# cd your-react-app && npm run dev

# Run QuickShell
gamescope -f -- quickshell -c shell.qml
```

---

## 🔄 Update Workflow

### Automatic Updates

The repository checks for QuickShell updates every 6 hours. When a new version is found:

1. Update workflow tests patch compatibility
2. If patch applies: Auto-commits and triggers build
3. If patch fails: Creates GitHub issue

### Manual Update

```bash
# Check for updates manually
cd web-shell-copr
git pull

# If new QuickShell version available
cd quickshell-webengine
./scripts/regenerate-patch.sh 0.2.2  # new version

# Test patch
spectool -g quickshell-webengine.spec
rpmbuild -bp quickshell-webengine.spec

# If successful, commit
git add quickshell-webengine.patch quickshell-webengine.spec
git commit -m "quickshell-webengine: Update to 0.2.2 [build-webengine]"
git push
```

---

## 📊 Common Tasks

### Check Build Status

```bash
# Via CLI
copr-cli list-builds agency-agency/web-shell

# Via Web
# https://copr.fedorainfracloud.org/coprs/agency-agency/web-shell/builds/
```

### Manual Build Trigger

```bash
# Build specific package
copr-cli build-package agency-agency/web-shell \
    --name quickshell-webengine

# With commit message trigger
git commit -m "Fix: some change [build-webengine]"
git push
```

### View Logs

```bash
# Get build ID
BUILD_ID=12345

# View logs
copr-cli get-build-logs $BUILD_ID
```

### Test Before COPR

```bash
# Mock build (clean environment)
cd quickshell-webengine
rpmbuild -bs quickshell-webengine.spec
sudo mock -r fedora-40-x86_64 ~/rpmbuild/SRPMS/quickshell-webengine-*.src.rpm

# Results in:
# /var/lib/mock/fedora-40-x86_64/result/
```

---

## 🆘 Troubleshooting

### "Package not found"

```bash
# Refresh repository
sudo dnf clean all
sudo dnf makecache

# Check if repository enabled
dnf repolist | grep agency-agency
```

### "Patch failed to apply"

```bash
# Regenerate patch for new QuickShell version
cd quickshell-webengine
../scripts/regenerate-patch.sh <new-version>
```

### "WebEngine not working"

```bash
# Verify installation
rpm -q qt6-qtwebengine
ldd /usr/bin/quickshell | grep -i web

# Test import
qml -c 'import QtWebEngine; console.log("OK")'

# Enable debug output
export QT_LOGGING_RULES="qt.webengine*=true"
quickshell -c test.qml
```

### "Build failed in COPR"

```bash
# Get build details
copr-cli list-builds agency-agency/web-shell | grep failed

# View logs
copr-cli get-build <build-id>

# Common issues:
# - Missing BuildRequires in spec
# - Patch doesn't apply (upstream changed)
# - Network timeout during build
```

---

## 📚 Next Steps

- **Full Documentation:** See [README.md](../README.md)
- **Testing Guide:** See [docs/TESTING.md](../docs/TESTING.md)
- **Patch Maintenance:** See [docs/PATCH_MAINTENANCE.md](../docs/PATCH_MAINTENANCE.md)
- **Report Issues:** https://github.com/agency-agency/web-shell-copr/issues

---

## ⏱️ Time Estimates

| Task | Time |
|------|------|
| User installation | 2 minutes |
| COPR setup | 10 minutes |
| Local build test | 15 minutes |
| Full development setup | 30 minutes |
| Patch regeneration | 5 minutes |

---

**Questions?** Open an issue or check the full documentation!
