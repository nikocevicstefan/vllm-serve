#!/usr/bin/env python3
"""CLI tool to easily serve LLM models with vLLM."""

import os
import sys
import subprocess
import glob
from pathlib import Path
from typing import List, Dict, Optional, Any

import click
from rich.console import Console
from rich.prompt import Prompt, IntPrompt, Confirm

console = Console()

DEFAULT_MODELS_DIR = os.path.expanduser("~/models")
DEFAULT_PORT = 8000
DEFAULT_HOST = "0.0.0.0"  # Listen on all interfaces
DEFAULT_MAX_MODEL_LEN = 8192

def find_models(models_dir: str) -> List[str]:
    """Find model directories in the specified path."""
    # Look for directories that might contain models
    model_dirs = []
    
    # Expand the path to handle the tilde
    models_dir = os.path.expanduser(models_dir)
    
    # Check if the directory exists
    if not os.path.exists(models_dir):
        console.print(f"[yellow]Warning: Models directory {models_dir} does not exist.[/yellow]")
        return []
    
    # Get all directories in the models directory
    for item in os.listdir(models_dir):
        full_path = os.path.join(models_dir, item)
        if os.path.isdir(full_path):
            # Check if this looks like a model directory (contains .bin, .safetensors, or config.json files)
            model_files = glob.glob(os.path.join(full_path, "*.bin")) + \
                         glob.glob(os.path.join(full_path, "*.safetensors")) + \
                         glob.glob(os.path.join(full_path, "config.json"))
            
            if model_files:
                model_dirs.append(full_path)
    
    return model_dirs

def prompt_for_config() -> Dict[str, Any]:
    """Prompt the user for vLLM configuration parameters."""
    config = {}
    
    # Basic configuration
    config["dtype"] = Prompt.ask(
        "Data type for inference", 
        choices=["auto", "float16", "bfloat16", "float32"], 
        default="auto"
    )
    
    config["max_model_len"] = IntPrompt.ask(
        "Maximum sequence length", 
        default=DEFAULT_MAX_MODEL_LEN
    )
    
    config["gpu_memory_utilization"] = float(Prompt.ask(
        "GPU memory utilization (0.0-1.0)", 
        default="0.9"
    ))
    
    # Ask about tensor parallelism if they want to use it
    if Confirm.ask("Use tensor parallelism (for multi-GPU setups)?", default=False):
        config["tensor_parallel_size"] = IntPrompt.ask(
            "Tensor parallel size (number of GPUs)", 
            default=1
        )
    
    # Server configuration
    config["host"] = Prompt.ask("Host to bind to", default=DEFAULT_HOST)
    config["port"] = IntPrompt.ask("Port to listen on", default=DEFAULT_PORT)
    
    # Advanced options
    if Confirm.ask("Configure advanced options?", default=False):
        config["quantization"] = Prompt.ask(
            "Quantization (empty for none)", 
            default=""
        )
        
        # Only add non-empty quantization
        if not config["quantization"]:
            del config["quantization"]
    
    return config

def build_vllm_command(model_path: str, config: Dict[str, Any]) -> List[str]:
    """Build the vLLM serve command with the selected parameters."""
    cmd = ["vllm", "serve", model_path]
    
    # Add all the configuration options
    for key, value in config.items():
        if isinstance(value, bool) and value:
            cmd.append(f"--{key}")
        elif not isinstance(value, bool):
            cmd.append(f"--{key}")
            cmd.append(str(value))
    
    return cmd

@click.group()
def cli():
    """vLLM Serve CLI - Easily serve LLM models with vLLM."""
    pass

@cli.command()
@click.option("--models-dir", default=DEFAULT_MODELS_DIR, 
              help=f"Directory containing model files (default: {DEFAULT_MODELS_DIR})")
def list(models_dir):
    """List available models in the models directory."""
    models = find_models(models_dir)
    
    if not models:
        console.print("[red]No models found in the specified directory.[/red]")
        return
    
    console.print(f"[green]Found {len(models)} models in {models_dir}:[/green]")
    for i, model in enumerate(models, 1):
        model_name = os.path.basename(model)
        console.print(f"{i}. [bold]{model_name}[/bold] ({model})")

@cli.command()
@click.option("--models-dir", default=DEFAULT_MODELS_DIR,
              help=f"Directory containing model files (default: {DEFAULT_MODELS_DIR})")
@click.option("--model", help="Specific model path to serve (skips selection)")
def serve(models_dir, model):
    """Serve a model using vLLM."""
    if not model:
        models = find_models(models_dir)
        
        if not models:
            console.print("[red]No models found in the specified directory.[/red]")
            sys.exit(1)
        
        console.print("[green]Available models:[/green]")
        for i, model_path in enumerate(models, 1):
            model_name = os.path.basename(model_path)
            console.print(f"{i}. [bold]{model_name}[/bold] ({model_path})")
        
        selection = IntPrompt.ask(
            "Select a model to serve (number)", 
            default=1,
            show_choices=False
        )
        
        if selection < 1 or selection > len(models):
            console.print("[red]Invalid selection.[/red]")
            sys.exit(1)
        
        model = models[selection - 1]
    
    # Get the user-defined configuration
    console.print(f"[green]Configuring vLLM to serve: [bold]{os.path.basename(model)}[/bold][/green]")
    config = prompt_for_config()
    
    # Build and execute the command
    cmd = build_vllm_command(model, config)
    
    # Show the command and ask for confirmation
    console.print("[yellow]Will execute command:[/yellow]")
    console.print(" ".join(cmd))
    
    if Confirm.ask("Do you want to proceed?", default=True):
        try:
            # Execute vLLM
            subprocess.run(cmd)
        except KeyboardInterrupt:
            console.print("[yellow]Stopped vLLM server.[/yellow]")
        except Exception as e:
            console.print(f"[red]Error running vLLM: {e}[/red]")
            sys.exit(1)

if __name__ == "__main__":
    cli() 