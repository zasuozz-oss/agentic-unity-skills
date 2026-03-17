# QA Agent-Tester — LangChain Implementation (Python)

## Cài đặt

```bash
pip install langchain langchain-anthropic python-dotenv pydantic
```

## Cấu trúc project

```
qa-agent-langchain/
├── .env
├── config.yaml
├── agents/
│   ├── __init__.py
│   ├── parser_agent.py
│   ├── generator_agent.py
│   ├── verifier_agent.py
│   └── scorer.py
├── tools/
│   ├── file_reader.py      # Đọc PDF, DOCX, MD
│   └── md_writer.py        # Xuất file .md
├── history/                # Lưu lịch sử run
├── output/                 # Output files
└── run.py                  # Entry point
```

## .env

```env
ANTHROPIC_API_KEY=sk-ant-xxxxx
MODEL_NAME=claude-sonnet-4-20250514
MAX_TOKENS=4096
```

## config.yaml

```yaml
model: claude-sonnet-4-20250514
max_tokens: 4096

scoring:
  weights:
    coverage: 0.30
    severity: 0.30
    automation_ready: 0.20
    manual_priority: 0.20
  pass_threshold: 6.0

output:
  format: markdown
  save_history: true
  history_dir: ./history
  output_dir: ./output

team:
  platform: both           # unity_csharp | php | both
  size: "5-10"
  priority_focus: all      # all | p0_only | p0_p1
  tc_count: 10
```

## parser_agent.py

```python
from langchain_anthropic import ChatAnthropic
from langchain.prompts import ChatPromptTemplate
from langchain.output_parsers import JsonOutputParser
from pydantic import BaseModel
from typing import List, Optional
import os

class APIEndpoint(BaseModel):
    method: str
    path: str
    description: str

class ParsedFeature(BaseModel):
    feature_name: str
    actors: List[str]
    happy_paths: List[dict]
    edge_cases: List[str]
    business_rules: List[str]
    api_endpoints: List[APIEndpoint]
    platforms: List[str]
    complexity: str

SYSTEM_PROMPT = """Bạn là QA Analyst chuyên về mobile game (Unity C# client + PHP backend).
Nhiệm vụ: Phân tích tài liệu tính năng và trích xuất thông tin có cấu trúc.
Luôn trả về JSON hợp lệ. KHÔNG dùng markdown. KHÔNG giải thích thêm."""

USER_PROMPT = """Phân tích tài liệu tính năng sau và trả về JSON theo schema:

DOCUMENT:
{document_content}

SCHEMA:
{{
  "feature_name": "string",
  "actors": ["string"],
  "happy_paths": [{{"name": "string", "steps": ["string"]}}],
  "edge_cases": ["string"],
  "business_rules": ["string"],
  "api_endpoints": [{{"method": "GET|POST|PUT|DELETE", "path": "string", "description": "string"}}],
  "platforms": ["unity_client", "php_backend"],
  "complexity": "low|medium|high"
}}

Chỉ trả về JSON. Không có text khác."""

class ParserAgent:
    def __init__(self):
        self.llm = ChatAnthropic(
            model=os.getenv("MODEL_NAME", "claude-sonnet-4-20250514"),
            max_tokens=int(os.getenv("MAX_TOKENS", 4096)),
        )
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", SYSTEM_PROMPT),
            ("human", USER_PROMPT),
        ])
        self.parser = JsonOutputParser()
        self.chain = self.prompt | self.llm | self.parser

    def parse(self, document_content: str) -> dict:
        result = self.chain.invoke({"document_content": document_content})
        return result
```

## generator_agent.py

```python
from langchain_anthropic import ChatAnthropic
from langchain.prompts import ChatPromptTemplate
from langchain.output_parsers import JsonOutputParser
import json, os

SYSTEM_PROMPT = """Bạn là Senior QA Engineer với 5+ năm kinh nghiệm mobile game.
Chuyên về Unity C# (NUnit) và PHP (PHPUnit).
Sinh test cases chất lượng cao, bao phủ đủ happy path và edge cases.
Luôn trả về JSON hợp lệ. KHÔNG dùng markdown. KHÔNG giải thích thêm."""

USER_PROMPT = """Sinh {count} test cases cho tính năng sau:

FEATURE DATA:
{parsed_feature_json}

CONFIG:
- Platform: {platform}
- Priority focus: {priority_focus}
- Team size: {team_size}

SCHEMA mỗi test case:
{{
  "id": "TC-[FEATURE_CODE]-[TYPE]-[NUMBER]",
  "title": "string",
  "type": "Functional|UI|Integration|Performance|Security|Edge case",
  "priority": "P0|P1|P2|P3",
  "preconditions": "string",
  "steps": ["string"],
  "expected": "string",
  "test_data": "string",
  "automation_ready": true,
  "score_coverage": 1,
  "score_severity": 1,
  "score_automation": 1,
  "score_manual": 1,
  "unity_test": "// C# NUnit code",
  "php_test": "// PHPUnit code"
}}

Return: {{"testcases": [...]}}
Chỉ trả về JSON."""

class GeneratorAgent:
    def __init__(self, config: dict):
        self.llm = ChatAnthropic(
            model=os.getenv("MODEL_NAME", "claude-sonnet-4-20250514"),
            max_tokens=int(os.getenv("MAX_TOKENS", 4096)),
        )
        self.config = config
        self.prompt = ChatPromptTemplate.from_messages([
            ("system", SYSTEM_PROMPT),
            ("human", USER_PROMPT),
        ])
        self.parser = JsonOutputParser()
        self.chain = self.prompt | self.llm | self.parser

    def generate(self, parsed_feature: dict) -> list:
        result = self.chain.invoke({
            "count": self.config.get("tc_count", 10),
            "parsed_feature_json": json.dumps(parsed_feature, ensure_ascii=False, indent=2),
            "platform": self.config.get("platform", "both"),
            "priority_focus": self.config.get("priority_focus", "all"),
            "team_size": self.config.get("team_size", "5-10"),
        })
        return result.get("testcases", [])
```

## scorer.py

```python
from typing import List

class Scorer:
    def __init__(self, weights: dict = None):
        self.weights = weights or {
            "coverage": 0.30,
            "severity": 0.30,
            "automation_ready": 0.20,
            "manual_priority": 0.20,
        }
        self.threshold = 6.0

    def score_tc(self, tc: dict) -> dict:
        total = (
            tc.get("score_coverage", 0) * self.weights["coverage"] +
            tc.get("score_severity", 0) * self.weights["severity"] +
            tc.get("score_automation", 0) * self.weights["automation_ready"] +
            tc.get("score_manual", 0) * self.weights["manual_priority"]
        )
        return {
            "tc_id": tc["id"],
            "coverage": tc.get("score_coverage", 0),
            "severity": tc.get("score_severity", 0),
            "automation": tc.get("score_automation", 0),
            "manual": tc.get("score_manual", 0),
            "total": round(total, 1),
            "quality": "good" if total >= self.threshold else "needs_review",
        }

    def score_all(self, testcases: List[dict]) -> dict:
        scores = [self.score_tc(tc) for tc in testcases]
        avg = sum(s["total"] for s in scores) / len(scores) if scores else 0
        return {
            "scores": scores,
            "avg_total": round(avg, 1),
            "good_count": sum(1 for s in scores if s["quality"] == "good"),
            "needs_review_count": sum(1 for s in scores if s["quality"] == "needs_review"),
        }
```

## md_writer.py

```python
from datetime import datetime
import os

def write_qa_testcases(testcases: list, feature_name: str, output_dir: str) -> str:
    lines = [f"# QA Test Cases — {feature_name}", f"*Generated: {datetime.now().strftime('%Y-%m-%d %H:%M')}*\n"]
    for tc in testcases:
        score = round(
            tc.get("score_coverage",0)*0.30 +
            tc.get("score_severity",0)*0.30 +
            tc.get("score_automation",0)*0.20 +
            tc.get("score_manual",0)*0.20, 1
        )
        lines += [
            f"## {tc['id']}: {tc['title']}\n",
            f"- **Priority**: {tc['priority']}",
            f"- **Type**: {tc['type']}",
            f"- **Score**: {score}/10",
            f"- **Automation Ready**: {'Yes' if tc.get('automation_ready') else 'No'}",
            f"- **Preconditions**: {tc.get('preconditions','')}\n",
            "### Steps",
            *[f"{i+1}. {s}" for i,s in enumerate(tc.get('steps',[]))],
            "\n### Expected Result",
            tc.get('expected',''),
            "\n### Test Data",
            tc.get('test_data',''),
            "\n---\n",
        ]
    path = os.path.join(output_dir, "01_qa_testcases.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path

def write_unity_tests(testcases: list, feature_name: str, output_dir: str) -> str:
    class_name = feature_name.replace(" ", "")
    lines = [
        f"// Unity C# Test Cases — {feature_name}",
        "// Generated by QA Agent-Tester\n",
        "using NUnit.Framework;\n",
        f"[TestFixture]",
        f"public class {class_name}Tests",
        "{",
    ]
    for tc in [t for t in testcases if t.get("automation_ready")]:
        lines += [f"\n    // {tc['id']}: {tc['title']}", f"    {tc.get('unity_test','')}"]
    lines.append("}\n")
    path = os.path.join(output_dir, "02_unity_tests.cs")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path

def write_php_tests(testcases: list, feature_name: str, output_dir: str) -> str:
    class_name = feature_name.replace(" ", "")
    lines = [
        "<?php",
        f"// PHP PHPUnit Test Cases — {feature_name}",
        "// Generated by QA Agent-Tester\n",
        "use Tests\\TestCase;\n",
        f"class {class_name}Test extends TestCase",
        "{",
    ]
    for tc in [t for t in testcases if t.get("automation_ready")]:
        lines += [f"\n    // {tc['id']}: {tc['title']}", f"    {tc.get('php_test','')}"]
    lines.append("}\n")
    path = os.path.join(output_dir, "03_php_tests.php")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path

def write_score_report(testcases: list, verify_results: dict,
                       score_data: dict, feature_name: str, output_dir: str) -> str:
    total = len(testcases)
    pass_n  = sum(1 for v in verify_results.values() if v == "pass")
    fail_n  = sum(1 for v in verify_results.values() if v == "fail")
    manual_n = sum(1 for v in verify_results.values() if v == "manual")
    skip_n  = sum(1 for v in verify_results.values() if v == "skip")
    failed_tcs = [tc for tc in testcases if verify_results.get(tc["id"]) == "fail"]
    manual_tcs = [tc for tc in testcases if verify_results.get(tc["id"]) == "manual"]

    lines = [
        f"# Score Report — {feature_name}",
        f"**Date**: {datetime.now().strftime('%Y-%m-%d')} | **Tool**: QA Agent-Tester\n",
        "## Summary",
        f"| Metric | Count | % |",
        f"|--------|-------|---|",
        f"| Total TCs | {total} | 100% |",
        f"| ✅ Passed | {pass_n} | {round(pass_n/total*100) if total else 0}% |",
        f"| ❌ Failed | {fail_n} | {round(fail_n/total*100) if total else 0}% |",
        f"| ⚠️ Manual | {manual_n} | {round(manual_n/total*100) if total else 0}% |",
        f"| ⏭️ Skipped | {skip_n} | {round(skip_n/total*100) if total else 0}% |",
        f"\n**Average Score**: {score_data.get('avg_total', 0)}/10\n",
        "## Scoring Breakdown",
        "| TC ID | Coverage | Severity | Automation | Manual | Total | Quality |",
        "|-------|----------|----------|------------|--------|-------|---------|",
        *[f"| {s['tc_id']} | {s['coverage']} | {s['severity']} | {s['automation']} | {s['manual']} | {s['total']} | {'✅' if s['quality']=='good' else '⚠️'} |"
          for s in score_data.get("scores", [])],
        "\n## Failed TCs — Cần xử lý ngay",
    ]
    if failed_tcs:
        lines += ["| ID | Title | Priority |", "|-----|-------|----------|",
                  *[f"| {tc['id']} | {tc['title']} | {tc['priority']} |" for tc in failed_tcs]]
    else:
        lines.append("Không có TC nào bị failed 🎉")

    lines += ["\n## Manual Test Queue", "| ID | Title | Lý do manual |", "|-----|-------|--------------|"]
    if manual_tcs:
        lines += [f"| {tc['id']} | {tc['title']} | Cần verify UI/UX |" for tc in manual_tcs]
    else:
        lines.append("Không có TC nào cần manual test")

    path = os.path.join(output_dir, "04_score_report.md")
    with open(path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    return path
```

## run.py (Entry point)

```python
#!/usr/bin/env python3
"""
QA Agent-Tester — LangChain Entry Point
Usage: python run.py --doc path/to/feature.md --feature "Login Feature"
"""

import argparse, json, os, yaml
from datetime import datetime
from dotenv import load_dotenv

from agents.parser_agent import ParserAgent
from agents.generator_agent import GeneratorAgent
from agents.scorer import Scorer
from tools.md_writer import (
    write_qa_testcases, write_unity_tests,
    write_php_tests, write_score_report
)

load_dotenv()

def load_config(path: str = "config.yaml") -> dict:
    with open(path) as f:
        return yaml.safe_load(f)

def main():
    parser = argparse.ArgumentParser(description="QA Agent-Tester")
    parser.add_argument("--doc", required=True, help="Path to feature document")
    parser.add_argument("--feature", required=True, help="Feature name")
    parser.add_argument("--verify", help="Path to verify results JSON (optional)")
    args = parser.parse_args()

    config = load_config()
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    feat_slug = args.feature.replace(" ", "_").lower()
    run_dir = f"output/{feat_slug}_{ts}"
    os.makedirs(run_dir, exist_ok=True)
    os.makedirs("history", exist_ok=True)

    # Read document
    with open(args.doc, "r", encoding="utf-8") as f:
        doc_content = f.read()

    print(f"[1/4] Parsing document: {args.doc}")
    parsed = ParserAgent().parse(doc_content)

    print(f"[2/4] Generating test cases...")
    testcases = GeneratorAgent(config.get("team", {})).generate(parsed)

    print(f"[3/4] Writing output files to {run_dir}/")
    write_qa_testcases(testcases, args.feature, run_dir)
    write_unity_tests(testcases, args.feature, run_dir)
    write_php_tests(testcases, args.feature, run_dir)

    # Load verify results if provided
    verify_results = {}
    if args.verify and os.path.exists(args.verify):
        with open(args.verify) as f:
            verify_results = json.load(f).get("results", {})

    print(f"[4/4] Scoring and generating report...")
    scorer = Scorer(config.get("scoring", {}).get("weights"))
    score_data = scorer.score_all(testcases)
    write_score_report(testcases, verify_results, score_data, args.feature, run_dir)

    # Save history
    history_entry = {
        "run_id": f"{feat_slug}_{ts}",
        "feature": args.feature,
        "timestamp": datetime.now().isoformat(),
        "total_tcs": len(testcases),
        "avg_score": score_data["avg_total"],
        "model": config.get("model"),
        "output_dir": run_dir,
    }
    history_path = f"history/{feat_slug}_{ts}.json"
    with open(history_path, "w") as f:
        json.dump(history_entry, f, indent=2)

    print(f"\n✅ Done!")
    print(f"   Output: {run_dir}/")
    print(f"   TCs generated: {len(testcases)}")
    print(f"   Avg score: {score_data['avg_total']}/10")
    print(f"   History: {history_path}")

if __name__ == "__main__":
    main()
```

## Sử dụng

```bash
# Chạy cơ bản
python run.py --doc ./docs/login_feature.md --feature "User Login"

# Có kết quả verify
python run.py --doc ./docs/login_feature.md --feature "User Login" --verify ./verify_results.json

# verify_results.json format
{
  "results": {
    "TC-AUTH-F-001": "pass",
    "TC-AUTH-F-002": "fail",
    "TC-AUTH-E-003": "manual"
  }
}
```
