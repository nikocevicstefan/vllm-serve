#!/usr/bin/env python3
from setuptools import setup, find_packages

setup(
    name="vllm-serve-cli",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "click>=8.1.3",
        "vllm>=0.8.0",
        "rich>=10.0.0",
    ],
    entry_points={
        "console_scripts": [
            "vllm-serve=vllm_serve_cli.main:cli",
        ],
    },
) 