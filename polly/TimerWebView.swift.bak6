import SwiftUI
import WebKit

#if os(macOS)
struct TimerWebView: NSViewRepresentable {
    func makeNSView(context: Context) -> WKWebView {
        // Configure WebView with proper preferences
        let configuration = WKWebViewConfiguration()
        
        // Use the newer API for JavaScript configuration
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsMagnification = true
        webView.navigationDelegate = context.coordinator
        
        // Instead of loading from a file, load HTML content directly
        let htmlContent = getTimerHTMLContent()
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: TimerWebView
        
        init(_ parent: TimerWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView loaded successfully")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}
#else
struct TimerWebView: UIViewRepresentable {
    func makeUIView(context: Context) -> WKWebView {
        // Configure WebView with proper preferences
        let configuration = WKWebViewConfiguration()
        
        // Use the newer API for JavaScript configuration
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = webpagePreferences
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        
        // Instead of loading from a file, load HTML content directly
        let htmlContent = getTimerHTMLContent()
        webView.loadHTMLString(htmlContent, baseURL: nil)
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: TimerWebView
        
        init(_ parent: TimerWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("WebView loaded successfully")
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("WebView provisional navigation failed: \(error.localizedDescription)")
        }
    }
}
#endif

// Function to return the HTML content
func getTimerHTMLContent() -> String {
    return """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Timer</title>
        <style>
            body {
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background-color: #121212;
                color: #ffffff;
                font-family: 'Helvetica Neue', Arial, sans-serif;
            }
            #timer {
                font-size: 10vw;
                font-weight: bold;
                text-align: center;
            }
            button {
                margin-top: 20px;
                padding: 10px 20px;
                font-size: 2vw;
                border: none;
                border-radius: 5px;
                background-color: #1E88E5;
                color: white;
                cursor: pointer;
            }
            button:hover {
                background-color: #1565C0;
            }
        </style>
    </head>
    <body>
        <div>
            <div id="timer">00:00</div>
            <button id="startStopBtn">Start</button>
        </div>

        <script>
            let timerDisplay = document.getElementById('timer');
            let startStopBtn = document.getElementById('startStopBtn');

            let timerInterval = null;
            let totalSeconds = 0;

            function updateTimerDisplay() {
                let minutes = Math.floor(totalSeconds / 60);
                let seconds = totalSeconds % 60;

                timerDisplay.textContent = 
                    String(minutes).padStart(2, '0') + ':' + 
                    String(seconds).padStart(2, '0');
            }

            function startTimer() {
                if (timerInterval) return; // Prevent multiple intervals

                timerInterval = setInterval(() => {
                    totalSeconds++;
                    updateTimerDisplay();
                }, 1000);
                
                startStopBtn.textContent = 'Stop';
            }

            function stopTimer() {
                clearInterval(timerInterval);
                timerInterval = null;
                
                startStopBtn.textContent = 'Start';
            }

            startStopBtn.addEventListener('click', () => {
                if (timerInterval) {
                    stopTimer();
                } else {
                    startTimer();
                }
            });

            // Initialize display
            updateTimerDisplay();
        </script>
    </body>
    </html>
    """
}
