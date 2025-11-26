# Testing Guide - QuickShell WebEngine

Complete guide for testing QuickShell WebEngine packages locally before COPR deployment.

## 🎯 Prerequisites

### System Requirements
- Fedora 40, 41, or Rawhide
- x86_64 architecture
- 4GB RAM minimum (for building)
- Internet connection

### Install Build Tools

```bash
sudo dnf install -y \
    rpm-build \
    rpmdevtools \
    spectool \
    mock \
    copr-cli
```

### Setup RPM Build Environment

```bash
rpmdev-setuptree
```

This creates:
```
~/rpmbuild/
├── BUILD/
├── BUILDROOT/
├── RPMS/
├── SOURCES/
├── SPECS/
└── SRPMS/
```

## 🔨 Local Build Testing

### Method 1: Direct rpmbuild

#### Build QuickShell WebEngine

```bash
# Clone repository
git clone https://github.com/agency-agency/web-shell-copr
cd web-shell-copr/quickshell-webengine

# Download sources
spectool -g -R quickshell-webengine.spec

# Copy patch to SOURCES
cp quickshell-webengine.patch ~/rpmbuild/SOURCES/

# Build SRPM
rpmbuild -bs quickshell-webengine.spec

# Build RPM
rpmbuild -bb quickshell-webengine.spec
```

**Expected output:**
```
Wrote: ~/rpmbuild/RPMS/x86_64/quickshell-webengine-0.2.1-1.fc40.x86_64.rpm
```

#### Install and Test

```bash
# Install the built package
sudo dnf install ~/rpmbuild/RPMS/x86_64/quickshell-webengine-*.rpm

# Verify installation
quickshell --version
rpm -q quickshell-webengine

# Test WebEngine availability
cat > test-webengine.qml << 'EOF'
import QtQuick
import QtWebEngine

QtObject {
    Component.onCompleted: {
        console.log("QtWebEngine available:", typeof(QtWebEngine))
        console.log("Test passed!")
        Qt.quit()
    }
}
EOF

quickshell -c test-webengine.qml
```

**Expected output:**
```
QtWebEngine available: object
Test passed!
```

### Method 2: Mock Build (Clean Room)

Mock builds in a clean chroot environment (recommended for accuracy).

```bash
# Initialize mock for your Fedora version
sudo mock -r fedora-40-x86_64 --init

# Build SRPM
cd quickshell-webengine
rpmbuild -bs quickshell-webengine.spec

# Build in mock
sudo mock -r fedora-40-x86_64 ~/rpmbuild/SRPMS/quickshell-webengine-*.src.rpm

# Results in
/var/lib/mock/fedora-40-x86_64/result/
```

**Check mock logs:**
```bash
sudo mock -r fedora-40-x86_64 --shell
# Inside chroot:
ls /builddir/build/BUILD/
cat /builddir/build/BUILD/quickshell-*/build.log
```

### Method 3: Test COPR Makefile

Test the actual COPR build process locally:

```bash
cd web-shell-copr

# Test makefile preparation
make -f .copr/Makefile prepare

# Test Qt dependencies
make -f .copr/Makefile qtprep

# Build SRPM using COPR method
make -f .copr/Makefile srpm \
    spec=quickshell-webengine/quickshell-webengine.spec \
    outdir=./output
```

## 🧪 Functional Testing

### Test 1: Basic WebEngine Import

```bash
cat > test1-basic.qml << 'EOF'
import QtQuick
import QtWebEngine

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    
    Component.onCompleted: {
        console.log("WebEngine initialized")
        QtWebEngine.initialize()
    }
    
    WebEngineView {
        anchors.fill: parent
        url: "https://www.example.com"
    }
}
EOF

# Run with GameScope (recommended)
gamescope -w 800 -h 600 -f -- quickshell -c test1-basic.qml

# Or without GameScope
quickshell -c test1-basic.qml
```

### Test 2: QtWebChannel Bridge

```bash
cat > test2-bridge.qml << 'EOF'
import QtQuick
import QtWebEngine
import QtWebChannel

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    
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
        
        url: "data:text/html,
            <html>
            <head>
                <script src='qrc:///qtwebchannel/qwebchannel.js'></script>
                <script>
                new QWebChannel(qt.webChannelTransport, function(channel) {
                    var backend = channel.objects.backend;
                    backend.testSignal.connect(function(msg) {
                        document.body.innerHTML = 'Received: ' + msg;
                    });
                    backend.testMethod('Hello from JS!');
                });
                </script>
            </head>
            <body>Loading...</body>
            </html>
        "
    }
    
    QtObject {
        id: backend
        WebChannel.id: "backend"
        
        signal testSignal(string message)
        
        function testMethod(msg) {
            console.log("Received from JS:", msg)
            testSignal("Hello from QML!")
        }
    }
}
EOF

quickshell -c test2-bridge.qml
```

**Expected console output:**
```
Received from JS: Hello from JS!
```

### Test 3: Performance with GameScope

```bash
cat > test3-performance.qml << 'EOF'
import QtQuick
import QtWebEngine

ApplicationWindow {
    visible: true
    width: 1920
    height: 1080
    
    Component.onCompleted: {
        QtWebEngine.initialize()
    }
    
    WebEngineView {
        anchors.fill: parent
        url: "https://threejs.org/examples/webgl_animation_keyframes.html"
        
        onLoadingChanged: function(loadRequest) {
            if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                console.log("3D WebGL test loaded - check for smooth 60 FPS")
            }
        }
    }
}
EOF

# Run with GameScope Vulkan backend
gamescope -f -w 1920 -h 1080 -- quickshell -c test3-performance.qml
```

**Performance expectations:**
- Smooth 60 FPS rendering
- GPU acceleration active
- No tearing or stuttering

### Test 4: Multiple WebViews

```bash
cat > test4-multiple.qml << 'EOF'
import QtQuick
import QtWebEngine

ApplicationWindow {
    visible: true
    width: 1600
    height: 900
    
    Component.onCompleted: {
        QtWebEngine.initialize()
    }
    
    Row {
        anchors.fill: parent
        
        WebEngineView {
            width: parent.width / 2
            height: parent.height
            url: "https://www.wikipedia.org"
        }
        
        WebEngineView {
            width: parent.width / 2
            height: parent.height
            url: "https://github.com"
        }
    }
}
EOF

gamescope -f -- quickshell -c test4-multiple.qml
```

## 🔍 Verification Checklist

### Build Verification

- [ ] SRPM builds without errors
- [ ] RPM builds without errors
- [ ] All files installed to correct locations
- [ ] Binary runs: `quickshell --version`
- [ ] No dependency errors: `rpm -qpR quickshell-webengine-*.rpm`

### Runtime Verification

- [ ] QtWebEngine imports successfully
- [ ] QtWebChannel imports successfully
- [ ] WebEngineView renders web content
- [ ] QML ↔ JavaScript bridge works
- [ ] GPU acceleration active (check with GameScope)
- [ ] No crashes or segfaults
- [ ] Memory usage reasonable (<500MB for simple test)

### Integration Verification

- [ ] Works with GameScope
- [ ] Works standalone (without GameScope)
- [ ] Compatible with existing QuickShell configs
- [ ] DMS package installs with quickshell-webengine

## 🐛 Debugging

### Build Failures

```bash
# Check build log
tail -n 100 ~/rpmbuild/BUILD/quickshell-*/build.log

# Verify patch applies
cd ~/rpmbuild/BUILD/quickshell-*
patch -p1 --dry-run < ~/rpmbuild/SOURCES/quickshell-webengine.patch

# Check CMake configuration
cat build/CMakeCache.txt | grep WEBENGINE
```

### Runtime Failures

```bash
# Enable Qt debug output
export QT_LOGGING_RULES="qt.webengine*=true"
quickshell -c test.qml

# Check library loading
ldd /usr/bin/quickshell | grep -i web

# Verify QtWebEngine is installed
rpm -qa | grep qt6-qtwebengine

# Check for missing dependencies
quickshell -c test.qml 2>&1 | grep "cannot open shared object"
```

### WebEngine Not Rendering

```bash
# Verify GPU acceleration
export QT_WEBENGINE_DEBUG_GPU=1
quickshell -c test.qml

# Try software rendering fallback
export QTWEBENGINE_CHROMIUM_FLAGS="--disable-gpu"
quickshell -c test.qml

# Check Wayland compositor
echo $WAYLAND_DISPLAY
echo $XDG_SESSION_TYPE
```

## 📊 Performance Testing

### Memory Usage

```bash
cat > memory-test.qml << 'EOF'
import QtQuick
import QtWebEngine

ApplicationWindow {
    visible: true
    width: 800
    height: 600
    
    Component.onCompleted: QtWebEngine.initialize()
    
    WebEngineView {
        anchors.fill: parent
        url: "https://www.youtube.com"
    }
}
EOF

# Monitor memory
quickshell -c memory-test.qml &
PID=$!
watch -n 1 "ps -p $PID -o rss,vsz,pmem,pcpu,cmd"
```

**Expected:** <500MB RSS for basic page, <1GB for complex sites

### GPU Usage

```bash
# Install GPU monitoring
sudo dnf install nvtop  # for NVIDIA
sudo dnf install radeontop  # for AMD

# Run test
gamescope -f -- quickshell -c test.qml &

# Monitor GPU in another terminal
nvtop
```

## ✅ Test Results Template

Document your test results:

```markdown
## Test Results - QuickShell WebEngine 0.2.1

**Date:** 2024-11-25
**Tester:** Your Name
**System:** Fedora 40 x86_64
**Hardware:** CPU, RAM, GPU

### Build Tests
- [ ] SRPM build: PASS/FAIL
- [ ] RPM build: PASS/FAIL
- [ ] Mock build: PASS/FAIL

### Runtime Tests
- [ ] Basic WebEngine: PASS/FAIL
- [ ] WebChannel bridge: PASS/FAIL
- [ ] Performance test: PASS/FAIL
- [ ] Multiple views: PASS/FAIL

### Performance
- Memory (idle): XXX MB
- Memory (with page): XXX MB
- GPU usage: XX%
- Render performance: XX FPS

### Issues Found
1. Issue description...
2. Issue description...

### Notes
Additional observations...
```

## 🚀 Pre-COPR Checklist

Before pushing to COPR:

- [ ] All local build tests pass
- [ ] All functional tests pass
- [ ] Patch applies cleanly
- [ ] Spec file lints: `rpmlint quickshell-webengine.spec`
- [ ] SRPM lints: `rpmlint quickshell-webengine-*.src.rpm`
- [ ] RPM lints: `rpmlint quickshell-webengine-*.rpm`
- [ ] No unpackaged files warnings
- [ ] Dependencies resolved
- [ ] Documentation updated
- [ ] Changelog entry added

## 📚 Additional Resources

- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [Mock Documentation](https://github.com/rpm-software-management/mock/wiki)
- [Qt WebEngine Debugging](https://doc.qt.io/qt-6/qtwebengine-debugging.html)
- [GameScope Wiki](https://github.com/ValveSoftware/gamescope/wiki)

---

**Next Steps**: Once all tests pass, proceed with COPR upload!
