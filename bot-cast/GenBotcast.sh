#!/usr/bin/bash

-set xe

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
    curl -L -o GenBotcast.py "https://raw.githubusercontent.com/damienbuie/edgeinnovation_substack/refs/heads/main/bot-cast/GenBotcast.py"

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
