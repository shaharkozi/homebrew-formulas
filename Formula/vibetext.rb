class Vibetext < Formula
  desc "AI-powered text assistant with beautiful UI and powerful commands"
  homepage "https://github.com/shaharkozi/VibeText"
  url "https://github.com/shaharkozi/VibeText-releases/releases/download/v0.3.0/VibeText-vv0.3.0-macos-universal.tar.gz"
  sha256 "42e233d701bb213bda18208a246fbd1c0b6a016fbc08e068b3ed340462c169eb"
  license "MIT"

  depends_on "ollama"
  depends_on :macos

  def install
    # The archive contains a nested directory structure
    # Find the actual files in the extracted structure
    
    # Install the backend binary
    backend_binary = Dir.glob("**/bin/vibetext-backend").first
    if backend_binary
      bin.install backend_binary
    else
      odie "vibetext-backend binary not found in archive"
    end
    
    # Install the desktop app
    app_bundle = Dir.glob("**/app/*.app").first
    if app_bundle
      app_name = File.basename(app_bundle)
      puts "Found app bundle: #{app_name}"
      prefix.install app_bundle
      
      # App is installed in prefix directory
      puts "✅ App installed at: #{prefix}/#{app_name}"
    else
      odie "No .app bundle found in archive"
    end
    
    # Create a service script for easy startup
    (bin/"vibetext").write startup_script
  end

  def startup_script
    <<~EOS
      #!/bin/bash
      
      echo "🚀 Starting VibeText..."
      
      # Start Ollama in background if not running
      if ! pgrep -x "ollama" > /dev/null; then
        echo "📡 Starting Ollama server..."
        ollama serve > /dev/null 2>&1 &
        sleep 5
      else
        echo "✅ Ollama server is already running"
      fi
      
      # Check if Llama 3 model is available
      if ! ollama list | grep -q "llama3"; then
        echo "🤖 Llama 3 model not found. Installing..."
        if ollama pull llama3; then
          echo "✅ Llama 3 model installed successfully!"
        else
          echo "❌ Failed to install Llama 3 model. Please run: ollama pull llama3"
          exit 1
        fi
      else
        echo "✅ Llama 3 model is ready"
      fi
      
      # Start VibeText backend in background
      echo "🔧 Starting VibeText backend..."
      #{bin}/vibetext-backend &
      BACKEND_PID=$!
      
      # Wait a moment for backend to start
      sleep 2
      
      # Open the VibeText app
      echo "🎨 Opening VibeText app..."
      
      # Try to find and open the app - check Applications first, then fallback to brew prefix
      if [ -d "/Applications/VibeText.app" ]; then
        open "/Applications/VibeText.app"
      elif [ -d "/Applications/vibetext-chat.app" ]; then
        open "/Applications/vibetext-chat.app"
      else
        # Fallback to the brew-installed location
        APP_PATH=$(find #{prefix} -name "*.app" -type d | head -1)
        if [ -n "$APP_PATH" ]; then
          open "$APP_PATH"
        else
          echo "❌ Could not find VibeText app. Please open it manually from Applications or $(brew --prefix)/Cellar/vibetext/"
        fi
      fi
      
      echo "✨ VibeText is now running!"
      echo "💡 To stop: killall vibetext-backend ollama"
      echo "📱 App should open automatically"
      
      # Keep script running to maintain processes
      wait $BACKEND_PID
    EOS
  end

  def post_install
    puts <<~EOS
      🤖 Setting up Llama 3 model...
      
      Starting Ollama and pulling Llama 3 (this may take a few minutes)...
    EOS
    
    # Ensure Ollama is running
    unless system("pgrep -x ollama > /dev/null 2>&1")
      puts "📡 Starting Ollama server..."
      system("ollama serve > /dev/null 2>&1 &")
      sleep 5  # Give Ollama time to start
    end
    
    # Pull Llama 3 model with proper error handling
    puts "⬇️  Downloading Llama 3 model..."
    unless system("ollama pull llama3")
      puts "⚠️  Failed to download Llama 3. You can install it manually later with: ollama pull llama3"
    else
      puts "✅ Llama 3 model installed successfully!"
    end
    
    puts <<~EOS
      
      🎉 VibeText has been installed successfully!
      
      🚀 Quick Start:
      vibetext              # Start everything (Ollama + Backend + App)
      
      📋 Manual Setup (if needed):
      vibetext-backend      # Start backend only
      ollama serve          # Start Ollama only
      
      ✨ Available Commands:
      • @prettier     - Polish and improve text
      • @fixGrammar   - Fix grammatical errors
      • @rephrase     - Rewrite in different style
      • @changeTone   - Adjust tone (formal, casual, etc.)
      • @summarize    - Create concise summaries
      • @translate    - Translate to different languages
      
      🔧 Troubleshooting:
      • Stop all: killall vibetext-backend ollama
      • Backend runs on: http://localhost:8080
      • For support: shaharkozi12@gmail.com
      
      💡 Pro tip: Use @ or / to trigger command suggestions!
    EOS
    
    # Open Finder and highlight the app for easy dragging to Applications
    app_path = Dir.glob("#{prefix}/*.app").first
    if app_path
      puts "\n📱 Opening Finder and highlighting the app..."
      puts "💡 Drag the highlighted VibeText app to Applications folder for easier access!"
      system "open", "-R", app_path
    else
      puts "\n📱 Opening Finder to show installation location..."
      system "open", "#{prefix}"
    end
  end

  def caveats
    <<~EOS
      VibeText has been installed! 🎉
      
      🚀 Quick Start:
        vibetext
      
      This command will:
      • Start Ollama server
      • Start VibeText backend  
      • Open the VibeText app
      
      📱 Add to Applications (optional):
      To manually open and drag the app to Applications:
        open -R $(brew --prefix)/Cellar/vibetext/#{version}/*.app
      
      Or browse to: $(brew --prefix)/Cellar/vibetext/#{version}
      Then drag the app to Applications folder for easier access!
      
      🛑 To stop everything:
        killall vibetext-backend ollama
    EOS
  end

  test do
    assert_predicate bin/"vibetext-backend", :exist?
    assert_predicate bin/"vibetext", :exist?
    # Test for app bundle in the prefix directory
    assert Dir.glob("#{prefix}/*.app").any?, "No .app bundle found in #{prefix}"
  end
end 