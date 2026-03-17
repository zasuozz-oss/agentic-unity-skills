# QA Agent-Tester — Prompt Engineering Guide

## Nguyên tắc thiết kế prompt

Agent hoạt động qua 2 prompt chính. Mỗi prompt được thiết kế để trả về JSON thuần — không có markdown wrapper, không có text thừa.

---

## Prompt 1: Document Parser

**Mục đích:** Phân tích tài liệu tính năng và trích xuất cấu trúc.

**System prompt:**
```
Bạn là QA Analyst chuyên về mobile game (Unity C# client + PHP backend).
Nhiệm vụ: Phân tích tài liệu tính năng và trích xuất thông tin có cấu trúc.
Luôn trả về JSON hợp lệ. KHÔNG dùng markdown. KHÔNG giải thích thêm.
```

**User prompt template:**
```
Phân tích tài liệu tính năng sau và trả về JSON theo schema:

DOCUMENT:
{{document_content}}

SCHEMA:
{
  "feature_name": "string",
  "actors": ["string"],
  "happy_paths": [
    {
      "name": "string",
      "steps": ["string"]
    }
  ],
  "edge_cases": ["string"],
  "business_rules": ["string"],
  "api_endpoints": [
    {
      "method": "GET|POST|PUT|DELETE",
      "path": "string",
      "description": "string"
    }
  ],
  "platforms": ["unity_client", "php_backend"],
  "complexity": "low|medium|high"
}

Chỉ trả về JSON. Không có text khác.
```

**Ví dụ output:**
```json
{
  "feature_name": "User Login with Google OAuth",
  "actors": ["Player", "Auth Server", "Unity Client", "PHP Backend"],
  "happy_paths": [
    {
      "name": "Standard login flow",
      "steps": [
        "Player mở app, thấy màn hình login",
        "Player nhấn Login with Google",
        "Google OAuth popup xuất hiện",
        "Player chọn tài khoản và approve",
        "App nhận access token",
        "PHP backend validate token và tạo session",
        "Unity client nhận session_id và player_data",
        "Player vào main menu"
      ]
    }
  ],
  "edge_cases": [
    "Token hết hạn sau 1 giờ",
    "Tài khoản bị ban (status=banned)",
    "Không có kết nối internet",
    "First-time login vs returning player"
  ],
  "business_rules": [
    "Tài khoản bị ban không được vào game",
    "New player trigger onboarding tutorial",
    "Session hết hạn sau 24h không hoạt động"
  ],
  "api_endpoints": [
    { "method": "POST", "path": "/api/auth/google", "description": "Validate Google token" },
    { "method": "GET",  "path": "/api/player/profile", "description": "Fetch player data" },
    { "method": "POST", "path": "/api/auth/refresh", "description": "Refresh session token" }
  ],
  "platforms": ["unity_client", "php_backend"],
  "complexity": "medium"
}
```

---

## Prompt 2: Test Case Generator

**Mục đích:** Sinh QA test cases và developer test cases từ parsed feature.

**System prompt:**
```
Bạn là Senior QA Engineer với 5+ năm kinh nghiệm mobile game.
Chuyên về Unity C# (NUnit) và PHP (PHPUnit).
Nhiệm vụ: Sinh test cases chất lượng cao, bao phủ đủ happy path và edge cases.
Chấm điểm mỗi TC theo 4 tiêu chí: coverage, severity, automation_ready, manual_priority.
Luôn trả về JSON hợp lệ. KHÔNG dùng markdown. KHÔNG giải thích thêm.
```

**User prompt template:**
```
Sinh {{count}} test cases cho tính năng sau:

FEATURE DATA:
{{parsed_feature_json}}

CONFIG:
- Platform: {{platform}}  (unity_csharp | php | both)
- Priority focus: {{priority_focus}}  (all | p0_only | p0_p1)
- Team size: {{team_size}}

SCHEMA mỗi test case:
{
  "id": "TC-[FEATURE_CODE]-[TYPE]-[NUMBER]",
  "title": "string (mô tả ngắn gọn)",
  "type": "Functional|UI|Integration|Performance|Security|Edge case",
  "priority": "P0|P1|P2|P3",
  "preconditions": "string",
  "steps": ["string"],
  "expected": "string (kết quả mong đợi chi tiết)",
  "test_data": "string",
  "automation_ready": true|false,
  "score_coverage": 1-10,
  "score_severity": 1-10,
  "score_automation": 1-10,
  "score_manual": 1-10,
  "unity_test": "// C# NUnit code snippet",
  "php_test": "// PHPUnit code snippet"
}

Scoring guide:
- score_coverage: 10=happy+all edges, 7=happy+some edges, 4=happy only, 1=incomplete
- score_severity: 10=crash/data loss/security, 8=core broken, 5=wrong result, 2=cosmetic
- score_automation: 10=pure unit test, 7=needs mock, 4=complex integration, 1=manual only
- score_manual: 10=UX/animation/platform-specific, 7=UX verify recommended, 4=optional, 1=skip if auto passes

Return: { "testcases": [ ... ] }
Chỉ trả về JSON. Không có text khác.
```

---

## Prompt 3: Verify Classifier (optional)

**Mục đích:** Tự động phân loại kết quả test từ log text.

**User prompt template:**
```
Đọc kết quả test log sau và phân loại từng test case:

TEST LOG:
{{test_log_output}}

TEST CASE IDs cần phân loại:
{{tc_id_list}}

Status có thể là:
- "pass": Test thành công, không lỗi
- "fail": Assert thất bại hoặc exception
- "manual": Không thể auto test (UI, animation, haptic)
- "skip": Dependency chưa sẵn sàng
- "flaky": Pass/fail không nhất quán

Return: { "results": { "TC-001": "pass", "TC-002": "fail", ... } }
```

---

## Scoring Formula

```
Score = (coverage × 0.30) + (severity × 0.30) + (automation × 0.20) + (manual × 0.20)

Threshold: Score ≥ 6.0 = TC chất lượng tốt
           Score < 6.0 = TC cần review lại
```

---

## Quy ước đặt ID test case

```
TC-[FEATURE_CODE]-[TYPE_CODE]-[NUMBER]

Feature codes:
  AUTH   Authentication / Login
  INV    Inventory
  SHOP   Shop / IAP
  MATCH  Matchmaking / Game session
  UI     UI components
  API    Backend API

Type codes:
  F   Functional
  U   UI / Visual
  I   Integration
  P   Performance
  S   Security
  E   Edge case

Ví dụ: TC-AUTH-F-001, TC-SHOP-I-003, TC-API-S-007
```
