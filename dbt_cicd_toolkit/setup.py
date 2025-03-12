from setuptools import setup, find_packages

setup(
    name="dbt_cicd_toolkit",
    version="0.1.0",
    description="A comprehensive toolkit for implementing advanced CI/CD patterns with dbt",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="dbt Community",
    author_email="support@dbt-cicd-toolkit.org",
    url="https://github.com/dbt-labs/dbt-ci-cd-toolkit",
    packages=find_packages(),
    include_package_data=True,
    python_requires=">=3.7",
    install_requires=[
        "dbt-core>=1.0.0",
        "pyyaml>=5.1",
        "click>=7.0",
        "jinja2>=2.10",
    ],
    entry_points={
        "console_scripts": [
            "dbt-cicd=dbt_cicd_toolkit.scripts.cli:main",
        ],
    },
    classifiers=[
        "Development Status :: 4 - Beta",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
    keywords="dbt, data engineering, analytics, ci/cd",
) 