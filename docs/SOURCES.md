# Source Reference Index

Mapping từ docs/ → skills. Mỗi skill được tạo từ các nguồn tham khảo bên dưới.

---

## Unity Skills

### unity-code-audit
- [Unity Performance Checklist - Lite v2.2.pdf](unity/Unity%20Performance%20Checklist%20-%20Lite%20v2.2.pdf) — Checklist gốc từ Unity performance guide
- [scripts-verify-checklist.md](unity/scripts-verify-checklist.md) — Checklist scripts đã chuẩn hoá
- [unity_anr_crash_checklist.md](unity/unity_anr_crash_checklist.md) — ANR/crash prevention items
- Source: Knowledge Items (KI) từ project thực tế
  - `unity_mobile_code_review` — workflow, refactoring patterns, mobile engineering rules
  - `osa_grid_adapter_implementation` — state management, pagination, race condition prevention
  - `unity_ui_utility_helpers` — lifecycle safety patterns
- Verification patterns derived from SDU project audit evaluation (2026-03-20)

### unity-asset-audit
- [Unity Performance Checklist - Lite v2.2.pdf](unity/Unity%20Performance%20Checklist%20-%20Lite%20v2.2.pdf) — Checklist gốc từ Unity performance guide
- [asset-verify-checklist.md](unity/asset-verify-checklist.md) — Checklist assets đã chuẩn hoá

### unity-ui-performance
- [thegamedev_guru_level_3_unity_ui_development_diagram.pdf](unity/thegamedev_guru_level_3_unity_ui_development_diagram.pdf) — UI development best practices diagram

### unity-csharp-standards
- Source: Knowledge Items (KI) từ project thực tế
  - `unity_mobile_code_review` — C# conventions, design review, performance rules

### unity-dotween-safety
- Source: Knowledge Items (KI) từ project thực tế
  - `unity_mobile_code_review` — DOTween async safety, leak case studies

### unity-async-patterns
- Source: Knowledge Items (KI) từ project thực tế
  - `unity_mobile_code_review` — async/await lifecycle, cancellation patterns

### unity-addressables
- Source: Knowledge Items (KI) từ project thực tế
  - `unity_resource_management` — asset lifecycle, Addressables performance

### unity-editor-tools
- Source: Knowledge Items (KI) từ project thực tế
  - `unity_mcp_tooling_standards` — editor automation patterns

---

## QA Skills

### unity-qa-parser, unity-qa-generator, unity-qa-verifier, unity-qa-scorer
- [QA_Agent_Tester_Full_Design.docx](agent-qa/QA_Agent_Tester_Full_Design.docx) — Full system design
- [01_system_overview.md](agent-qa/01_system_overview.md) — System architecture
- [02_prompt_guide.md](agent-qa/02_prompt_guide.md) — Prompt engineering guide
- [03_langchain_guide.md](agent-qa/03_langchain_guide.md) — LangChain implementation
- [04_n8n_dify_guide.md](agent-qa/04_n8n_dify_guide.md) — n8n/Dify integration
- [05_output_templates.md](agent-qa/05_output_templates.md) — Output format templates
