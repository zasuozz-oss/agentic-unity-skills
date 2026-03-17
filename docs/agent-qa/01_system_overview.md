# QA Agent-Tester — System Overview

## Mục tiêu

Tự động hóa quy trình QA cho mobile game (Unity C# + PHP Backend) theo pipeline:

```
Document đầu vào → Phân tích → Sinh Test Cases → Dev Integration → Verify → Score → Report
```

## Kiến trúc tổng thể

```
┌─────────────────────────────────────────────────────────────┐
│                      QA Agent-Tester                         │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌────────┐ │
│  │  Parser  │───►│Generator │───►│ Verifier │───►│ Scorer │ │
│  └──────────┘    └──────────┘    └──────────┘    └────────┘ │
│       │               │               │               │      │
│  Notion/PDF      Claude API      Test Results     4-criteria │
│  Word/MD/        (LLM Core)      JSON input       Scoring    │
│  Figma                                                        │
└─────────────────────────────────────────────────────────────┘
           │                                    │
    ┌──────▼──────┐                    ┌────────▼───────┐
    │   history/  │                    │    output/     │
    │  (JSON log) │                    │  (.md files)   │
    └─────────────┘                    └────────────────┘
```

## 4 Phases

| Phase | Tên | Input | Output |
|-------|-----|-------|--------|
| 1 | Document Parsing | Notion/PDF/Word/MD/Figma | Structured feature JSON |
| 2 | TC Generation | Feature JSON + Config | QA TCs + Dev TCs (.md) |
| 3 | Verify | Dev test results | pass/fail/manual/skip/flaky |
| 4 | Scoring | Verify results | Score report (.md) |

## Team roles

| Role | Công việc trong hệ thống |
|------|--------------------------|
| QA Lead | Review document đầu vào, approve TCs |
| QA Engineer | Chạy agent, verify manual TCs |
| Dev Unity | Nhận `*_unity_tests.cs`, chạy NUnit |
| Dev PHP | Nhận `*_php_tests.php`, chạy PHPUnit |
| PM | Đọc `score_summary.md` cuối sprint |

## Platform hỗ trợ build local agent

- **LangChain** (Python) — recommended cho dev Python
- **n8n** — recommended cho no-code/low-code workflow
- **Dify** — recommended cho visual AI workflow
- **AutoGen** — recommended cho multi-agent setup
- **LlamaIndex** — recommended nếu cần RAG trên documents
- **Flowise** — alternative cho n8n, dễ setup hơn
