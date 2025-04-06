#!/usr/bin/env python3
"""CLI tool to easily serve LLM models with vLLM."""

import os
import sys
import subprocess
import glob
from pathlib import Path
from typing import List, Dict, Optional, Any

import click
import questionary
from rich.console import Console
from rich.prompt import Prompt, IntPrompt, Confirm

console = Console()

DEFAULT_MODELS_DIR = os.path.expanduser("~/models")
DEFAULT_PORT = 8000
DEFAULT_HOST = "0.0.0.0"  # Listen on all interfaces
DEFAULT_MAX_MODEL_LEN = 8192

# Define preset configurations for common use cases
PRESET_CONFIGS = {
    "Default": {
        "dtype": "auto",
        "max_model_len": DEFAULT_MAX_MODEL_LEN,
        "gpu_memory_utilization": 0.9,
        "host": DEFAULT_HOST,
        "port": DEFAULT_PORT,
    },
    "Low Memory": {
        "dtype": "auto",
        "max_model_len": 4096,
        "gpu_memory_utilization": 0.8,
        "host": DEFAULT_HOST,
        "port": DEFAULT_PORT,
    },
    "High Performance": {
        "dtype": "bfloat16",
        "max_model_len": DEFAULT_MAX_MODEL_LEN,
        "gpu_memory_utilization": 0.95,
        "host": DEFAULT_HOST,
        "port": DEFAULT_PORT,
    },
    "Quantized": {
        "dtype": "auto",
        "max_model_len": DEFAULT_MAX_MODEL_LEN,
        "gpu_memory_utilization": 0.9,
        "host": DEFAULT_HOST,
        "port": DEFAULT_PORT,
        "quantization": "awq",
    }
}

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
    """Prompt the user for vLLM configuration parameters with an interactive UI."""
    
    # Ask user if they want to use a preset or customize settings
    config_type = questionary.select(
        "Choose configuration type:",
        choices=[
            "Use a preset configuration",
            "Customize all parameters manually"
        ]
    ).ask()
    
    if config_type.startswith("Use a preset"):
        # Let user select from preset configs
        preset_name = questionary.select(
            "Select a preset configuration:",
            choices=list(PRESET_CONFIGS.keys())
        ).ask()
        
        config = PRESET_CONFIGS[preset_name].copy()
        
        # Show the selected config details
        console.print(f"[green]Selected preset: [bold]{preset_name}[/bold][/green]")
        for key, value in config.items():
            console.print(f"  [blue]{key}[/blue]: {value}")
        
        # Ask if they want to customize any of the preset values
        if questionary.confirm("Do you want to modify any of these settings?", default=False).ask():
            config = customize_config(config)
        
        return config
    else:
        # Manual configuration from scratch
        return customize_config({})

def customize_config(base_config: Dict[str, Any]) -> Dict[str, Any]:
    """Customize configuration parameters with questionary."""
    config = base_config.copy()
    
    # Basic configuration
    if "dtype" not in config:
        config["dtype"] = questionary.select(
            "Data type for inference:",
            choices=["auto", "float16", "bfloat16", "float32"],
            default="auto"
        ).ask()
    else:
        config["dtype"] = questionary.select(
            "Data type for inference:",
            choices=["auto", "float16", "bfloat16", "float32"],
            default=config["dtype"]
        ).ask()
    
    # Max model length
    if "max_model_len" not in config:
        max_len_choices = ["2048", "4096", "8192", "16384", "32768", "Custom"]
        max_len_choice = questionary.select(
            "Maximum sequence length:",
            choices=max_len_choices,
            default="8192"
        ).ask()
        
        if max_len_choice == "Custom":
            config["max_model_len"] = int(questionary.text(
                "Enter custom maximum sequence length:",
                default=str(DEFAULT_MAX_MODEL_LEN)
            ).ask())
        else:
            config["max_model_len"] = int(max_len_choice)
    else:
        max_len_choices = ["2048", "4096", "8192", "16384", "32768", "Custom"]
        current_max_len = str(config["max_model_len"])
        if current_max_len not in max_len_choices:
            max_len_choices.append(current_max_len)
            max_len_choices.remove("Custom")
            max_len_choices.append("Custom")
        
        max_len_choice = questionary.select(
            "Maximum sequence length:",
            choices=max_len_choices,
            default=current_max_len
        ).ask()
        
        if max_len_choice == "Custom":
            config["max_model_len"] = int(questionary.text(
                "Enter custom maximum sequence length:",
                default=str(config["max_model_len"])
            ).ask())
        else:
            config["max_model_len"] = int(max_len_choice)
    
    # GPU memory utilization
    if "gpu_memory_utilization" not in config:
        utilization_choices = ["0.7", "0.8", "0.9", "0.95", "Custom"]
        util_choice = questionary.select(
            "GPU memory utilization (0.0-1.0):",
            choices=utilization_choices,
            default="0.9"
        ).ask()
        
        if util_choice == "Custom":
            config["gpu_memory_utilization"] = float(questionary.text(
                "Enter custom GPU memory utilization:",
                default="0.9"
            ).ask())
        else:
            config["gpu_memory_utilization"] = float(util_choice)
    else:
        utilization_choices = ["0.7", "0.8", "0.9", "0.95", "Custom"]
        current_util = str(config["gpu_memory_utilization"])
        if current_util not in utilization_choices:
            utilization_choices.append(current_util)
            utilization_choices.remove("Custom")
            utilization_choices.append("Custom")
            
        util_choice = questionary.select(
            "GPU memory utilization (0.0-1.0):",
            choices=utilization_choices,
            default=current_util
        ).ask()
        
        if util_choice == "Custom":
            config["gpu_memory_utilization"] = float(questionary.text(
                "Enter custom GPU memory utilization:",
                default=str(config["gpu_memory_utilization"])
            ).ask())
        else:
            config["gpu_memory_utilization"] = float(util_choice)
    
    # Ask about tensor parallelism
    if "tensor_parallel_size" not in config:
        if questionary.confirm("Use tensor parallelism (for multi-GPU setups)?", default=False).ask():
            tp_sizes = ["2", "4", "8", "Custom"]
            tp_choice = questionary.select(
                "Tensor parallel size (number of GPUs):",
                choices=tp_sizes,
                default="2"
            ).ask()
            
            if tp_choice == "Custom":
                config["tensor_parallel_size"] = int(questionary.text(
                    "Enter custom tensor parallel size:",
                    default="2"
                ).ask())
            else:
                config["tensor_parallel_size"] = int(tp_choice)
    
    # Server configuration
    if "host" not in config:
        config["host"] = questionary.text(
            "Host to bind to:", 
            default=DEFAULT_HOST
        ).ask()
    else:
        config["host"] = questionary.text(
            "Host to bind to:", 
            default=config["host"]
        ).ask()
    
    if "port" not in config:
        port_choices = ["8000", "8080", "5000", "3000", "Custom"]
        port_choice = questionary.select(
            "Port to listen on:",
            choices=port_choices,
            default="8000"
        ).ask()
        
        if port_choice == "Custom":
            config["port"] = int(questionary.text(
                "Enter custom port:",
                default=str(DEFAULT_PORT)
            ).ask())
        else:
            config["port"] = int(port_choice)
    else:
        port_choices = ["8000", "8080", "5000", "3000", "Custom"]
        current_port = str(config["port"])
        if current_port not in port_choices:
            port_choices.append(current_port)
            port_choices.remove("Custom")
            port_choices.append("Custom")
            
        port_choice = questionary.select(
            "Port to listen on:",
            choices=port_choices,
            default=current_port
        ).ask()
        
        if port_choice == "Custom":
            config["port"] = int(questionary.text(
                "Enter custom port:",
                default=str(config["port"])
            ).ask())
        else:
            config["port"] = int(port_choice)
    
    # Advanced options
    if questionary.confirm("Configure advanced options?", default=False).ask():
        # Quantization
        quant_choices = ["none", "awq", "gptq", "sq", "Custom"]
        current_quant = config.get("quantization", "none")
        if current_quant not in quant_choices and current_quant != "none":
            quant_choices.append(current_quant)
            quant_choices.remove("Custom")
            quant_choices.append("Custom")
            
        quant_choice = questionary.select(
            "Quantization:",
            choices=quant_choices,
            default=current_quant if current_quant in quant_choices else "none"
        ).ask()
        
        if quant_choice == "Custom":
            quant_value = questionary.text(
                "Enter custom quantization:",
                default=current_quant if current_quant != "none" else ""
            ).ask()
            if quant_value and quant_value.lower() != "none":
                config["quantization"] = quant_value
            elif "quantization" in config:
                del config["quantization"]
        elif quant_choice.lower() != "none":
            config["quantization"] = quant_choice
        elif "quantization" in config:
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

def serve_model(models_dir, model):
    """Core function to serve a model using vLLM."""
    if not model:
        models = find_models(models_dir)
        
        if not models:
            console.print("[red]No models found in the specified directory.[/red]")
            sys.exit(1)
        
        # Create a list of models with their names for selection
        choices = []
        for model_path in models:
            model_name = os.path.basename(model_path)
            choices.append({
                'name': f"{model_name} ({model_path})",
                'value': model_path
            })
        
        console.print("[green]Select a model to serve:[/green]")
        model = questionary.select(
            "Choose a model:",
            choices=choices
        ).ask()
    
    # Get the user-defined configuration
    console.print(f"[green]Configuring vLLM to serve: [bold]{os.path.basename(model)}[/bold][/green]")
    config = prompt_for_config()
    
    # Build and execute the command
    cmd = build_vllm_command(model, config)
    
    # Show the command and ask for confirmation
    console.print("[yellow]Will execute command:[/yellow]")
    console.print(" ".join(cmd))
    
    if questionary.confirm("Do you want to proceed?", default=True).ask():
        try:
            # Execute vLLM
            subprocess.run(cmd)
        except KeyboardInterrupt:
            console.print("[yellow]Stopped vLLM server.[/yellow]")
        except Exception as e:
            console.print(f"[red]Error running vLLM: {e}[/red]")
            sys.exit(1)

@click.group(invoke_without_command=True)
@click.pass_context
@click.option("--models-dir", default=DEFAULT_MODELS_DIR,
              help=f"Directory containing model files (default: {DEFAULT_MODELS_DIR})")
def cli(ctx, models_dir):
    """vLLM Serve CLI - Easily serve LLM models with vLLM."""
    # If no subcommand was specified, run the default serve action
    if ctx.invoked_subcommand is None:
        serve_model(models_dir, None)

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
    serve_model(models_dir, model)

if __name__ == "__main__":
    cli() 