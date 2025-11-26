# DEPLOYMENT INSTRUCTIONS
# QuickShell WebEngine COPR Package

## 🎉 All Files Created Successfully!

Your complete COPR package repository is ready. Here's what to do next:

## 📦 What Was Created

```
quickshell-webengine-copr/
├── 📄 Core Documentation
│   ├── README.md                    ✅ Main documentation (comprehensive)
│   ├── QUICKSTART.md               ✅ 5-minute quick start
│   ├── PROJECT_SUMMARY.md          ✅ Complete package overview
│   └── .gitignore                  ✅ Git ignore rules
│
├── 📦 Package Files
│   ├── quickshell-webengine/
│   │   ├── quickshell-webengine.spec     ✅ RPM spec with WebEngine
│   │   └── quickshell-webengine.patch    ✅ CMake modifications
│   └── dms/
│       └── dms.spec                       ✅ DankMaterialShell spec
│
├── 🤖 Automation
│   ├── .copr/
│   │   └── Makefile                       ✅ COPR build automation
│   └── .github/workflows/
│       ├── build.yml                      ✅ Package building
│       └── update.yml                     ✅ Version checking
│
├── 🛠️ Tools
│   └── scripts/
│       └── regenerate-patch.sh            ✅ Patch regeneration script
│
└── 📚 Documentation
    ├── TESTING.md                         ✅ Comprehensive testing guide
    ├── PATCH_MAINTENANCE.md               ✅ Patch update procedures
    └── example-dms-config.qml             ✅ Example configuration
```

## 🚀 Deployment Steps

### Step 1: Create GitHub Repository

```bash
# Create new repository on GitHub: agency-agency/web-shell-copr
# Then:

cd quickshell-webengine-copr
git init
git add .
git commit -m "Initial commit: QuickShell WebEngine COPR package

- QuickShell with QtWebEngine support
- DankMaterialShell with React UI support
- GameScope-optimized architecture
- Automated COPR builds
- Complete documentation"

git branch -M main
git remote add origin https://github.com/agency-agency/web-shell-copr.git
git push -u origin main
```

### Step 2: Configure GitHub Secrets

1. Go to GitHub repository settings
2. Navigate to: **Settings → Secrets and variables → Actions**
3. Click **"New repository secret"**
4. Create secret:
   - **Name:** `COPR_CONFIG`
   - **Value:** (paste your COPR configuration)
   
   ```ini
   [copr-cli]
   login = your_username
   username = agency-agency
   token = your_very_long_token_here
   copr_url = https://copr.fedorainfracloud.org
   ```

Get your COPR token from: https://copr.fedorainfracloud.org/api/

### Step 3: Create COPR Project

1. Go to https://copr.fedorainfracloud.org/
2. Click **"New Project"**
3. Configure:
   - **Project name:** `web-shell`
   - **Owner:** Select `agency-agency` (or create organization first)
   - **Description:** "QuickShell with QtWebEngine support for web-based desktop shells"
   - **Instructions:** 
     ```
     sudo dnf copr enable agency-agency/web-shell
     sudo dnf install quickshell-webengine
     # For DankMaterialShell:
     sudo dnf install dms gamescope
     ```
   - **Chroots:** Select:
     - ☑ fedora-40-x86_64
     - ☑ fedora-41-x86_64
     - ☑ fedora-rawhide-x86_64
   - **Enable internet:** ☑ Yes
   - **Follow Fedora branching:** ☑ Yes

4. Click **"Create"**

### Step 4: Add Packages to COPR

#### Package 1: quickshell-webengine

1. In your COPR project, click **"Packages"** → **"New Package"** → **"SCM"**
2. Configure:
   ```
   Package name: quickshell-webengine
   Clone URL: https://github.com/agency-agency/web-shell-copr.git
   Committish: main
   Subdirectory: quickshell-webengine
   Spec File: quickshell-webengine.spec
   Type: git
   Method: make_srpm
   ```
3. Click **"Create Package"**

#### Package 2: dms

1. Click **"New Package"** → **"SCM"** again
2. Configure:
   ```
   Package name: dms
   Clone URL: https://github.com/agency-agency/web-shell-copr.git
   Committish: main
   Subdirectory: dms
   Spec File: dms.spec
   Type: git
   Method: make_srpm
   ```
3. Click **"Create Package"**

### Step 5: Trigger First Build

#### Option A: Via GitHub Actions (Recommended)

```bash
# Trigger build with commit message
git commit --allow-empty -m "Initial build [build-webengine]"
git push
```

Then monitor:
- GitHub Actions: https://github.com/agency-agency/web-shell-copr/actions
- COPR: https://copr.fedorainfracloud.org/coprs/agency-agency/web-shell/builds/

#### Option B: Via COPR Web Interface

1. Go to your COPR project
2. Click "Packages" → "quickshell-webengine" → "Rebuild"
3. Repeat for "dms" after quickshell-webengine succeeds

#### Option C: Via CLI

```bash
# Install copr-cli
sudo dnf install copr-cli

# Configure (paste your token)
copr-cli --config

# Build packages
copr-cli build-package agency-agency/web-shell \
    --name quickshell-webengine

# After quickshell-webengine succeeds:
copr-cli build-package agency-agency/web-shell \
    --name dms
```

### Step 6: Verify Deployment

```bash
# Enable repository
sudo dnf copr enable agency-agency/web-shell

# Check available packages
dnf list --available | grep -E "quickshell-webengine|dms"

# Install and test
sudo dnf install quickshell-webengine

# Test WebEngine
cat > test.qml << 'EOF'
import QtQuick
import QtWebEngine
QtObject {
    Component.onCompleted: {
        console.log("✅ WebEngine works!")
        Qt.quit()
    }
}
EOF

quickshell -c test.qml
```

**Expected output:** `✅ WebEngine works!`

## 🔄 Ongoing Maintenance

### Automatic Updates

GitHub Actions checks for new QuickShell versions every 6 hours:
- ✅ Detects new releases
- ✅ Tests patch compatibility
- ✅ Auto-commits and triggers build
- ✅ Creates issue if patch fails

### Manual Updates

When new QuickShell version released:

```bash
cd web-shell-copr/quickshell-webengine

# Regenerate patch
../scripts/regenerate-patch.sh 0.2.2  # new version

# Test locally
spectool -g quickshell-webengine.spec
rpmbuild -bp quickshell-webengine.spec

# If successful:
git add quickshell-webengine.patch quickshell-webengine.spec
git commit -m "quickshell-webengine: Update to 0.2.2 [build-webengine]"
git push
```

## 🧪 Testing Checklist

Before considering deployment complete:

- [ ] GitHub repository created and pushed
- [ ] COPR project created
- [ ] Both packages added to COPR
- [ ] GitHub Actions workflows active
- [ ] COPR secrets configured in GitHub
- [ ] First builds successful
- [ ] Packages installable
- [ ] WebEngine imports work
- [ ] Documentation accessible
- [ ] Update workflow scheduled

## 📊 Monitoring

### Build Status

Monitor at:
- **COPR Builds:** https://copr.fedorainfracloud.org/coprs/agency-agency/web-shell/builds/
- **GitHub Actions:** https://github.com/agency-agency/web-shell-copr/actions

### Email Notifications

COPR will email you when:
- Builds succeed/fail
- New builds start
- Packages are ready

Configure in COPR project settings.

## 🐛 Troubleshooting

### "Build failed in COPR"

```bash
# Check logs
copr-cli list-builds agency-agency/web-shell | head -20
copr-cli get-build <build-id>

# Common issues:
# - Missing dependencies (add to spec)
# - Patch doesn't apply (regenerate)
# - Network timeout (retry)
```

### "GitHub Actions not running"

```bash
# Verify workflows exist
ls -la .github/workflows/

# Check workflow runs
# Go to GitHub: Actions tab

# Verify secrets configured
# Go to GitHub: Settings → Secrets → Actions
```

### "Patch failed to apply"

```bash
# Upstream CMakeLists.txt changed
cd quickshell-webengine
../scripts/regenerate-patch.sh <version>

# Test
spectool -g quickshell-webengine.spec
rpmbuild -bp quickshell-webengine.spec
```

## 📚 Documentation

All documentation is ready:

1. **For Users:**
   - [README.md](README.md) - Main documentation
   - [QUICKSTART.md](QUICKSTART.md) - Quick start

2. **For Developers:**
   - [docs/TESTING.md](docs/TESTING.md) - Testing procedures
   - [docs/example-dms-config.qml](docs/example-dms-config.qml) - Example config

3. **For Maintainers:**
   - [docs/PATCH_MAINTENANCE.md](docs/PATCH_MAINTENANCE.md) - Patch updates
   - [scripts/regenerate-patch.sh](scripts/regenerate-patch.sh) - Automation script

## ✅ Success Criteria

You'll know deployment is successful when:

1. ✅ COPR builds show "succeeded"
2. ✅ `sudo dnf copr enable agency-agency/web-shell` works
3. ✅ `sudo dnf install quickshell-webengine` works
4. ✅ WebEngine imports function in QML
5. ✅ GitHub Actions runs automatically
6. ✅ Update workflow checks for new versions

## 🎯 Next Steps

After successful deployment:

1. **Test DMS integration:**
   ```bash
   sudo dnf install dms gamescope
   gamescope -f -- quickshell -c /etc/xdg/quickshell/dms/shell.qml
   ```

2. **Create your web-based shell:**
   - Start with `docs/example-dms-config.qml`
   - Build React UI with Material 3
   - Use QtWebChannel bridge
   - Deploy with GameScope

3. **Share with community:**
   - Announce on QuickShell Discord/forums
   - Create demo video
   - Write blog post
   - Share on Reddit/HackerNews

## 🎉 You're Done!

Your QuickShell WebEngine COPR package is now:
- ✅ Built and tested
- ✅ Deployed to COPR
- ✅ Automatically maintained
- ✅ Fully documented
- ✅ Ready for production

**Congratulations! Now go build amazing web-based desktop shells! 🚀**

---

**Need Help?**
- Open GitHub issue
- Check documentation
- Review test logs
- Ask in QuickShell community

**Time to complete:** ~30 minutes (including COPR build time)
