# vLLM Serve CLI

A command-line tool to easily serve LLM models with vLLM.

## Features

- Automatically finds and lists LLM models in your models directory
- Interactive parameter configuration with sensible defaults
- Simple interface to launch vLLM servers
- Supports all major vLLM configurations

## Installation

```bash
# Install from source
pip install -e .
```

## Usage

### List available models:

```bash
vllm-serve list
```

### Serve a model:

```bash
vllm-serve serve
```

This will:
1. List all available models in your `~/models` directory
2. Let you select one to serve
3. Guide you through configuration with sensible defaults
4. Launch the vLLM server with your chosen settings

### Specify a custom models directory:

```bash
vllm-serve list --models-dir /path/to/your/models
vllm-serve serve --models-dir /path/to/your/models
```

### Directly specify a model to serve:

```bash
vllm-serve serve --model /path/to/your/model
```

## Requirements

- Python 3.8+
- vLLM
- click
- rich 