# QA Agent-Tester — n8n & Dify Workflow Guide

---

## Phần 1: n8n Workflow

### Cài đặt n8n local

```bash
# Docker (recommended)
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Hoặc npm
npm install -g n8n
n8n start
```

Truy cập: http://localhost:5678

---

### Workflow: QA Test Case Generator

**Nodes theo thứ tự:**

```
[Webhook / Manual Trigger]
         │
[Set Variables]        ← feature_name, doc_content, platform, count
         │
[HTTP Request: Claude API] ← Phase 1: Parse document
         │
[Parse JSON]           ← Extract parsed_feature
         │
[HTTP Request: Claude API] ← Phase 2: Generate test cases
         │
[Parse JSON]           ← Extract testcases[]
         │
[Code Node: Scorer]    ← Tính score cho từng TC
         │
[Code Node: MD Builder] ← Build markdown content
         │
[Write Binary File]    ← Lưu .md files
         │
[Send Response / Slack Notification]
```

---

### Node configs chi tiết

#### Node: Set Variables
```json
{
  "feature_name": "={{ $json.feature_name }}",
  "doc_content": "={{ $json.doc_content }}",
  "platform": "both",
  "tc_count": 10,
  "priority_focus": "all",
  "anthropic_key": "={{ $credentials.anthropicApi.apiKey }}"
}
```

#### Node: HTTP Request — Phase 1 (Parse)
```
Method: POST
URL: https://api.anthropic.com/v1/messages
Headers:
  x-api-key: {{ $vars.anthropic_key }}
  anthropic-version: 2023-06-01
  content-type: application/json

Body (JSON):
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 2048,
  "system": "Bạn là QA Analyst. Trả về JSON thuần, không markdown.",
  "messages": [
    {
      "role": "user",
      "content": "Phân tích tài liệu này và trả về JSON:\n\n{{ $vars.doc_content }}\n\nSchema: {feature_name, actors[], happy_paths[], edge_cases[], business_rules[], api_endpoints[], platforms[], complexity}"
    }
  ]
}
```

#### Node: HTTP Request — Phase 2 (Generate)
```
Body (JSON):
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 4096,
  "system": "Bạn là Senior QA Engineer. Trả về JSON thuần.",
  "messages": [
    {
      "role": "user",
      "content": "Sinh {{ $vars.tc_count }} test cases.\nFeature: {{ JSON.stringify($node['Parse Phase 1'].json) }}\nPlatform: {{ $vars.platform }}\nReturn: {\"testcases\":[...]}"
    }
  ]
}
```

#### Node: Code — Scorer
```javascript
const items = $input.all();
const testcases = items[0].json.testcases || [];

const weights = { coverage: 0.30, severity: 0.30, automation: 0.20, manual: 0.20 };
const THRESHOLD = 6.0;

const scored = testcases.map(tc => {
  const total = (
    (tc.score_coverage || 0) * weights.coverage +
    (tc.score_severity || 0) * weights.severity +
    (tc.score_automation || 0) * weights.automation +
    (tc.score_manual || 0) * weights.manual
  );
  return {
    ...tc,
    score_total: Math.round(total * 10) / 10,
    quality: total >= THRESHOLD ? 'good' : 'needs_review'
  };
});

const avgScore = scored.reduce((a,t)=>a+t.score_total,0) / scored.length;

return [{ json: {
  testcases: scored,
  summary: {
    total: scored.length,
    good: scored.filter(t=>t.quality==='good').length,
    avg_score: Math.round(avgScore * 10) / 10
  }
}}];
```

#### Node: Code — MD Builder
```javascript
const { testcases, summary } = $input.first().json;
const featureName = $vars.feature_name;

// QA Test Cases MD
let qaContent = `# QA Test Cases — ${featureName}\n\n`;
testcases.forEach(tc => {
  qaContent += `## ${tc.id}: ${tc.title}\n\n`;
  qaContent += `- **Priority**: ${tc.priority}\n`;
  qaContent += `- **Type**: ${tc.type}\n`;
  qaContent += `- **Score**: ${tc.score_total}/10\n`;
  qaContent += `- **Preconditions**: ${tc.preconditions}\n\n`;
  qaContent += `### Steps\n`;
  (tc.steps || []).forEach((s,i) => qaContent += `${i+1}. ${s}\n`);
  qaContent += `\n### Expected\n${tc.expected}\n\n---\n\n`;
});

// Unity Tests
let unityContent = `// Unity C# — ${featureName}\nusing NUnit.Framework;\n\n`;
unityContent += `[TestFixture]\npublic class ${featureName.replace(/\s/g,'')}Tests\n{\n`;
testcases.filter(t=>t.automation_ready).forEach(tc => {
  unityContent += `\n    // ${tc.id}: ${tc.title}\n    ${tc.unity_test}\n`;
});
unityContent += '}\n';

// PHP Tests
let phpContent = `<?php\n// PHP PHPUnit — ${featureName}\n\n`;
phpContent += `class ${featureName.replace(/\s/g,'')}Test extends TestCase\n{\n`;
testcases.filter(t=>t.automation_ready).forEach(tc => {
  phpContent += `\n    // ${tc.id}: ${tc.title}\n    ${tc.php_test}\n`;
});
phpContent += '}\n';

return [{ json: { qaContent, unityContent, phpContent, summary }}];
```

---

## Phần 2: Dify Workflow

### Cài đặt Dify local

```bash
git clone https://github.com/langgenius/dify.git
cd dify/docker
cp .env.example .env
docker compose up -d
```

Truy cập: http://localhost/

---

### Tạo Workflow trong Dify

#### Bước 1: Tạo Workflow App mới

```
App Type: Workflow
Tên: QA Test Case Generator
```

#### Bước 2: Nodes cần tạo

```
[Start]
  - Input: document_content (paragraph)
  - Input: feature_name (short text)
  - Input: platform (select: both/unity/php)
  - Input: tc_count (number, default: 10)

[LLM Node 1 — Parse Document]
  Model: claude-sonnet-4-20250514
  System: "Bạn là QA Analyst. Trả về JSON thuần."
  User: "Phân tích document:\n{{#start.document_content#}}\n\nReturn JSON: {feature_name, actors[], ...}"

[Code Node — Extract JSON]
  Language: Python
  Code:
    import json
    result = json.loads(arg1)
    return {"parsed_feature": json.dumps(result)}

[LLM Node 2 — Generate TCs]
  Model: claude-sonnet-4-20250514
  Max tokens: 4096
  System: "Bạn là Senior QA Engineer. Trả về JSON thuần."
  User: "Sinh {{#start.tc_count#}} TCs cho:\n{{#code_extract.parsed_feature#}}\n\nPlatform: {{#start.platform#}}\nReturn: {\"testcases\":[...]}"

[Code Node — Score & Format]
  Language: Python
  Code: (xem bên dưới)

[End]
  Output: qa_markdown (text)
  Output: unity_code (text)
  Output: php_code (text)
  Output: summary (object)
```

#### Code Node — Score & Format (Dify Python)

```python
import json

def main(testcases_json: str, feature_name: str) -> dict:
    testcases = json.loads(testcases_json).get("testcases", [])
    weights = {"coverage":0.30,"severity":0.30,"automation":0.20,"manual":0.20}

    qa_lines = [f"# QA Test Cases — {feature_name}\n"]
    unity_lines = [f"// Unity C# — {feature_name}", "using NUnit.Framework;\n",
                   f"[TestFixture]", f"public class {feature_name.replace(' ','')}Tests", "{"]
    php_lines = [f"<?php", f"// PHP — {feature_name}", "",
                 f"class {feature_name.replace(' ','')}Test extends TestCase", "{"]

    scores = []
    for tc in testcases:
        total = round(
            tc.get("score_coverage",0)*weights["coverage"] +
            tc.get("score_severity",0)*weights["severity"] +
            tc.get("score_automation",0)*weights["automation"] +
            tc.get("score_manual",0)*weights["manual"], 1
        )
        scores.append(total)

        qa_lines += [f"## {tc['id']}: {tc['title']}\n",
                     f"- **Priority**: {tc['priority']}",
                     f"- **Score**: {total}/10",
                     f"- **Preconditions**: {tc.get('preconditions','')}\n",
                     "### Steps",
                     *[f"{i+1}. {s}" for i,s in enumerate(tc.get('steps',[]))],
                     f"\n### Expected\n{tc.get('expected','')}\n\n---\n"]

        if tc.get("automation_ready"):
            unity_lines += [f"", f"    // {tc['id']}", f"    {tc.get('unity_test','')}"]
            php_lines += [f"", f"    // {tc['id']}", f"    {tc.get('php_test','')}"]

    unity_lines.append("}")
    php_lines.append("}")

    avg = round(sum(scores)/len(scores), 1) if scores else 0

    return {
        "qa_markdown": "\n".join(qa_lines),
        "unity_code": "\n".join(unity_lines),
        "php_code": "\n".join(php_lines),
        "summary": json.dumps({
            "total": len(testcases),
            "avg_score": avg,
            "good": sum(1 for s in scores if s >= 6.0)
        })
    }
```

---

## Phần 3: Flowise (Alternative cho n8n)

### Cài đặt

```bash
npm install -g flowise
npx flowise start --port=3000
```

### Chain cần tạo trong Flowise

```
ChatAnthropic Node
  ├─ model: claude-sonnet-4-20250514
  ├─ temperature: 0
  └─ maxTokens: 4096

PromptTemplate (Phase 1 - Parse)
  └─ Template: (dùng prompt từ 02_prompt_guide.md)

LLMChain (Phase 1)
  ├─ llm: ChatAnthropic
  └─ prompt: PromptTemplate Phase 1

PromptTemplate (Phase 2 - Generate)
  └─ Template: (dùng prompt từ 02_prompt_guide.md)

LLMChain (Phase 2)
  ├─ llm: ChatAnthropic
  └─ prompt: PromptTemplate Phase 2

Custom Function Node (Scorer + MD Writer)
  └─ Code: JavaScript scorer
```

---

## So sánh platform

| Tiêu chí | LangChain | n8n | Dify | Flowise |
|----------|-----------|-----|------|---------|
| Setup độ khó | Medium | Easy | Easy | Easy |
| Code flexibility | Cao nhất | Medium | Medium | Medium |
| Visual workflow | Không | Có | Có | Có |
| Local hosting | Có | Có | Có | Có |
| Python native | Có | Không | Có | Không |
| Phù hợp cho | Dev Python | Ops/QA | Non-dev | Non-dev |
| Tích hợp Notion | Thủ công | Node built-in | Built-in | Plugin |
| Recommended cho team 5-10 | ✅ | ✅ | ✅ | ⚠️ |
