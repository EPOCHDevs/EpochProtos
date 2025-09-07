import os
from setuptools import setup, find_packages

setup(
    name="epoch-protos",
    version="1.0.0",
    description="Protocol Buffer definitions for EpochFolio models",
    long_description=open("README.md").read() if os.path.exists("README.md") else "",
    long_description_content_type="text/markdown",
    author="EpochLab",
    author_email="dev@epochlab.ai",
    url="https://github.com/epochlab/epoch-protos",
    packages=find_packages(),
    install_requires=[
        "protobuf>=4.21.0",
        "pydantic>=2.0.0",
        "typing-extensions>=4.0.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "black>=22.0.0",
            "mypy>=1.0.0",
        ]
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
        "Topic :: Office/Business :: Financial",
    ],
    python_requires=">=3.8",
    include_package_data=True,
    package_data={
        "": ["*.proto", "*.py", "*.pyi"],
    },
)
