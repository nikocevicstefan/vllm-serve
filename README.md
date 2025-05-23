# vLLM Serve

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A user-friendly Bash script to easily serve LLM models with [vLLM](https://github.com/vllm-project/vllm).

## Features

- 🧠 Automatically discovers LLM models in your models directory
- 🔧 Pre-configured parameter sets for common scenarios 
- 💻 Simple interface to launch vLLM servers
- 🚀 Supports all major vLLM configurations
- 📝 Detailed command preview before execution
- 🔍 No dependencies other than Bash and vLLM itself!

## Requirements

- Bash shell (Linux or macOS)
- vLLM already installed
- CUDA-compatible GPU (for vLLM)

## Installation

### Option 1: One-line installer (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/nikocevicstefan/vllm-serve/main/install.sh | bash
```

This will:
1. Check if vLLM is installed
2. **Auto-detect your conda/virtual environment** and offer to install there (recommended)
3. Offer installation options:
   - Current conda/virtual environment (if detected)
   - User installation (in ~/.local/bin)
   - Global installation (in /usr/local/bin, requires sudo)
   - Custom location
4. Download the script and make it executable
5. Add the installation directory to your PATH if needed

For conda environments, ensure your environment is activated before installation:

```bash
conda activate your-env-name
curl -sSL https://raw.githubusercontent.com/nikocevicstefan/vllm-serve/main/install.sh | bash
```

For global installation (available to all users), you can run:

```bash
sudo curl -sSL https://raw.githubusercontent.com/nikocevicstefan/vllm-serve/main/install.sh | sudo bash
```

### Option 2: Manual Download

```bash
# Clone the repository
git clone https://github.com/nikocevicstefan/vllm-serve.git
cd vllm-serve

# Make the script executable
chmod +x vllm-serve.sh
```

Or just download the standalone script:

```bash
curl -o vllm-serve.sh https://raw.githubusercontent.com/nikocevicstefan/vllm-serve/main/vllm-serve.sh
chmod +x vllm-serve.sh
```

## Usage

### Quick Start

If you've installed globally or in your active environment:

```bash
vllm-serve
```

Or if you downloaded the script directly:

```bash
./vllm-serve.sh
```

This will:
1. Present an interactive menu to choose an action (list models, serve a model, or show help).
2. If "serve" is chosen:
   - Scan your `~/models` directory for LLM models
   - Present a menu to select one of the available models
   - Offer configuration presets or custom configuration
   - Launch the vLLM server with your selected settings

### Available Commands

#### List models

```bash
vllm-serve list
```

Lists all available models in your models directory.

#### Serve a model

```bash
vllm-serve serve
```

Interactive process to configure and launch a vLLM server.

#### Show help

```bash
vllm-serve help
```

Displays the help message with available commands and options.

### Configuration Options

#### Specifying a custom models directory

```bash
vllm-serve --models-dir /path/to/your/models
vllm-serve list --models-dir /path/to/your/models
vllm-serve serve --models-dir /path/to/your/models
```

#### Directly serving a specific model

```bash
vllm-serve serve --model /path/to/your/model
```

### Configuration Presets

The script offers several presets to quickly configure parameters:

| Preset | Description |
|--------|-------------|
| Default | Balanced settings for general use |
| Low Memory | Reduced context length for systems with limited GPU memory |
| High Performance | Higher GPU utilization and BF16 precision for speed |
| Quantized | AWQ quantization for reduced memory footprint |

You can also customize individual parameters after selecting a preset.

## Configuration Parameters

Some of the key parameters you can configure:

- **Data type**: `auto`, `float16`, `bfloat16`, or `float32`
- **Maximum sequence length**: Context window size (2048-32768)
- **GPU memory utilization**: How much GPU memory to use (0.7-0.95)
- **Tensor parallelism**: Multi-GPU configuration
- **Host/Port**: Server binding configuration
- **Quantization**: Enable model quantization (AWQ, GPTQ, SQ)

## Problem Solving

If you encounter a memory error like:

```
ValueError: To serve at least one request with the models's max seq len (8192), 
(1.00 GiB KV cache is needed, which is larger than the available KV cache memory (0.81 GiB).
```

Use one of these solutions:
- Select the "Low Memory" preset
- Reduce the max_model_len parameter
- Select "Quantized" preset if your model supports it
- Increase gpu_memory_utilization if your system has available memory

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [vLLM](https://github.com/vllm-project/vllm) for the amazing inference engine 