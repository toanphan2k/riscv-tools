
import re
import subprocess
from pathlib import Path

import pytest
import yaml


SCRIPT_DIR = Path(__file__).resolve().parent
CONFIG_FILE = SCRIPT_DIR / "tests.yaml"


def load_tests():
    with CONFIG_FILE.open("r", encoding="utf-8") as file:
        config = yaml.safe_load(file) or {}

    if not isinstance(config, dict):
        raise ValueError("YAML root must be a mapping")

    tests = [
        (name, test_config)
        for name, test_config in config.items()
        if isinstance(name, str) and name.startswith("test_")
    ]

    if not tests:
        raise ValueError("No tests found with names starting with 'test_'")

    return tests


def run_command(command):
    return subprocess.run(
        command,
        shell=True,
        cwd=SCRIPT_DIR,
        capture_output=True,
        text=True,
        executable="/bin/bash",
    )


def execute_test(name, config):
    for field in ("command", "validate", "match"):
        assert field in config, f"{name}: missing field '{field}'"
        assert isinstance(config[field], str), (
            f"{name}: '{field}' must be a string"
        )

    # 1. Execute the main command
    command_result = run_command(config["command"])

    assert command_result.returncode == 0, (
        f"{name}: command failed\n"
        f"Command: {config['command']}\n"
        f"Exit code: {command_result.returncode}\n"
        f"stdout:\n{command_result.stdout}\n"
        f"stderr:\n{command_result.stderr}"
    )

    # 2. Execute validation
    validate_result = run_command(config["validate"])

    validate_output = (
        validate_result.stdout + validate_result.stderr
    )

    assert validate_result.returncode == 0, (
        f"{name}: validation command failed\n"
        f"Command: {config['validate']}\n"
        f"Exit code: {validate_result.returncode}\n"
        f"Output:\n{validate_output}"
    )

    # 3. Match regex against validation output
    assert re.search(config["match"], validate_output), (
        f"{name}: regex did not match validation output\n"
        f"Regex: {config['match']}\n"
        f"Output:\n{validate_output}"
    )


@pytest.mark.parametrize(
    "name,config",
    load_tests(),
    ids=lambda value: value if isinstance(value, str) else None,
)
def test_yaml_case(name, config):
    execute_test(name, config)
