# vLLM Serve CLI

[![PyPI version](https://badge.fury.io/py/vllm-serve-cli.svg)](https://badge.fury.io/py/vllm-serve-cli)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A user-friendly command-line tool to easily serve LLM models with [vLLM](https://github.com/vllm-project/vllm).

## Features

- 🎮 Interactive arrow-key navigation for selecting models and parameters
- 🧠 Automatically discovers LLM models in your models directory
- 🔧 Pre-configured parameter sets for common scenarios 
- 💻 Simple interface to launch vLLM servers
- 🚀 Supports all major vLLM configurations
- 📝 Detailed command preview before execution

![vLLM Serve CLI Demo](https://raw.githubusercontent.com/nikocevicstefan/vllm-serve-cli/main/docs/demo.gif)

## Installation

### From PyPI (recommended)

```bash
pip install vllm-serve-cli
```

### From GitHub

```bash
pip install git+https://github.com/nikocevicstefan/vllm-serve-cli.git
```

### From Source

```bash
git clone https://github.com/nikocevicstefan/vllm-serve-cli.git
cd vllm-serve-cli
pip install -e .
```

## Requirements

- Python 3.8+
- vLLM
- CUDA-compatible GPU (for vLLM)

## Usage

### Quick Start

Simply run the command to start the interactive interface:

```bash
vllm-serve
```

This will:
1. Scan your `~/models` directory for LLM models
2. Present a menu to select one of the available models
3. Offer configuration presets or custom configuration
4. Launch the vLLM server with your selected settings

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

The tool offers several presets to quickly configure parameters:

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

Contributions are welcome! Please check out our [contribution guidelines](CONTRIBUTING.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgements

- [vLLM](https://github.com/vllm-project/vllm) for the amazing inference engine
- [Questionary](https://github.com/tmbo/questionary) for the interactive CLI interface
- [Click](https://click.palletsprojects.com/) for the command-line interface
- [Rich](https://github.com/Textualize/rich) for beautiful terminal formatting 