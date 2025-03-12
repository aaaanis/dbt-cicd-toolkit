#!/usr/bin/env python3
"""
Script to run selective tests in a CI environment based on changed files.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Run selective dbt tests based on changed files.')
    parser.add_argument('--changed-files', type=str, help='Comma-separated list of changed files')
    parser.add_argument('--changed-files-file', type=str, help='File containing list of changed files (one per line)')
    parser.add_argument('--test-level', type=str, default='standard', 
                        choices=['minimal', 'standard', 'comprehensive'],
                        help='Level of testing to perform')
    parser.add_argument('--include-upstream', action='store_true', 
                        help='Whether to include upstream models')
    parser.add_argument('--include-downstream', action='store_true', default=True,
                        help='Whether to include downstream models')
    parser.add_argument('--dbt-project-dir', type=str, default='.',
                        help='Path to dbt project directory')
    parser.add_argument('--output-format', type=str, default='text',
                        choices=['text', 'json', 'markdown'],
                        help='Output format for results')
    parser.add_argument('--dry-run', action='store_true',
                        help='Print affected models without running tests')
    return parser.parse_args()


def get_changed_files(args):
    """Get the list of changed files from arguments."""
    if args.changed_files:
        return [f.strip() for f in args.changed_files.split(',')]
    elif args.changed_files_file:
        with open(args.changed_files_file, 'r') as f:
            return [line.strip() for line in f if line.strip()]
    else:
        print("Error: Either --changed-files or --changed-files-file must be provided")
        sys.exit(1)


def run_dbt_command(args, command, additional_args=None):
    """Run a dbt command and return the result."""
    if additional_args is None:
        additional_args = []
    
    cmd = ['dbt', command, '--project-dir', args.dbt_project_dir] + additional_args
    
    print(f"Running command: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error running dbt command: {result.stderr}")
        sys.exit(result.returncode)
    
    return result.stdout


def get_impacted_models(args, changed_files):
    """Get the list of impacted models from changed files."""
    # Create a temporary manifest to run the macro
    temp_manifest_dir = Path(args.dbt_project_dir) / 'target' / 'run'
    temp_manifest_dir.mkdir(parents=True, exist_ok=True)
    
    # Create a temporary model file to run the macro
    temp_model_path = temp_manifest_dir / 'get_impacted_models.sql'
    
    # Escape file paths for Jinja
    escaped_files = [f.replace('\\', '\\\\').replace('"', '\\"') for f in changed_files]
    files_arg = '[' + ', '.join(f'"{f}"' for f in escaped_files) + ']'
    
    with open(temp_model_path, 'w') as f:
        f.write(f"""
-- This is a temporary model to run the macro
{{{{ config(enabled=false) }}}}

SELECT 
    {{{{ dbt_cicd_toolkit.get_impacted_models(
        source_files={files_arg},
        include_sources=true,
        include_downstream={str(args.include_downstream).lower()},
        exclude_current=false
    ) | tojson }}}}
""")
    
    # Run the macro
    result = run_dbt_command(args, 'compile', ['--models', 'get_impacted_models'])
    
    # Parse the result
    try:
        # Extract the JSON part from the compile output
        json_start = result.find('[')
        json_end = result.rfind(']') + 1
        if json_start >= 0 and json_end > json_start:
            json_result = result[json_start:json_end]
            return json.loads(json_result)
        else:
            print("Error: Could not find JSON output in dbt compile result")
            return []
    except json.JSONDecodeError:
        print("Error: Could not parse JSON output from dbt compile result")
        return []


def run_selective_tests(args, impacted_models):
    """Run tests for the impacted models."""
    if not impacted_models:
        print("No models impacted by changes. No tests to run.")
        return 0
    
    # Join models with '+'
    models_arg = '+'.join(impacted_models)
    
    # Run tests
    additional_args = ['--models', models_arg]
    run_dbt_command(args, 'test', additional_args)
    
    return 0


def main():
    args = parse_arguments()
    changed_files = get_changed_files(args)
    
    print(f"Changed files: {changed_files}")
    print(f"Test level: {args.test_level}")
    
    impacted_models = get_impacted_models(args, changed_files)
    print(f"Impacted models: {impacted_models}")
    
    if args.dry_run:
        print("Dry run - not running tests")
        return 0
    
    return run_selective_tests(args, impacted_models)


if __name__ == "__main__":
    sys.exit(main()) 