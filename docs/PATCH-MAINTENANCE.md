# Patch Maintenance Guide - QuickShell WebEngine

Guide for maintaining and regenerating the QuickShell WebEngine patch when upstream changes occur.

## 📋 Overview

The patch strategy allows us to:
- ✅ Track upstream QuickShell updates automatically
- ✅ Maintain minimal diff (only CMake changes)
- ✅ Avoid managing a full fork
- ✅ Easy contribution back to upstream

## 🔄 Patch Lifecycle

```
Upstream Update → Test Patch → Regenerate if Needed → Rebuild → Deploy
```

## 📦 Current Patch Contents

The `quickshell-webengine.patch` modifies only `CMakeLists.txt`:

1. **Adds WebEngine option** (~line 43)
   ```cmake
   option(WEBENGINE "Enable QtWebEngine support" OFF)
   ```

2. **Finds Qt6 WebEngine components** (~line 75)
   ```cmake
   if (WEBENGINE)
       find_package(Qt6 REQUIRED COMPONENTS WebEngineQuick WebChannel)
   endif()
   ```

3. **Links WebEngine libraries** (~line 258)
   ```cmake
   if (WEBENGINE)
       target_link_libraries(quickshell-module PRIVATE
           Qt6::WebEngineQuick Qt6::WebChannel)
   endif()
   ```

## 🛠️ When to Regenerate

### Automatic Detection

The update workflow checks for new QuickShell versions. If the patch fails to apply:

```bash
# GitHub Actions will show error:
# "patch: **** malformed patch at line XX"
```

### Manual Check

```bash
# Download new QuickShell version
VERSION=0.2.2  # example
wget https://github.com/quickshell-mirror/quickshell/archive/v${VERSION}.tar.gz
tar xzf v${VERSION}.tar.gz
cd quickshell-${VERSION}

# Test if patch applies
patch -p1 --dry-run < ../quickshell-webengine.patch

# Exit code 0 = success, 1 = failure
echo $?
```

## 🔧 Regeneration Process

### Method 1: Automated Script

Create `scripts/regenerate-patch.sh`:

```bash
#!/bin/bash
set -euo pipefail

VERSION=${1:-0.2.1}
UPSTREAM_URL="https://github.com/quickshell-mirror/quickshell"

echo "Regenerating patch for QuickShell $VERSION"

# Clean workspace
rm -rf /tmp/quickshell-patch
mkdir -p /tmp/quickshell-patch
cd /tmp/quickshell-patch

# Download upstream source
echo "Downloading upstream..."
wget "${UPSTREAM_URL}/archive/v${VERSION}.tar.gz"
tar xzf v${VERSION}.tar.gz

# Create two copies
cp -r quickshell-${VERSION} quickshell-${VERSION}-original
cp -r quickshell-${VERSION} quickshell-${VERSION}-patched

cd quickshell-${VERSION}-patched

# Apply modifications
echo "Applying WebEngine modifications..."

# Modification 1: Add WEBENGINE option
sed -i '/^option(SERVICE/a option(WEBENGINE "Enable QtWebEngine support" OFF)\n\n# QtWebEngine requires private Qt headers\nset(QT_FEATURE_webengine_private_includes ON)' CMakeLists.txt

# Modification 2: Add Qt6::Quick to find_package
sed -i '/find_package(Qt6 REQUIRED COMPONENTS/,/)/{ /Qml/a\	Quick }' CMakeLists.txt

# Modification 3: Add WebEngine find_package
sed -i '/pkg_check_modules(jemalloc/a\\nif (WEBENGINE)\n\tfind_package(Qt6 REQUIRED COMPONENTS WebEngineQuick WebChannel)\n\tadd_compile_definitions(QS_WEBENGINE_ENABLED)\n\tmessage(STATUS "QtWebEngine support: ENABLED")\nendif()' CMakeLists.txt

# Modification 4: Add WebEngine linking
sed -i '/target_link_libraries(quickshell-module PRIVATE/,/^)/{ /^)/i\\nif (WEBENGINE)\n\ttarget_link_libraries(quickshell-module PRIVATE\n\t\tQt6::WebEngineQuick Qt6::WebChannel)\nendif() }' CMakeLists.txt

# Generate patch
cd ..
diff -Naur quickshell-${VERSION}-original/CMakeLists.txt \
           quickshell-${VERSION}-patched/CMakeLists.txt \
           > quickshell-webengine-${VERSION}.patch || true

# Verify patch
echo "Verifying patch..."
cd quickshell-${VERSION}-original
patch -p1 --dry-run < ../quickshell-webengine-${VERSION}.patch

if [ $? -eq 0 ]; then
    echo "✅ Patch generated successfully!"
    echo "Location: /tmp/quickshell-patch/quickshell-webengine-${VERSION}.patch"
    echo ""
    echo "Next steps:"
    echo "1. Review the patch: cat /tmp/quickshell-patch/quickshell-webengine-${VERSION}.patch"
    echo "2. Copy to repo: cp /tmp/quickshell-patch/quickshell-webengine-${VERSION}.patch quickshell-webengine/"
    echo "3. Update spec Version: $VERSION"
    echo "4. Test build"
else
    echo "❌ Patch verification failed!"
    exit 1
fi
```

Make it executable:
```bash
chmod +x scripts/regenerate-patch.sh
```

Usage:
```bash
# Regenerate for new version
./scripts/regenerate-patch.sh 0.2.2

# Copy to repository
cp /tmp/quickshell-patch/quickshell-webengine-0.2.2.patch \
   quickshell-webengine/quickshell-webengine.patch
```

### Method 2: Manual Regeneration

#### Step 1: Prepare Sources

```bash
VERSION=0.2.2
cd /tmp
wget https://github.com/quickshell-mirror/quickshell/archive/v${VERSION}.tar.gz
tar xzf v${VERSION}.tar.gz

# Create two copies
cp -r quickshell-${VERSION} quickshell-${VERSION}-original
cp -r quickshell-${VERSION} quickshell-${VERSION}-modified
```

#### Step 2: Apply Modifications

```bash
cd quickshell-${VERSION}-modified
vim CMakeLists.txt
```

Make these changes manually:

1. **After `option(SERVICE ...)` line**, add:
   ```cmake
   option(WEBENGINE "Enable QtWebEngine support" OFF)
   
   # QtWebEngine requires private Qt headers
   set(QT_FEATURE_webengine_private_includes ON)
   ```

2. **In `find_package(Qt6 REQUIRED COMPONENTS` block**, add `Quick` after `Qml`

3. **After `pkg_check_modules(jemalloc ...)`**, add:
   ```cmake
   if (WEBENGINE)
       find_package(Qt6 REQUIRED COMPONENTS WebEngineQuick WebChannel)
       add_compile_definitions(QS_WEBENGINE_ENABLED)
       message(STATUS "QtWebEngine support: ENABLED")
   endif()
   ```

4. **After `target_link_libraries(quickshell-module PRIVATE` block**, add:
   ```cmake
   if (WEBENGINE)
       target_link_libraries(quickshell-module PRIVATE
           Qt6::WebEngineQuick Qt6::WebChannel)
   endif()
   ```

#### Step 3: Generate Patch

```bash
cd /tmp
diff -Naur quickshell-${VERSION}-original/CMakeLists.txt \
           quickshell-${VERSION}-modified/CMakeLists.txt \
           > quickshell-webengine.patch
```

#### Step 4: Verify Patch

```bash
# Test on clean source
cd quickshell-${VERSION}-original
patch -p1 --dry-run < ../quickshell-webengine.patch

# Should output:
# checking file CMakeLists.txt
# (no errors)
```

#### Step 5: Integrate into Repository

```bash
# Copy patch
cp /tmp/quickshell-webengine.patch \
   ~/web-shell-copr/quickshell-webengine/

# Update spec file version
cd ~/web-shell-copr/quickshell-webengine
sed -i "s/^Version:.*/Version:            ${VERSION}/" quickshell-webengine.spec

# Update changelog
DATE=$(date +"%a %b %d %Y")
sed -i "/%changelog/a * $DATE Agency <maintainer@agency-agency.dev> - ${VERSION}-1\n- Update to QuickShell ${VERSION}\n- Regenerated patch for upstream changes" quickshell-webengine.spec
```

## 🧪 Testing Regenerated Patch

### Quick Test

```bash
cd quickshell-webengine
spectool -g quickshell-webengine.spec
rpmbuild -bp quickshell-webengine.spec

# Check if patch applied
ls ~/rpmbuild/BUILD/quickshell-*/CMakeLists.txt
grep "WEBENGINE" ~/rpmbuild/BUILD/quickshell-*/CMakeLists.txt
```

### Full Test

```bash
# Build package
rpmbuild -bb quickshell-webengine.spec

# Install and test
sudo dnf install ~/rpmbuild/RPMS/x86_64/quickshell-webengine-*.rpm

# Run WebEngine test
cat > test.qml << 'EOF'
import QtQuick
import QtWebEngine

QtObject {
    Component.onCompleted: {
        console.log("WebEngine OK")
        Qt.quit()
    }
}
EOF

quickshell -c test.qml
```

## 🔍 Troubleshooting

### Patch Applies with Fuzz

```bash
# Warning like:
# Hunk #1 succeeded at 45 with fuzz 2.

# This means line numbers changed but content matched
# Regenerate patch to remove fuzz:
./scripts/regenerate-patch.sh <VERSION>
```

### Patch Fails Completely

```bash
# Error like:
# patch: **** malformed patch at line 15

# Check if CMakeLists.txt structure changed significantly
cd quickshell-${VERSION}
grep -n "option(SERVICE" CMakeLists.txt  # Find where to add WEBENGINE
grep -n "find_package(Qt6" CMakeLists.txt  # Find where to add WebEngine
grep -n "target_link_libraries" CMakeLists.txt  # Find where to link
```

**Common upstream changes:**
1. New options added → Adjust line numbers
2. find_package reorganized → Update patch context
3. Target names changed → Update library linking section

### Patch Creates Build Errors

```bash
# Patch applied but build fails
# Check CMake configuration
rpmbuild -bc quickshell-webengine.spec
cat ~/rpmbuild/BUILD/quickshell-*/build.log | grep -A 10 "WEBENGINE"

# Common issues:
# - Missing components in find_package
# - Wrong target name in link_libraries
# - Circular dependencies
```

## 📊 Patch Quality Checklist

Before committing regenerated patch:

- [ ] Patch applies cleanly (no fuzz, no errors)
- [ ] Only modifies CMakeLists.txt (no other files)
- [ ] Changes are minimal (< 50 lines)
- [ ] All hunks make sense contextually
- [ ] Build succeeds with patch applied
- [ ] WebEngine imports work at runtime
- [ ] No regression in base QuickShell functionality

## 🤖 Automated Monitoring

The GitHub Actions update workflow will:

1. **Check for new versions** (every 6 hours)
2. **Test patch application** automatically
3. **Create issue** if patch fails
4. **Notify maintainers**

### Workflow Behavior

```yaml
# In .github/workflows/update.yml

- name: Test patch
  run: |
    cd quickshell-webengine
    spectool -g quickshell-webengine.spec
    rpmbuild -bp quickshell-webengine.spec || {
        echo "PATCH_FAILED=true" >> $GITHUB_ENV
    }

- name: Create issue if patch fails
  if: env.PATCH_FAILED == 'true'
  uses: actions/github-script@v6
  with:
    script: |
      github.rest.issues.create({
        owner: context.repo.owner,
        repo: context.repo.repo,
        title: 'Patch failed for QuickShell ${{ env.VERSION }}',
        body: 'The patch needs regeneration...'
      })
```

## 📚 Reference

### Patch Format

```diff
--- a/CMakeLists.txt
+++ b/CMakeLists.txt
@@ -40,6 +40,10 @@ option(WAYLAND "Enable wayland support" ON)
 option(WAYLAND_WLR_LAYERSHELL "Support zwlr_layer_shell_v1" ON)
 option(SOCKETS "Enable socket server" ON)
 option(SERVICE "Enable service" ON)
+option(WEBENGINE "Enable QtWebEngine support" OFF)
```

- `-` lines removed
- `+` lines added
- `@@` hunk headers (line numbers)

### Useful Commands

```bash
# Show patch statistics
diffstat quickshell-webengine.patch

# Validate patch format
lsdiff quickshell-webengine.patch

# Apply patch with verbose output
patch -p1 -v < quickshell-webengine.patch

# Reverse a patch
patch -p1 -R < quickshell-webengine.patch

# Check which files a patch modifies
lsdiff quickshell-webengine.patch
```

## 🚀 Future Improvements

1. **Automated patch regeneration** via GitHub Actions
2. **Upstream contribution** of WebEngine option
3. **Version-specific patches** if needed
4. **Patch bisecting** for regression debugging

## 🤝 Contributing Upstream

Once stable, consider upstreaming:

```bash
# Fork QuickShell
git clone https://github.com/your-fork/quickshell
cd quickshell

# Create feature branch
git checkout -b feature/webengine-support

# Apply our changes manually (cleaner than patch)
# ... edit CMakeLists.txt ...

# Commit
git add CMakeLists.txt
git commit -m "Add optional QtWebEngine support

This adds a CMake option to build QuickShell with QtWebEngine
and QtWebChannel support, enabling web-based UI components.

Benefits:
- Optional feature (disabled by default)
- Enables React/Vue/Angular UIs in QuickShell
- Works with GameScope for GPU acceleration
- Minimal changes to build system"

# Push and create PR
git push origin feature/webengine-support
```

---

**Maintenance Schedule**: Check patch compatibility after each QuickShell release
