// Example DMS Configuration with QuickShell WebEngine
// This demonstrates how to use QtWebEngine in a DankMaterialShell setup

import QtQuick
import QtQuick.Window
import QtWebEngine
import QtWebChannel
import Quickshell

ShellRoot {
    // Initialize WebEngine once at startup
    Component.onCompleted: {
        QtWebEngine.initialize()
        console.log("DMS: WebEngine initialized")
    }
    
    // Main panel with web-based UI
    PanelWindow {
        id: mainPanel
        anchors {
            top: true
            left: true
            right: true
        }
        height: 40
        
        // Native QML fallback (used when web UI isn't loaded)
        Rectangle {
            anchors.fill: parent
            color: "#1e1e1e"
            
            Row {
                anchors.centerIn: parent
                spacing: 10
                
                Text {
                    text: "DMS"
                    color: "#ffffff"
                    font.pixelSize: 16
                    font.bold: true
                }
                
                Text {
                    text: new Date().toLocaleTimeString()
                    color: "#888888"
                    font.pixelSize: 14
                    
                    Timer {
                        interval: 1000
                        running: true
                        repeat: true
                        onTriggered: parent.text = new Date().toLocaleTimeString()
                    }
                }
            }
        }
    }
    
    // Web UI Container (Material 3 React app)
    FloatingWindow {
        id: webContainer
        visible: false  // Toggle with keybind
        width: 400
        height: 600
        
        WebEngineView {
            id: webView
            anchors.fill: parent
            
            // Point to your React dev server or built app
            url: "http://localhost:5173"  // Vite dev server
            // url: "file:///usr/share/dms/web-ui/index.html"  // Production
            
            // WebChannel for QML ↔ React communication
            webChannel: WebChannel {
                id: bridge
                registeredObjects: [dmsBackend]
            }
            
            // Handle load events
            onLoadingChanged: function(loadRequest) {
                if (loadRequest.status === WebEngineView.LoadSucceededStatus) {
                    console.log("DMS: Web UI loaded successfully")
                } else if (loadRequest.status === WebEngineView.LoadFailedStatus) {
                    console.error("DMS: Web UI failed to load:", loadRequest.errorString)
                }
            }
            
            // Development tools (disable in production)
            settings.pluginsEnabled: true
            settings.javascriptEnabled: true
            settings.localContentCanAccessRemoteUrls: true  // For dev only!
        }
        
        // Backend API exposed to web UI
        QtObject {
            id: dmsBackend
            WebChannel.id: "dms"
            
            // Signals (QML → JavaScript)
            signal systemInfoUpdated(var info)
            signal notificationReceived(string title, string body)
            signal themeChanged(string theme)
            
            // Slots (JavaScript → QML)
            function getSystemInfo() {
                console.log("DMS: Web UI requested system info")
                
                // Gather system information
                var info = {
                    hostname: Qt.application.name,
                    uptime: "12:34:56",  // Placeholder - use real data
                    memory: {
                        total: 16384,
                        used: 8192,
                        unit: "MB"
                    },
                    cpu: {
                        usage: 45,
                        temperature: 55,
                        unit: "°C"
                    }
                }
                
                systemInfoUpdated(info)
                return info
            }
            
            function executeCommand(command) {
                console.log("DMS: Executing command:", command)
                
                // Map web UI commands to system actions
                switch(command) {
                    case "open-settings":
                        // Open settings window
                        break
                    case "toggle-theme":
                        themeChanged("dark")
                        break
                    case "lock-screen":
                        // Trigger lock screen
                        break
                    default:
                        console.warn("Unknown command:", command)
                }
                
                return true
            }
            
            function showNotification(title, body) {
                console.log("DMS: Notification:", title, body)
                // Integrate with system notifications
                notificationReceived(title, body)
            }
            
            // Get current theme
            function getTheme() {
                return {
                    mode: "dark",
                    primary: "#6750A4",
                    secondary: "#625B71",
                    background: "#1C1B1F",
                    surface: "#1C1B1F"
                }
            }
        }
        
        // Performance monitoring
        Timer {
            interval: 5000
            running: webView.loading === false
            repeat: true
            onTriggered: {
                // Send periodic updates to web UI
                dmsBackend.systemInfoUpdated(dmsBackend.getSystemInfo())
            }
        }
    }
    
    // Keybindings
    Shortcuts {
        Keybind {
            name: "toggle-web-ui"
            description: "Toggle DMS web interface"
            sequence: "Super+Space"
            onPressed: {
                webContainer.visible = !webContainer.visible
                if (webContainer.visible) {
                    webContainer.raise()
                }
            }
        }
        
        Keybind {
            name: "reload-web-ui"
            description: "Reload DMS web interface (dev)"
            sequence: "Super+R"
            onPressed: {
                webView.reload()
                console.log("DMS: Web UI reloaded")
            }
        }
    }
    
    // GameScope integration (optional)
    // Run with: gamescope -f -- quickshell -c dms-config.qml
    
    // The web UI (React) should use QtWebChannel:
    //
    // // web-ui/src/bridge.js
    // import { QWebChannel } from 'qwebchannel';
    // 
    // new QWebChannel(qt.webChannelTransport, (channel) => {
    //     const dms = channel.objects.dms;
    //     
    //     // Call QML functions
    //     dms.getSystemInfo((info) => {
    //         console.log('System info:', info);
    //     });
    //     
    //     // Listen to QML signals
    //     dms.systemInfoUpdated.connect((info) => {
    //         updateUI(info);
    //     });
    //     
    //     // Send commands to QML
    //     dms.executeCommand('toggle-theme');
    // });
}

// Directory structure for DMS with WebEngine:
//
// /etc/xdg/quickshell/dms/
// ├── shell.qml              # This file
// ├── components/            # QML components
// │   ├── Panel.qml
// │   ├── Dock.qml
// │   └── Notifications.qml
// └── web-ui/                # React application
//     ├── index.html
//     ├── assets/
//     └── bridge.js          # QtWebChannel integration
//
// /usr/bin/
// ├── dms                    # CLI tool (Go)
// └── quickshell             # QuickShell with WebEngine
//
// /usr/share/dms/
// └── web-ui/                # Built React app (production)

// Build commands for web UI:
//
// # Development (with hot reload)
// cd web-ui
// npm install
// npm run dev  # Starts on localhost:5173
// 
// # Production build
// npm run build
// sudo cp -r dist/* /usr/share/dms/web-ui/

// Run DMS:
//
// # With GameScope (recommended)
// gamescope -f -- quickshell -c /etc/xdg/quickshell/dms/shell.qml
//
// # Without GameScope
// quickshell -c /etc/xdg/quickshell/dms/shell.qml
//
// # With custom config
// quickshell -c ~/my-dms-config.qml
