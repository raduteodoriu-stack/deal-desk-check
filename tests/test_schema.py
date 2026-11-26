"""The extraction schema must itself be a valid JSON Schema."""
import json
from pathlib import Path

from jsonschema import Draft202012Validator

SCHEMA = Path(__file__).resolve().parents[1] / "schemas" / "contract_extraction_v1.json"


def test_schema_is_valid():
    Draft202012Validator.check_schema(json.loads(SCHEMA.read_text(encoding="utf-8")))
