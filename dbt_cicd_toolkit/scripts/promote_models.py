#!/usr/bin/env python3
"""
Script to promote dbt models to a target environment.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='Promote dbt models to a target environment.')
    parser.add_argument('--target-environment', type=str, required=True,
                        help='Target environment to promote to')
    parser.add_argument('--models', type=str, required=True,
                        help='Comma-separated list of models to promote')
    parser.add_argument('--dbt-project-dir', type=str, default='.',
                        help='Path to dbt project directory')
    parser.add_argument('--require-tests', action='store_true', default=True,
                        help='Require tests to pass before promotion')
    parser.add_argument('--skip-tests', action='store_false', dest='require_tests',
                        help='Skip test validation before promotion')
    parser.add_argument('--dry-run', action='store_true',
                        help='Validate but do not update promotion state')
    parser.add_argument('--output-format', type=str, default='text',
                        choices=['text', 'json', 'markdown'],
                        help='Output format for results')
    return parser.parse_args()


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


def run_tests_for_models(args, models):
    """Run tests for the specified models."""
    # Join models with '+'
    models_arg = '+'.join(models)
    
    # Run tests
    print(f"Running tests for models: {models}")
    result = run_dbt_command(args, 'test', ['--models', models_arg])
    
    # Check if any tests failed
    if "FAIL" in result:
        print("Tests failed. Models cannot be promoted.")
        return False
    
    print("All tests passed.")
    return True


def promote_models(args):
    """Promote models to the target environment."""
    # Parse models list
    models = [model.strip() for model in args.models.split(',')]
    
    # Run tests if required
    if args.require_tests:
        tests_passed = run_tests_for_models(args, models)
        if not tests_passed:
            return 1
    
    # Create a temporary file to run the macro
    temp_dir = Path(args.dbt_project_dir) / 'target' / 'run'
    temp_dir.mkdir(parents=True, exist_ok=True)
    
    temp_file = temp_dir / 'promote_models.sql'
    
    # Escape model names for Jinja
    models_arg = '[' + ', '.join(f'"{model}"' for model in models) + ']'
    update_state = 'true' if not args.dry_run else 'false'
    
    with open(temp_file, 'w') as f:
        f.write(f"""
-- This is a temporary model to run the macro
{{{{ config(enabled=false) }}}}

SELECT 
    {{{{ dbt_cicd_toolkit.promote_to_environment(
        target_environment='{args.target_environment}',
        models={models_arg},
        require_tests=false,  -- We already ran tests
        update_state={update_state}
    ) | tojson }}}}
""")
    
    # Run the macro
    result = run_dbt_command(args, 'compile', ['--models', 'promote_models'])
    
    # Parse the result
    try:
        # Extract the JSON part from the compile output
        json_start = result.find('{')
        json_end = result.rfind('}') + 1
        if json_start >= 0 and json_end > json_start:
            json_result = result[json_start:json_end]
            promotion_result = json.loads(json_result)
            
            # Format output based on output format
            if args.output_format == 'json':
                print(json.dumps(promotion_result, indent=2))
            elif args.output_format == 'markdown':
                print(f"# Promotion Results\n")
                print(f"## Target Environment: {promotion_result['target_environment']}\n")
                print(f"## Models Promoted\n")
                for model in promotion_result['models']:
                    print(f"- `{model}`")
                print(f"\n## Timestamp: {promotion_result['timestamp']}")
                print(f"\n## Status: {'Success' if promotion_result['success'] else 'Failed'}")
                if args.dry_run:
                    print("\n**Note: This was a dry run. No state was updated.**")
            else:  # text
                print(f"Promotion Results:")
                print(f"  Target Environment: {promotion_result['target_environment']}")
                print(f"  Models Promoted: {', '.join(promotion_result['models'])}")
                print(f"  Timestamp: {promotion_result['timestamp']}")
                print(f"  Status: {'Success' if promotion_result['success'] else 'Failed'}")
                if args.dry_run:
                    print("Note: This was a dry run. No state was updated.")
            
            return 0 if promotion_result['success'] else 1
        else:
            print("Error: Could not find JSON output in dbt compile result")
            return 1
    except (json.JSONDecodeError, KeyError) as e:
        print(f"Error parsing promotion result: {e}")
        return 1


def main():
    args = parse_arguments()
    return promote_models(args)


if __name__ == "__main__":
    sys.exit(main()) 