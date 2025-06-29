class Vibetext < Formula
  desc "AI-powered text assistant with beautiful UI and powerful commands"
  homepage "https://github.com/shaharkozi/VibeText"
  url "https://github.com/shaharkozi/VibeText-releases/releases/download/v0.3.0/VibeText-v0.3.0-macos-universal.tar.gz"
  sha256 "0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5"
  license "MIT"

  depends_on "ollama"
  depends_on :macos

  def install
    # Install the backend binary
    bin.install "vibetext-backend"
    
    # Install the desktop app
    prefix.install "VibeText.app"
    
    # Create a symlink in Applications (optional, for user convenience)
    system "ln", "-sf", "#{prefix}/VibeText.app", "/Applications/VibeText.app"
    
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
      open "/Applications/VibeText.app"
      
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
  end

  def caveats
    <<~EOS
      VibeText has been installed! 🎉
      
      To start everything at once:
        vibetext
      
      This will:
      • Start Ollama server
      • Start VibeText backend  
      • Open the VibeText app
      
      To stop everything:
        killall vibetext-backend ollama
    EOS
  end

  test do
    assert_predicate bin/"vibetext-backend", :exist?
    assert_predicate bin/"vibetext", :exist?
    assert_predicate prefix/"VibeText.app", :exist?
  end
end 