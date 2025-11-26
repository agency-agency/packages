#!/bin/bash
# Regenerate QuickShell WebEngine patch for new upstream versions
# Usage: ./regenerate-patch.sh [VERSION]

set -euo pipefail

VERSION=${1:-0.2.1}
UPSTREAM_URL="https://github.com/quickshell-mirror/quickshell"
WORKDIR="/tmp/quickshell-patch-$$"

echo "=================================="
echo "QuickShell WebEngine Patch Generator"
echo "=================================="
echo "Version: $VERSION"
echo "Upstream: $UPSTREAM_URL"
echo "=================================="

# Clean and create workspace
rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Download upstream source
echo ""
echo "[1/6] Downloading QuickShell v${VERSION}..."
if ! wget -q "${UPSTREAM_URL}/archive/v${VERSION}.tar.gz"; then
    echo "❌ Failed to download QuickShell v${VERSION}"
    echo "   Check if version exists: ${UPSTREAM_URL}/releases"
    exit 1
fi

echo "[2/6] Extracting source..."
tar xzf "v${VERSION}.tar.gz"

# Create two copies
cp -r "quickshell-${VERSION}" "quickshell-${VERSION}-original"
cp -r "quickshell-${VERSION}" "quickshell-${VERSION}-patched"

cd "quickshell-${VERSION}-patched"

echo "[3/6] Applying WebEngine modifications..."

# Check if CMakeLists.txt exists
if [ ! -f "CMakeLists.txt" ]; then
    echo "❌ CMakeLists.txt not found!"
    exit 1
fi

# Backup original
cp CMakeLists.txt CMakeLists.txt.backup

# Modification 1: Add WEBENGINE option after SERVICE option
if ! grep -q "option(SERVICE" CMakeLists.txt; then
    echo "❌ Could not find SERVICE option in CMakeLists.txt"
    echo "   Upstream structure may have changed"
    exit 1
fi

sed -i '/^option(SERVICE/a\
option(WEBENGINE "Enable QtWebEngine support" OFF)\
\
# QtWebEngine requires private Qt headers\
set(QT_FEATURE_webengine_private_includes ON)' CMakeLists.txt

# Modification 2: Add Qt6::Quick to find_package
# Find the find_package(Qt6 REQUIRED COMPONENTS block and add Quick after Qml
if ! grep -q "find_package(Qt6 REQUIRED COMPONENTS" CMakeLists.txt; then
    echo "❌ Could not find Qt6 find_package"
    exit 1
fi

# Add Quick after Qml line
sed -i '/find_package(Qt6 REQUIRED COMPONENTS/,/)/{
    /Qml/a\
\	Quick
}' CMakeLists.txt

# Modification 3: Add WebEngine find_package after jemalloc
if ! grep -q "pkg_check_modules(jemalloc" CMakeLists.txt; then
    echo "⚠️  Warning: jemalloc not found, adding WebEngine block anyway"
fi

sed -i '/pkg_check_modules(jemalloc/a\
\
if (WEBENGINE)\
\	find_package(Qt6 REQUIRED COMPONENTS WebEngineQuick WebChannel)\
\	add_compile_definitions(QS_WEBENGINE_ENABLED)\
\	message(STATUS "QtWebEngine support: ENABLED")\
endif()' CMakeLists.txt

# Modification 4: Add WebEngine linking after quickshell-module target_link_libraries
if ! grep -q "target_link_libraries(quickshell-module PRIVATE" CMakeLists.txt; then
    echo "❌ Could not find quickshell-module target_link_libraries"
    exit 1
fi

# Find the jemalloc_link line and add WebEngine block after it
sed -i '/jemalloc_link/a\
)\
\
if (WEBENGINE)\
\	target_link_libraries(quickshell-module PRIVATE\
\		Qt6::WebEngineQuick Qt6::WebChannel)' CMakeLists.txt

# Note: This might need adjustment based on actual CMakeLists.txt structure

echo "[4/6] Generating patch..."
cd "$WORKDIR"

# Generate unified diff
diff -Naur "quickshell-${VERSION}-original/CMakeLists.txt" \
           "quickshell-${VERSION}-patched/CMakeLists.txt" \
           > "quickshell-webengine-${VERSION}.patch" || true

# Check if patch was created
if [ ! -s "quickshell-webengine-${VERSION}.patch" ]; then
    echo "❌ Patch generation failed (empty file)"
    exit 1
fi

echo "[5/6] Verifying patch..."
cd "quickshell-${VERSION}-original"

if patch -p1 --dry-run --silent < "../quickshell-webengine-${VERSION}.patch" 2>&1; then
    echo "✅ Patch applies cleanly!"
else
    echo "❌ Patch verification failed!"
    echo ""
    echo "Trying to apply patch with output:"
    patch -p1 --dry-run < "../quickshell-webengine-${VERSION}.patch" || true
    exit 1
fi

# Show patch stats
cd "$WORKDIR"
echo ""
echo "[6/6] Patch Statistics:"
echo "-----------------------------------"
if command -v diffstat &> /dev/null; then
    diffstat "quickshell-webengine-${VERSION}.patch"
else
    wc -l "quickshell-webengine-${VERSION}.patch"
fi
echo "-----------------------------------"

# Success!
echo ""
echo "✅ Patch generated successfully!"
echo ""
echo "📍 Location: ${WORKDIR}/quickshell-webengine-${VERSION}.patch"
echo ""
echo "📋 Next steps:"
echo "   1. Review the patch:"
echo "      cat ${WORKDIR}/quickshell-webengine-${VERSION}.patch"
echo ""
echo "   2. Copy to repository:"
echo "      cp ${WORKDIR}/quickshell-webengine-${VERSION}.patch \\"
echo "         quickshell-webengine/quickshell-webengine.patch"
echo ""
echo "   3. Update spec file:"
echo "      sed -i 's/^Version:.*/Version:            ${VERSION}/' \\"
echo "         quickshell-webengine/quickshell-webengine.spec"
echo ""
echo "   4. Test build:"
echo "      cd quickshell-webengine"
echo "      spectool -g quickshell-webengine.spec"
echo "      rpmbuild -bp quickshell-webengine.spec"
echo ""
echo "   5. Full build test:"
echo "      rpmbuild -bb quickshell-webengine.spec"
echo ""

# Keep workspace for inspection
echo "🗂️  Workspace preserved at: $WORKDIR"
echo "   (will be cleaned on next run)"
echo ""
