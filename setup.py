#!/usr/bin/env python3
from setuptools import setup, find_packages

# Read the contents of README.md
with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="vllm-serve-cli",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    description="A CLI tool to easily serve LLM models with vLLM",
    long_description=long_description,
    long_description_content_type="text/markdown",
    author="Stefan Nikocevic",
    author_email="nikocevicstefan@gmail.com",
    url="https://github.com/nikocevicstefan/vllm-serve-cli",
    python_requires=">=3.8",
    install_requires=[
        "click>=8.1.3",
        "vllm>=0.8.0",
        "rich>=10.0.0",
        "questionary>=1.10.0",
    ],
    entry_points={
        "console_scripts": [
            "vllm-serve=vllm_serve_cli.main:cli",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    keywords=["vllm", "llm", "cli", "serve", "inference"],
) 