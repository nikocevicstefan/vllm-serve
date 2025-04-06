#!/bin/bash

# vLLM Serve - A Bash script to easily serve LLM models with vLLM
# This is a Bash implementation of the vllm-serve-cli Python package

VERSION="0.1.0"

# Default configuration
DEFAULT_MODELS_DIR="$HOME/models"
DEFAULT_PORT=8000
DEFAULT_HOST="0.0.0.0"  # Listen on all interfaces
DEFAULT_MAX_MODEL_LEN=8192

# Define preset configurations
declare -A PRESET_CONFIGS
# Default preset
PRESET_CONFIGS[Default_dtype]="auto"
PRESET_CONFIGS[Default_max_model_len]=$DEFAULT_MAX_MODEL_LEN
PRESET_CONFIGS[Default_gpu_memory_utilization]=0.9
PRESET_CONFIGS[Default_host]=$DEFAULT_HOST
PRESET_CONFIGS[Default_port]=$DEFAULT_PORT

# Low Memory preset
PRESET_CONFIGS[LowMemory_dtype]="auto"
PRESET_CONFIGS[LowMemory_max_model_len]=4096
PRESET_CONFIGS[LowMemory_gpu_memory_utilization]=0.8
PRESET_CONFIGS[LowMemory_host]=$DEFAULT_HOST
PRESET_CONFIGS[LowMemory_port]=$DEFAULT_PORT

# High Performance preset
PRESET_CONFIGS[HighPerformance_dtype]="bfloat16"
PRESET_CONFIGS[HighPerformance_max_model_len]=$DEFAULT_MAX_MODEL_LEN
PRESET_CONFIGS[HighPerformance_gpu_memory_utilization]=0.95
PRESET_CONFIGS[HighPerformance_host]=$DEFAULT_HOST
PRESET_CONFIGS[HighPerformance_port]=$DEFAULT_PORT

# Quantized preset
PRESET_CONFIGS[Quantized_dtype]="auto"
PRESET_CONFIGS[Quantized_max_model_len]=$DEFAULT_MAX_MODEL_LEN
PRESET_CONFIGS[Quantized_gpu_memory_utilization]=0.9
PRESET_CONFIGS[Quantized_host]=$DEFAULT_HOST
PRESET_CONFIGS[Quantized_port]=$DEFAULT_PORT
PRESET_CONFIGS[Quantized_quantization]="awq"

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Usage information
print_usage() {
    echo -e "${BLUE}vLLM Serve${NC} v$VERSION"
    echo
    echo "A user-friendly script to easily serve LLM models with vLLM"
    echo
    echo "USAGE:"
    echo "  $(basename "$0") [COMMAND] [OPTIONS]"
    echo
    echo "COMMANDS:"
    echo "  list     List available models in the specified directory"
    echo "  serve    Configure and launch a vLLM server for a model"
    echo "  help     Display this help message"
    echo
    echo "OPTIONS:"
    echo "  --models-dir DIR  Specify models directory (default: $DEFAULT_MODELS_DIR)"
    echo "  --model PATH      Directly specify a model path to serve (with 'serve' command)"
    echo
    echo "EXAMPLES:"
    echo "  $(basename "$0")                       # Interactive mode"
    echo "  $(basename "$0") list                  # List available models"
    echo "  $(basename "$0") serve                 # Select and serve a model"
    echo "  $(basename "$0") serve --model PATH    # Directly serve the specified model"
}

# Find potential model directories
find_models() {
    local models_dir="$1"
    
    # Expand the path to handle the tilde
    models_dir="${models_dir/#\~/$HOME}"
    
    # Check if the directory exists
    if [ ! -d "$models_dir" ]; then
        echo -e "${YELLOW}Warning: Models directory $models_dir does not exist.${NC}"
        return 1
    fi
    
    # Find potential model directories (those containing *.bin, *.safetensors, or config.json)
    declare -a found_models
    local i=1
    
    for dir in "$models_dir"/*; do
        if [ -d "$dir" ]; then
            # Check if this looks like a model directory
            if compgen -G "$dir/*.bin" > /dev/null || \
               compgen -G "$dir/*.safetensors" > /dev/null || \
               [ -f "$dir/config.json" ]; then
                found_models+=("$dir")
                echo "  $i) $(basename "$dir")"
                ((i++))
            fi
        fi
    done
    
    # If no models were found, inform the user
    if [ ${#found_models[@]} -eq 0 ]; then
        echo -e "${YELLOW}No models found in $models_dir${NC}"
        return 1
    fi
    
    # Return the list of model paths through the global variable
    MODEL_PATHS=("${found_models[@]}")
    return 0
}

# List available models
cmd_list() {
    local models_dir="$DEFAULT_MODELS_DIR"
    
    # Process options
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --models-dir)
                models_dir="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
    
    echo -e "${BLUE}Looking for models in:${NC} $models_dir"
    echo
    
    find_models "$models_dir"
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}Try specifying a different directory with --models-dir${NC}"
    fi
}

# Prompt user for configuration options
prompt_for_config() {
    local config_type
    
    # Ask if user wants to use a preset or customize
    echo -e "${BLUE}Choose configuration type:${NC}"
    echo "  1) Use a preset configuration"
    echo "  2) Customize all parameters manually"
    read -p "Enter choice [1]: " config_choice
    config_choice=${config_choice:-1}
    
    if [ "$config_choice" = "1" ]; then
        echo -e "${BLUE}Select a preset configuration:${NC}"
        echo "  1) Default - Balanced settings for general use"
        echo "  2) Low Memory - Reduced context length for systems with limited GPU memory"
        echo "  3) High Performance - Higher GPU utilization and BF16 precision for speed"
        echo "  4) Quantized - AWQ quantization for reduced memory footprint"
        read -p "Enter choice [1]: " preset_choice
        preset_choice=${preset_choice:-1}
        
        # Set the preset config
        case $preset_choice in
            1|"")
                PRESET="Default"
                ;;
            2)
                PRESET="LowMemory"
                ;;
            3)
                PRESET="HighPerformance"
                ;;
            4)
                PRESET="Quantized"
                ;;
            *)
                echo -e "${RED}Invalid choice. Using Default preset.${NC}"
                PRESET="Default"
                ;;
        esac
        
        # Display the selected preset
        echo -e "${GREEN}Selected preset: $PRESET${NC}"
        echo -e "  ${BLUE}dtype:${NC} ${PRESET_CONFIGS[${PRESET}_dtype]}"
        echo -e "  ${BLUE}max_model_len:${NC} ${PRESET_CONFIGS[${PRESET}_max_model_len]}"
        echo -e "  ${BLUE}gpu_memory_utilization:${NC} ${PRESET_CONFIGS[${PRESET}_gpu_memory_utilization]}"
        echo -e "  ${BLUE}host:${NC} ${PRESET_CONFIGS[${PRESET}_host]}"
        echo -e "  ${BLUE}port:${NC} ${PRESET_CONFIGS[${PRESET}_port]}"
        
        # Check if quantization is part of this preset
        if [ -n "${PRESET_CONFIGS[${PRESET}_quantization]}" ]; then
            echo -e "  ${BLUE}quantization:${NC} ${PRESET_CONFIGS[${PRESET}_quantization]}"
        fi
        
        # Ask if user wants to modify any settings
        read -p "Do you want to modify any of these settings? [y/N]: " modify_settings
        if [[ "$modify_settings" =~ ^[Yy]$ ]]; then
            customize_config "$PRESET"
        else
            # Use preset as-is
            CONFIG_DTYPE="${PRESET_CONFIGS[${PRESET}_dtype]}"
            CONFIG_MAX_MODEL_LEN="${PRESET_CONFIGS[${PRESET}_max_model_len]}"
            CONFIG_GPU_UTIL="${PRESET_CONFIGS[${PRESET}_gpu_memory_utilization]}"
            CONFIG_HOST="${PRESET_CONFIGS[${PRESET}_host]}"
            CONFIG_PORT="${PRESET_CONFIGS[${PRESET}_port]}"
            CONFIG_QUANTIZATION="${PRESET_CONFIGS[${PRESET}_quantization]}"
        fi
    else
        # Start with empty config
        customize_config ""
    fi
}

# Customize configuration options
customize_config() {
    local preset="$1"
    
    # Data type
    echo -e "${BLUE}Data type for inference:${NC}"
    echo "  1) auto"
    echo "  2) float16"
    echo "  3) bfloat16"
    echo "  4) float32"
    
    # Set default based on preset
    local default_dtype="1" # Default to auto
    if [ -n "$preset" ]; then
        case "${PRESET_CONFIGS[${preset}_dtype]}" in
            "auto") default_dtype="1" ;;
            "float16") default_dtype="2" ;;
            "bfloat16") default_dtype="3" ;;
            "float32") default_dtype="4" ;;
        esac
    fi
    
    read -p "Enter choice [$default_dtype]: " dtype_choice
    dtype_choice=${dtype_choice:-$default_dtype}
    
    case $dtype_choice in
        1|"") CONFIG_DTYPE="auto" ;;
        2) CONFIG_DTYPE="float16" ;;
        3) CONFIG_DTYPE="bfloat16" ;;
        4) CONFIG_DTYPE="float32" ;;
        *) 
            echo -e "${RED}Invalid choice. Using auto.${NC}"
            CONFIG_DTYPE="auto"
            ;;
    esac
    
    # Maximum sequence length
    echo -e "${BLUE}Maximum sequence length:${NC}"
    echo "  1) 2048"
    echo "  2) 4096"
    echo "  3) 8192"
    echo "  4) 16384"
    echo "  5) 32768"
    echo "  6) Custom"
    
    # Set default based on preset
    local default_max_len="3" # Default to 8192
    if [ -n "$preset" ]; then
        case "${PRESET_CONFIGS[${preset}_max_model_len]}" in
            2048) default_max_len="1" ;;
            4096) default_max_len="2" ;;
            8192) default_max_len="3" ;;
            16384) default_max_len="4" ;;
            32768) default_max_len="5" ;;
            *) default_max_len="6" ;; # Custom
        esac
    fi
    
    read -p "Enter choice [$default_max_len]: " max_len_choice
    max_len_choice=${max_len_choice:-$default_max_len}
    
    case $max_len_choice in
        1) CONFIG_MAX_MODEL_LEN=2048 ;;
        2) CONFIG_MAX_MODEL_LEN=4096 ;;
        3|"") CONFIG_MAX_MODEL_LEN=8192 ;;
        4) CONFIG_MAX_MODEL_LEN=16384 ;;
        5) CONFIG_MAX_MODEL_LEN=32768 ;;
        6) 
            # Custom length
            local default_custom_len=$DEFAULT_MAX_MODEL_LEN
            if [ -n "$preset" ]; then
                default_custom_len="${PRESET_CONFIGS[${preset}_max_model_len]}"
            fi
            read -p "Enter custom maximum sequence length [$default_custom_len]: " custom_max_len
            custom_max_len=${custom_max_len:-$default_custom_len}
            
            # Validate input is a number
            if [[ "$custom_max_len" =~ ^[0-9]+$ ]]; then
                CONFIG_MAX_MODEL_LEN=$custom_max_len
            else
                echo -e "${RED}Invalid number. Using default: $DEFAULT_MAX_MODEL_LEN${NC}"
                CONFIG_MAX_MODEL_LEN=$DEFAULT_MAX_MODEL_LEN
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Using default: $DEFAULT_MAX_MODEL_LEN${NC}"
            CONFIG_MAX_MODEL_LEN=$DEFAULT_MAX_MODEL_LEN
            ;;
    esac
    
    # GPU memory utilization
    echo -e "${BLUE}GPU memory utilization (0.0-1.0):${NC}"
    echo "  1) 0.7"
    echo "  2) 0.8"
    echo "  3) 0.9"
    echo "  4) 0.95"
    echo "  5) Custom"
    
    # Set default based on preset
    local default_util="3" # Default to 0.9
    if [ -n "$preset" ]; then
        case "${PRESET_CONFIGS[${preset}_gpu_memory_utilization]}" in
            0.7) default_util="1" ;;
            0.8) default_util="2" ;;
            0.9) default_util="3" ;;
            0.95) default_util="4" ;;
            *) default_util="5" ;; # Custom
        esac
    fi
    
    read -p "Enter choice [$default_util]: " util_choice
    util_choice=${util_choice:-$default_util}
    
    case $util_choice in
        1) CONFIG_GPU_UTIL=0.7 ;;
        2) CONFIG_GPU_UTIL=0.8 ;;
        3|"") CONFIG_GPU_UTIL=0.9 ;;
        4) CONFIG_GPU_UTIL=0.95 ;;
        5) 
            # Custom utilization
            local default_custom_util=0.9
            if [ -n "$preset" ]; then
                default_custom_util="${PRESET_CONFIGS[${preset}_gpu_memory_utilization]}"
            fi
            read -p "Enter custom GPU memory utilization [$default_custom_util]: " custom_util
            custom_util=${custom_util:-$default_custom_util}
            
            # Validate input is a float between 0 and 1
            if [[ "$custom_util" =~ ^0?\.[0-9]+$ ]] || [[ "$custom_util" =~ ^[01]$ ]]; then
                CONFIG_GPU_UTIL=$custom_util
            else
                echo -e "${RED}Invalid value. Using default: 0.9${NC}"
                CONFIG_GPU_UTIL=0.9
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Using default: 0.9${NC}"
            CONFIG_GPU_UTIL=0.9
            ;;
    esac
    
    # Tensor parallelism
    read -p "Use tensor parallelism (for multi-GPU setups)? [y/N]: " use_tp
    if [[ "$use_tp" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Tensor parallel size (number of GPUs):${NC}"
        echo "  1) 2"
        echo "  2) 4"
        echo "  3) 8"
        echo "  4) Custom"
        
        read -p "Enter choice [1]: " tp_choice
        tp_choice=${tp_choice:-1}
        
        case $tp_choice in
            1|"") CONFIG_TP_SIZE=2 ;;
            2) CONFIG_TP_SIZE=4 ;;
            3) CONFIG_TP_SIZE=8 ;;
            4)
                read -p "Enter custom tensor parallel size [2]: " custom_tp
                custom_tp=${custom_tp:-2}
                
                # Validate input is a number
                if [[ "$custom_tp" =~ ^[0-9]+$ ]]; then
                    CONFIG_TP_SIZE=$custom_tp
                else
                    echo -e "${RED}Invalid number. Using default: 2${NC}"
                    CONFIG_TP_SIZE=2
                fi
                ;;
            *)
                echo -e "${RED}Invalid choice. Using default: 2${NC}"
                CONFIG_TP_SIZE=2
                ;;
        esac
    else
        CONFIG_TP_SIZE=""
    fi
    
    # Host address
    local default_host=$DEFAULT_HOST
    if [ -n "$preset" ]; then
        default_host="${PRESET_CONFIGS[${preset}_host]}"
    fi
    read -p "Host to bind to [$default_host]: " input_host
    CONFIG_HOST=${input_host:-$default_host}
    
    # Port
    echo -e "${BLUE}Port to listen on:${NC}"
    echo "  1) 8000"
    echo "  2) 8080"
    echo "  3) 5000"
    echo "  4) 3000"
    echo "  5) Custom"
    
    # Set default based on preset
    local default_port_choice="1" # Default to 8000
    if [ -n "$preset" ]; then
        case "${PRESET_CONFIGS[${preset}_port]}" in
            8000) default_port_choice="1" ;;
            8080) default_port_choice="2" ;;
            5000) default_port_choice="3" ;;
            3000) default_port_choice="4" ;;
            *) default_port_choice="5" ;; # Custom
        esac
    fi
    
    read -p "Enter choice [$default_port_choice]: " port_choice
    port_choice=${port_choice:-$default_port_choice}
    
    case $port_choice in
        1|"") CONFIG_PORT=8000 ;;
        2) CONFIG_PORT=8080 ;;
        3) CONFIG_PORT=5000 ;;
        4) CONFIG_PORT=3000 ;;
        5)
            # Custom port
            local default_custom_port=$DEFAULT_PORT
            if [ -n "$preset" ]; then
                default_custom_port="${PRESET_CONFIGS[${preset}_port]}"
            fi
            read -p "Enter custom port [$default_custom_port]: " custom_port
            custom_port=${custom_port:-$default_custom_port}
            
            # Validate input is a number
            if [[ "$custom_port" =~ ^[0-9]+$ ]]; then
                CONFIG_PORT=$custom_port
            else
                echo -e "${RED}Invalid number. Using default: $DEFAULT_PORT${NC}"
                CONFIG_PORT=$DEFAULT_PORT
            fi
            ;;
        *)
            echo -e "${RED}Invalid choice. Using default: $DEFAULT_PORT${NC}"
            CONFIG_PORT=$DEFAULT_PORT
            ;;
    esac
    
    # Quantization (only if using Quantized preset or user wants to customize)
    if [ "$preset" = "Quantized" ] || [ -z "$preset" ]; then
        read -p "Use model quantization? [y/N]: " use_quant
        if [[ "$use_quant" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Quantization type:${NC}"
            echo "  1) AWQ"
            echo "  2) GPTQ"
            echo "  3) SQ"
            
            read -p "Enter choice [1]: " quant_choice
            quant_choice=${quant_choice:-1}
            
            case $quant_choice in
                1|"") CONFIG_QUANTIZATION="awq" ;;
                2) CONFIG_QUANTIZATION="gptq" ;;
                3) CONFIG_QUANTIZATION="sq" ;;
                *)
                    echo -e "${RED}Invalid choice. Using AWQ.${NC}"
                    CONFIG_QUANTIZATION="awq"
                    ;;
            esac
        else
            # Don't use quantization
            CONFIG_QUANTIZATION=""
        fi
    fi
}

# Build the vLLM command with selected parameters
build_vllm_command() {
    local model_path="$1"
    
    # Start with basic command
    declare -a cmd
    cmd=("vllm" "serve" "$model_path")
    
    # Add all the configuration options
    cmd+=("--dtype" "$CONFIG_DTYPE")
    cmd+=("--max-model-len" "$CONFIG_MAX_MODEL_LEN")
    cmd+=("--gpu-memory-utilization" "$CONFIG_GPU_UTIL")
    cmd+=("--host" "$CONFIG_HOST")
    cmd+=("--port" "$CONFIG_PORT")
    
    # Add optional parameters
    if [ -n "$CONFIG_TP_SIZE" ]; then
        cmd+=("--tensor-parallel-size" "$CONFIG_TP_SIZE")
    fi
    
    if [ -n "$CONFIG_QUANTIZATION" ]; then
        cmd+=("--quantization" "$CONFIG_QUANTIZATION")
    fi
    
    # Return the final command through the global variable
    VLLM_COMMAND=("${cmd[@]}")
}

# Serve a model
cmd_serve() {
    local models_dir="$DEFAULT_MODELS_DIR"
    local direct_model_path=""
    
    # Process options
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --models-dir)
                models_dir="$2"
                shift 2
                ;;
            --model)
                direct_model_path="$2"
                shift 2
                ;;
            *)
                echo -e "${RED}Error: Unknown option: $1${NC}"
                print_usage
                exit 1
                ;;
        esac
    done
    
    # Set the model path
    local model_path=""
    
    if [ -n "$direct_model_path" ]; then
        # User provided direct model path
        model_path="$direct_model_path"
        echo -e "${BLUE}Using specified model:${NC} $model_path"
    else
        # List available models and let user select
        echo -e "${BLUE}Looking for models in:${NC} $models_dir"
        echo
        
        if ! find_models "$models_dir"; then
            # No models found in the directory
            echo -e "${YELLOW}No models found. You can:${NC}"
            echo "  1) Specify a different models directory with --models-dir"
            echo "  2) Specify a direct model path or HuggingFace model ID"
            read -p "Enter a direct model path or HuggingFace model ID: " model_path
            
            if [ -z "$model_path" ]; then
                echo -e "${RED}Error: No model specified. Exiting.${NC}"
                exit 1
            fi
        else
            # Let user select from found models
            echo
            read -p "Select a model (1-${#MODEL_PATHS[@]}) or enter 0 for custom path: " model_num
            
            if [ "$model_num" -eq 0 ]; then
                # Custom path
                read -p "Enter a direct model path or HuggingFace model ID: " model_path
                
                if [ -z "$model_path" ]; then
                    echo -e "${RED}Error: No model specified. Exiting.${NC}"
                    exit 1
                fi
            elif [ "$model_num" -ge 1 ] && [ "$model_num" -le ${#MODEL_PATHS[@]} ]; then
                # Valid selection from the list
                model_path="${MODEL_PATHS[$((model_num-1))]}"
                echo -e "${GREEN}Selected:${NC} $model_path"
            else
                echo -e "${RED}Invalid selection. Exiting.${NC}"
                exit 1
            fi
        fi
    fi
    
    # Get configuration from user
    prompt_for_config
    
    # Build the vLLM command
    build_vllm_command "$model_path"
    
    # Display the command
    echo
    echo -e "${BLUE}Command to execute:${NC}"
    printf "%q " "${VLLM_COMMAND[@]}"
    echo
    
    # Confirm and execute
    echo
    read -p "Press Enter to execute, or Ctrl+C to cancel..."
    
    echo -e "${GREEN}Launching vLLM server...${NC}"
    "${VLLM_COMMAND[@]}"
}

# Main function
main() {
    # If no arguments, run interactive mode
    if [ $# -eq 0 ]; then
        # Welcome message
        echo -e "${BLUE}vLLM Serve${NC} v$VERSION"
        echo "A user-friendly script to serve LLM models with vLLM"
        echo
        
        # Show available commands
        echo -e "${BLUE}Available commands:${NC}"
        echo "  1) list - List available models"
        echo "  2) serve - Configure and launch a vLLM server"
        echo "  3) help - Show help information"
        read -p "Choose a command [2]: " cmd_choice
        cmd_choice=${cmd_choice:-2}
        
        case $cmd_choice in
            1) cmd_list ;;
            2|"") cmd_serve ;;
            3) print_usage ;;
            *)
                echo -e "${RED}Invalid choice.${NC}"
                print_usage
                exit 1
                ;;
        esac
        
        exit 0
    fi
    
    # Parse command line arguments
    case "$1" in
        list)
            shift
            cmd_list "$@"
            ;;
        serve)
            shift
            cmd_serve "$@"
            ;;
        help|--help|-h)
            print_usage
            ;;
        *)
            echo -e "${RED}Unknown command: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
}

# Execute main function
main "$@" 