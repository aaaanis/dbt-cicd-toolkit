#!/usr/bin/env python3
"""
Command Line Interface for dbt-ci-cd-toolkit.
This script provides CLI access to the toolkit's features.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description='dbt CI/CD Toolkit CLI')
    subparsers = parser.add_subparsers(dest='command', help='Command to execute')
    
    # Setup command
    setup_parser = subparsers.add_parser('setup', help='Setup CI/CD templates')
    setup_parser.add_argument('--project-dir', type=str, default='.',
                       help='Path to the dbt project directory')
    setup_parser.add_argument('--ci-provider', type=str, 
                       choices=['github', 'gitlab', 'azure', 'jenkins'],
                       default='github', help='CI provider to setup templates for')
    setup_parser.add_argument('--features', type=str, nargs='+',
                       choices=['impact_analysis', 'selective_testing', 'environment_promotion',
                                'visualization', 'testing_dashboard', 'version_management', 'all'],
                       default=['all'], help='Features to enable')
    setup_parser.add_argument('--configure-dbt-project', action='store_true',
                       help='Update dbt_project.yml with recommended configurations')
    
    # Impact analysis command
    impact_parser = subparsers.add_parser('impact-analysis', help='Analyze impact of changes')
    impact_parser.add_argument('--files', type=str, nargs='+', required=True,
                        help='Source files that have changed')
    impact_parser.add_argument('--include-downstream', action='store_true',
                        help='Include downstream models')
    impact_parser.add_argument('--format', type=str, choices=['json', 'markdown', 'text'],
                        default='text', help='Output format')
    
    # Selective testing command
    test_parser = subparsers.add_parser('selective-testing', help='Run selective tests')
    test_parser.add_argument('--files', type=str, nargs='+', required=True,
                      help='Changed files to test')
    test_parser.add_argument('--level', type=str, 
                      choices=['minimal', 'standard', 'comprehensive'],
                      default='standard', help='Test level')
    test_parser.add_argument('--include-upstream', action='store_true',
                      help='Include upstream models')
    test_parser.add_argument('--include-downstream', action='store_true',
                      help='Include downstream models')
    
    # Version management commands
    version_parser = subparsers.add_parser('version', help='Version management')
    version_subparsers = version_parser.add_subparsers(dest='version_command', help='Version command')
    
    # Register version
    register_parser = version_subparsers.add_parser('register', help='Register a new version')
    register_parser.add_argument('--model', type=str, required=True,
                          help='Model name')
    register_parser.add_argument('--version', type=str, required=True,
                          help='Version string (e.g. 1.2.0)')
    register_parser.add_argument('--description', type=str,
                          help='Description of changes')
    register_parser.add_argument('--breaking', action='store_true',
                          help='Mark as breaking change')
    register_parser.add_argument('--author', type=str,
                          help='Author of the change')
    
    # Deploy version
    deploy_parser = version_subparsers.add_parser('deploy', help='Deploy a version')
    deploy_parser.add_argument('--model', type=str, required=True,
                        help='Model name')
    deploy_parser.add_argument('--version', type=str, required=True,
                        help='Version to deploy')
    deploy_parser.add_argument('--environment', type=str, required=True,
                        help='Environment to deploy to')
    deploy_parser.add_argument('--skip-tests', action='store_true',
                        help='Skip running tests before deployment')
    
    # Get version history
    history_parser = version_subparsers.add_parser('history', help='Get version history')
    history_parser.add_argument('--model', type=str, required=True,
                         help='Model name')
    history_parser.add_argument('--environment', type=str,
                         help='Filter by environment')
    history_parser.add_argument('--format', type=str, choices=['json', 'table'],
                         default='table', help='Output format')
    
    # Environment promotion
    promote_parser = subparsers.add_parser('promote', help='Promote to environment')
    promote_parser.add_argument('--environment', type=str, required=True,
                         help='Target environment')
    promote_parser.add_argument('--models', type=str, nargs='+', required=True,
                         help='Models to promote')
    promote_parser.add_argument('--skip-tests', action='store_true',
                         help='Skip running tests before promotion')
    
    return parser.parse_args()


def run_dbt_operation(operation, args_dict):
    """Run a dbt operation with the given arguments."""
    args_json = json.dumps(args_dict)
    cmd = ['dbt', 'run-operation', operation, '--args', args_json]
    
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode != 0:
        print(f"Error running dbt operation: {result.stderr}")
        sys.exit(result.returncode)
    
    return result.stdout


def handle_setup(args):
    """Handle the setup command."""
    from dbt_cicd_toolkit.scripts.setup_cicd import main as setup_main
    sys.argv = ['setup_cicd.py']
    
    if args.project_dir:
        sys.argv.extend(['--project-dir', args.project_dir])
    
    if args.ci_provider:
        sys.argv.extend(['--ci-provider', args.ci_provider])
    
    if args.features:
        sys.argv.extend(['--features'] + args.features)
    
    if args.configure_dbt_project:
        sys.argv.append('--configure-dbt-project')
    
    setup_main()


def handle_impact_analysis(args):
    """Handle the impact analysis command."""
    operation_args = {
        'source_files': args.files,
        'include_downstream': args.include_downstream,
        'output_format': args.format
    }
    
    result = run_dbt_operation('dbt_cicd_toolkit.get_impacted_models', operation_args)
    print(result.strip())


def handle_selective_testing(args):
    """Handle the selective testing command."""
    operation_args = {
        'changed_files': args.files,
        'test_level': args.level,
        'include_upstream': args.include_upstream,
        'include_downstream': args.include_downstream
    }
    
    result = run_dbt_operation('dbt_cicd_toolkit.run_selective_tests', operation_args)
    print(result.strip())


def handle_version_register(args):
    """Handle the version register command."""
    operation_args = {
        'model_name': args.model,
        'version': args.version,
        'is_breaking': args.breaking
    }
    
    if args.description:
        operation_args['description'] = args.description
    
    if args.author:
        operation_args['author'] = args.author
    
    result = run_dbt_operation('dbt_cicd_toolkit.register_version', operation_args)
    print(result.strip())


def handle_version_deploy(args):
    """Handle the version deploy command."""
    operation_args = {
        'model_name': args.model,
        'version': args.version,
        'environment': args.environment,
        'require_tests': not args.skip_tests
    }
    
    result = run_dbt_operation('dbt_cicd_toolkit.deploy_version', operation_args)
    print(result.strip())


def handle_version_history(args):
    """Handle the version history command."""
    operation_args = {
        'model_name': args.model
    }
    
    if args.environment:
        operation_args['environment'] = args.environment
    
    result = run_dbt_operation('dbt_cicd_toolkit.get_version_history', operation_args)
    
    try:
        history = json.loads(result.strip())
        
        if args.format == 'table':
            print(f"Version history for model: {args.model}")
            print("-" * 80)
            print(f"{'Version':<10} | {'Timestamp':<20} | {'Status':<10} | {'Breaking':<8} | Description")
            print("-" * 80)
            
            for version_entry in history.get('versions', []):
                print(f"{version_entry.get('version', ''):<10} | "
                      f"{version_entry.get('timestamp', ''):<20} | "
                      f"{version_entry.get('status', ''):<10} | "
                      f"{str(version_entry.get('is_breaking', False)):<8} | "
                      f"{version_entry.get('description', '')}")
        else:
            print(json.dumps(history, indent=2))
    
    except json.JSONDecodeError:
        print("Error parsing version history. Raw output:")
        print(result.strip())


def handle_promote(args):
    """Handle the promote command."""
    operation_args = {
        'target_environment': args.environment,
        'models': args.models,
        'require_tests': not args.skip_tests
    }
    
    result = run_dbt_operation('dbt_cicd_toolkit.promote_to_environment', operation_args)
    print(result.strip())


def main():
    """Main entry point for the CLI."""
    args = parse_arguments()
    
    if args.command == 'setup':
        handle_setup(args)
    elif args.command == 'impact-analysis':
        handle_impact_analysis(args)
    elif args.command == 'selective-testing':
        handle_selective_testing(args)
    elif args.command == 'version':
        if args.version_command == 'register':
            handle_version_register(args)
        elif args.version_command == 'deploy':
            handle_version_deploy(args)
        elif args.version_command == 'history':
            handle_version_history(args)
        else:
            print("Error: Please specify a version subcommand")
            sys.exit(1)
    elif args.command == 'promote':
        handle_promote(args)
    else:
        print("Error: Please specify a command")
        sys.exit(1)


if __name__ == "__main__":
    main() 