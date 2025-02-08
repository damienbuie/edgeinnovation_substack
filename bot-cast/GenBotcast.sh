#!/usr/bin/env bash

set -xe  # Enable debugging and exit on failure

echo "Checking Operating Sytem"
# Detect the OS
OS_TYPE=$(uname -s)

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "Running on macOS..."
    
    
    # Ensure Ollama is installed
    if ! command_exists ollama; then
        echo "Ollama not found. Installing via Homebrew..."
        

        # Ensure Homebrew is installed
        if ! command_exists brew; then
            echo "Homebrew not found. Installing..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi

        brew install ollama
    fi

else
    echo "Unsupported OS: $OS_TYPE"
    exit 1
fi


echo "Checking if Ollama is running:"
# Get the process ID of 'ollama serve'
OLLAMA_PID=$(pgrep -f 'ollama serve')

# If OLLAMA_PID is empty, start Ollama and get the new PID
if [ -z "$OLLAMA_PID" ]; then
    echo "Starting Ollama"
    /bin/ollama serve &  # Run Ollama in the background
    sleep 2  # Give some time for Ollama to start
    OLLAMA_PID=$(pgrep -f 'ollama serve')
else 
    echo "Ollama is running"
fi

# If it's still not running, exit with an error
if [ -z "$OLLAMA_PID" ]; then
    echo "Ollama binary not running. Exiting."
    exit 1
fi

echo "Pulling required LLMs"
# Define the required models
REQUIRED_MODELS=("gemma:7b" "mistral:latest" "deepseek-r1:8b" )

# Function to get a list of installed models
get_installed_models() {
    ollama list | awk 'NR>1 {print $1}'  # Extract model names, skipping the header row
}

# Function to check if a model is installed
is_model_installed() {
    local model=$1
    get_installed_models | grep -wq "$model"
}

# Ensure required models are installed
for model in "${REQUIRED_MODELS[@]}"; do
    if ! is_model_installed "$model"; then
        echo "Model $model not found. Pulling..."
        ollama pull "$model"
    else
        echo "Model $model is already installed."
    fi
done

if [ -f "GenBotcast.py" ]; then
    echo "GenBot File exists."
else
    echo "Bot-cast not found. Pulling with curl..."
    curl -L -o GenBotcast.py "https://raw.githubusercontent.com/damienbuie/copy_substack/refs/heads/main/GenBotcast_published_20250201.py"

    if [ $? -eq 0 ]; then
        echo "Download successful."
    else
        echo "Download failed!"
        exit 1
    fi
fi

echo "Checking for Python Libraries."
REQUIRED_LIBRARIES=("ollama")

for lib in "${REQUIRED_LIBRARIES[@]}"; do
    if ! python3 -c "import $lib" &> /dev/null; then
        echo "Installing $lib..."
        python3 -m pip install "$lib"
    else
        echo "$lib is already installed."
    fi
done

echo "Running the Bot-Casts!"

echo "Mistal & Mistral host a Bot-cast"
#time python3 GenBotcast.py --host gemma --guest mistral > bot-cast_mistral_v_mistral.txt

echo "Gemma & Mistral host a Bot-cast"
#time python3 GenBotcast.py --host gemma --guest mistral > bot-cast_gemma_v_mistral.txt

echo "DeepSeek & Mistral host a Bot-cast"
#time python3 GenBotcast.py --host deepseek-r1:8b --guest mistral --lint > bot-cast_deepseek_v_mistral.txt
