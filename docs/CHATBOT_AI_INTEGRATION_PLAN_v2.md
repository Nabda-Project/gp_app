# Chatbot → AI Report Integration Plan (v2)

**Based on:** actual `med.py`, `app.py`, `stage_questions.py` source code  
**Date:** May 2026

---

## What I Found in the Code

After reading med.py thoroughly, the system is more complex than a simple 7-stage form. Here's what's actually happening:

```
med.py is a STATE MACHINE with 6 stages:
  1. DEMOGRAPHICS     → age, sex, pregnancy, weight, height
  2. HISTORY          → cardiac history, workups, chronic conditions, meds, family, lifestyle
  3. SYMPTOM_SELECTION→ patient picks symptoms from 16 options (multi-choice)
  4. SYMPTOM_LOOP     → FOR EACH selected symptom, asks 5-10 detailed questions
                         (severity, duration, pattern, triggers, relieving factors,
                          + symptom-specific extras like radiation for chest pain)
  5. RED_FLAG_SCREENING→ exertional chest pain, syncope during exercise
  6. FREE_TEXT        → anything else the patient wants to add
```

The data is collected into a nested JSON, then `_build_arabic_narrative()` converts it into **plain Arabic text** — a continuous narrative like a patient talking to a doctor.

The AI server is **NOT synchronous**. It uses an **async polling pattern**:
```
POST /generate  →  {"poll_url": "/jobs/<id>"}     (returns immediately)
GET  /jobs/<id> →  {"status": "processing"}        (keep polling every 2s)
GET  /jobs/<id> →  {"status": "completed", "result": {...}}  (done!)
```

**AI Server Details (from med.py):**
```
URL:     http://100.51.212.220:8000/generate
API Key: REMOVED
Header:  X-API-Key
Body:    {"text": "<arabic narrative>"}
Timeout: up to 5 minutes (300s) with 2-second polling interval
```

---

## Architecture Decision: Two Approaches

You need to decide which approach to take. This decision affects everything.

### Approach A — Keep Flask, Flutter Talks to Flask via Spring Boot (Minimal Changes)

```
Flutter  ──POST /api/chatbot/message──►  Spring Boot  ──proxy──►  Flask (med.py)
Flutter  ◄── question JSON ──────────────────────────────────────────────────┘

(Flask runs the state machine, asks questions one by one)
(When done, Flask calls /api/chatbot/complete → Spring Boot → AI server)
```

**This is what you already have.** The Flutter developer just needs to build a chat UI that sends messages and displays the returned questions. The state machine stays in Flask.

**Pros:** Least work. Flask is already working.  
**Cons:** You depend on Flask being deployed. Two servers to maintain.

### Approach B — Move Everything to Spring Boot, Kill Flask (More Work, Cleaner)

```
Flutter  ──POST /api/chatbot/message──►  Spring Boot (runs the state machine)
Flutter  ◄── question JSON ─────────────────────┘

(Spring Boot manages conversation state, asks questions one by one)
(When done, Spring Boot builds narrative → calls AI server → saves report)
```

**This means rewriting med.py's state machine in Java.** That's ~600 lines of logic including the symptom loop, dependency engine, question banks, and all the Arabic translation maps.

**Pros:** One server. No Flask dependency.  
**Cons:** Massive rewrite. Risk of introducing bugs before the demo.

### Approach C — Flutter Handles the UI Flow, Sends Final JSON to Spring Boot (RECOMMENDED)

```
Flutter (has all questions hardcoded in Dart)
  → walks the patient through all stages locally
  → handles the symptom loop (for each selected symptom, show sub-questions)
  → collects everything into the same nested JSON structure as med.py
  → POST /api/ai/consult/{patientId} with the full JSON

Spring Boot:
  → receives the JSON
  → fetches patient data from DB (or uses what Flutter sent)
  → calls _build_arabic_narrative() logic (rewritten in Java)
  → sends narrative to AI server (with polling)
  → saves report to database
```

**This is the best balance.** Flutter handles the UI/UX flow. Spring Boot handles the AI call and data persistence. Flask can be retired.

---

## THE PLAN (Approach C)

---

## Part 1: What the Flutter Developer Builds

### 1.1 The Question Flow (Hardcoded in Dart)

The Flutter developer needs to recreate the same question flow from med.py, but as local UI screens. No network calls during the chatbot — everything happens locally on the phone until the final submit.

**Structure it as a Dart model:**

```dart
// The question types match med.py exactly
enum QuestionType { number, choice, multiChoice, text }

class ChatbotQuestion {
  final String field;          // e.g. "demographics.age"
  final String question;       // Arabic text
  final QuestionType type;
  final Map<String, String>? options;  // {Arabic: englishCode}
  final double? min, max;      // for number type
  final DependsOn? dependsOn;  // conditional logic
}
```

### 1.2 Stage-by-Stage Screens

**Stage 1 — DEMOGRAPHICS (5 questions max)**

| Field | Arabic Question | Type | Notes |
|-------|----------------|------|-------|
| `demographics.age` | كم العمر بالسنوات؟ | number | min: 1, max: 110 |
| `demographics.sex` | الجنس؟ | choice | ذكر/أنثى |
| `demographics.pregnancy` | هل أنتِ حامل حالياً...؟ | choice | **Only show if sex = female** |
| `demographics.weight_kg` | ما هو الوزن بالكيلوجرام؟ | number | min: 3, max: 300 |
| `demographics.height_cm` | ما هو الطول بالسنتيمتر؟ | number | min: 50, max: 250 |

**Stage 2 — HISTORY (7 questions, some conditional)**

| Field | Arabic Question | Type | Notes |
|-------|----------------|------|-------|
| `history.known_cardiac` | هل سبق تشخيصك بمرض في القلب؟ | multi_choice | 8 options |
| `history.prior_workup` | هل قمت سابقاً بفحوصات للقلب؟ | multi_choice | 6 options |
| `history.chronic_conditions` | هل تعاني من أي حالات مزمنة؟ | multi_choice | 9 options |
| `history.medications` | ما الأدوية التي تتناولها؟ | text | Free text |
| `history.med_adherence` | هل توقفت عن أدويتك مؤخراً؟ | choice | **Only if medications ≠ "لا شيء"** |
| `history.family_history` | هل يعاني أقاربك من مرض قلب؟ | choice | yes/no/unknown |
| `history.lifestyle` | هل ينطبق عليك أي من التالي؟ | multi_choice | 6 options (smoking, caffeine, etc.) |

**Stage 3 — SYMPTOM SELECTION (1 question)**

| Field | Arabic Question | Type | Notes |
|-------|----------------|------|-------|
| `symptom_selection.chosen` | ما الأعراض التي تشعر بها؟ | multi_choice | **16 symptoms** — this determines Stage 4 |

The 16 symptoms:
- خفقان (palpitations)
- عدم انتظام (irregular)
- ألم أو ضغط في الصدر (chest_pain)
- ألم في منطقة القلب (heart_pain)
- نغزات/وخز (stabs)
- ضيق في التنفس (dyspnea)
- دوخة/دوار (dizziness)
- إغماء (fainting)
- تعب/إرهاق (fatigue)
- تعرق (sweating)
- غثيان/قيء (nausea)
- ألم ينتشر للذراع (arm_radiation)
- تنميل (tingling)
- رجفة (tremor)
- برودة الأطراف (cold_extremities)
- عرض آخر (other)

**Stage 4 — SYMPTOM LOOP (Dynamic — this is the complex part)**

For EACH symptom the patient selected in Stage 3, ask these sub-questions:

**Common questions (asked for every symptom):**

| Field pattern | Question | Type |
|--------------|----------|------|
| `symptom_detail.{code}.severity` | ما شدة [{label}]؟ | choice (4 options) |
| `symptom_detail.{code}.duration_general` | منذ متى وأنت تعاني من [{label}]؟ | choice (6 options) |
| `symptom_detail.{code}.pattern` | كيف يأتي [{label}]؟ | choice (3 options) |
| `symptom_detail.{code}.episode_duration` | كم تستمر النوبة؟ | choice (5 options) — **only if pattern = episodic** |
| `symptom_detail.{code}.triggers` | متى يحدث [{label}]؟ | multi_choice (12 options) |
| `symptom_detail.{code}.relieving_factors` | ما الذي يخفف [{label}]؟ | multi_choice (6 options) |

**Extra questions (only for specific symptoms):**

| Symptom | Extra Questions |
|---------|----------------|
| chest_pain | radiation (multi), exertional (yes/no), quality (5 types) |
| heart_pain | radiation (multi), exertional (yes/no) |
| stabs | location (4 options) |
| palpitations | rate_feel (4 options) |
| irregular | skip_or_extra (4 options) |
| dyspnea | orthopnea (yes/no), exertion_level (4 options) |
| dizziness | type (4 options: vertigo/lightheaded/presyncope/imbalance) |
| fainting | full_loss (2 options), recovery_time (3 options) |
| arm_radiation | side (left/right/both) |
| fatigue | exertional_change (yes/slightly/no) |

If the patient selected "عرض آخر" (other), first ask how many extra symptoms (1-10), then ask the name of each, then ask the common questions for each.

**Stage 5 — RED FLAGS (2 questions, conditional)**

| Field | Question | Type | Condition |
|-------|----------|------|-----------|
| `red_flags.exertional_chest` | هل يوجد ألم صدر يزداد مع المجهود؟ | choice | **Only if chest_pain/heart_pain NOT in selected symptoms** |
| `red_flags.syncope_exertion` | هل أغمي عليك أثناء الرياضة؟ | choice | Always asked |

**Stage 6 — FREE TEXT (1 question)**

| Field | Question | Type |
|-------|----------|------|
| `free_text.additional` | هل هناك شيء آخر تود إضافته؟ | text |

### 1.3 The JSON the Flutter App Sends

After all stages are done, Flutter builds this JSON and sends it to Spring Boot:

```
POST /api/ai/consult/{patientId}
Authorization: Bearer {jwt_token}
Content-Type: application/json
```

```json
{
  "demographics": {
    "age": 45,
    "sex": "male",
    "weight_kg": 85,
    "height_cm": 175
  },
  "history": {
    "known_cardiac": ["none"],
    "prior_workup": ["ecg", "echo"],
    "chronic_conditions": ["htn", "chol"],
    "medications": "أملوديبين 5 ملجم يومياً",
    "med_adherence": "compliant",
    "family_history": "yes",
    "lifestyle": ["smoker", "heavy_caffeine"]
  },
  "symptom_selection": {
    "chosen": ["chest_pain", "dyspnea", "fatigue"]
  },
  "symptom_detail": {
    "chest_pain": {
      "severity": "moderate",
      "duration_general": "weeks",
      "pattern": "episodic",
      "episode_duration": "minutes_long",
      "triggers": ["exertion", "emotional"],
      "relieving_factors": ["rest"],
      "radiation": ["left_arm", "back"],
      "exertional": "yes",
      "quality": "pressure"
    },
    "dyspnea": {
      "severity": "moderate",
      "duration_general": "months",
      "pattern": "episodic",
      "episode_duration": "minutes_short",
      "triggers": ["exertion"],
      "relieving_factors": ["rest"],
      "orthopnea": "no",
      "exertion_level": "moderate_exertion"
    },
    "fatigue": {
      "severity": "mild",
      "duration_general": "months",
      "pattern": "continuous",
      "triggers": ["exertion"],
      "relieving_factors": ["rest"],
      "exertional_change": "yes"
    }
  },
  "other_symptoms": [],
  "red_flags": {
    "syncope_exertion": "no"
  },
  "free_text": {
    "additional": "أحياناً أشعر بثقل في صدري بعد الأكل الثقيل"
  }
}
```

### 1.4 Flutter Screens Summary

```
Screen 1: Welcome → "Start Health Assessment" button
Screen 2: Demographics (simple form — 5 fields)
Screen 3: Medical History (scrollable form — 7 fields)
Screen 4: Symptom Selection (checkbox grid — 16 symptoms)
Screen 5: Symptom Details (dynamic — loops through each selected symptom)
           → Show progress: "Symptom 1 of 3: ألم في الصدر"
           → Ask 6-9 questions per symptom
           → Handle conditional questions (depends_on logic)
Screen 6: Red Flags (1-2 quick questions)
Screen 7: Free Text (one text field)
Screen 8: Review (show summary of all answers, "Edit" per section)
Screen 9: Loading (show spinner while polling AI server — up to 5 min)
Screen 10: Report View (display the AI result)
```

### 1.5 API Calls for Flutter Developer

| When | Method | Endpoint | Purpose |
|------|--------|----------|---------|
| Submit assessment | POST | `/api/ai/consult/{patientId}` | Send full JSON, get report |
| Patient views reports | GET | `/api/ai/my-reports` | **New endpoint** — patient's own reports |
| Doctor views reports | GET | `/api/ai/history/{patientId}` | Existing endpoint |
| Auto-fill vitals | GET | `/api/iot/latest/{patientId}` | Optional — pre-fill if wearable connected |

---

## Part 2: What You Build in Spring Boot

### 2.1 New DTO — `ChatbotSubmissionRequest.java`

This replaces the current `AiConsultRequest`. It mirrors the exact JSON structure from med.py.

```java
@Data
public class ChatbotSubmissionRequest {

    @NotNull
    private Map<String, Object> demographics;  // age, sex, weight_kg, height_cm, pregnancy

    @NotNull
    private Map<String, Object> history;        // known_cardiac, prior_workup, chronic_conditions,
                                                 // medications, med_adherence, family_history, lifestyle

    @NotNull
    private Map<String, Object> symptomSelection;  // chosen: [list of symptom codes]

    @NotNull
    private Map<String, Map<String, Object>> symptomDetail;  // per-symptom sub-answers

    private List<Map<String, String>> otherSymptoms;  // [{code, label}]

    private Map<String, Object> redFlags;  // exertional_chest, syncope_exertion

    private Map<String, String> freeText;  // additional
}
```

**Why `Map<String, Object>` instead of typed fields?**  
Because the symptom_detail section is dynamic — different symptoms have different sub-fields. Using Maps keeps it flexible and matches med.py's `state.data` dict exactly. You don't need to create 20 sub-DTOs.

### 2.2 New Service — `ArabicNarrativeBuilder.java`

This is the Java port of med.py's `_build_arabic_narrative()`. It converts the JSON into the Arabic text string that the AI server expects.

**You need to port these components from med.py:**

1. **All the translation maps** (lines 42-138 of med.py) — `SEVERITY_MAP`, `DURATION_MAP`, `PATTERN_MAP`, `TRIGGERS_MAP`, `RADIATION_MAP`, etc. In Java, these become `Map<String, String>` constants.

2. **The narrative builder** (lines 592-791 of med.py) — `_build_arabic_narrative()`. In Java, this becomes a method that takes the request JSON and builds the Arabic string.

The logic is straightforward string concatenation. Here's the structure:

```java
@Service
public class ArabicNarrativeBuilder {

    // All the maps from med.py (lines 42-138)
    private static final Map<String, String> SEVERITY_MAP = Map.of(
        "mild", "بسيطة", "moderate", "متوسطة",
        "severe", "شديدة", "unbearable", "لا تحتمل"
    );
    // ... (same for all other maps)

    public String buildNarrative(ChatbotSubmissionRequest request) {
        List<String> parts = new ArrayList<>();

        // 1. Demographics
        Map<String, Object> demo = request.getDemographics();
        List<String> demoParts = new ArrayList<>();
        if (demo.get("age") != null) demoParts.add("عمري " + ((Number)demo.get("age")).intValue() + " سنة");
        if ("male".equals(demo.get("sex"))) demoParts.add("أنا ذكر");
        if ("female".equals(demo.get("sex"))) demoParts.add("أنا أنثى");
        if (demo.get("weight_kg") != null) demoParts.add("وزني " + demo.get("weight_kg") + " كيلوجرام");
        if (demo.get("height_cm") != null) demoParts.add("طولي " + demo.get("height_cm") + " سنتيمتر");
        if (!demoParts.isEmpty()) parts.add(String.join("، ", demoParts) + ".");

        // 2. History — same logic as med.py lines 616-659
        // 3. Symptom details — same logic as med.py lines 661-762
        // 4. Red flags — same logic as med.py lines 764-777
        // 5. Free text — same logic as med.py lines 779-782

        String narrative = String.join("\n", parts);

        // Final filter: remove English text and underscores (same as med.py line 788)
        narrative = narrative.replaceAll("[a-zA-Z_]{2,}", "");
        narrative = narrative.replaceAll("\\s+", " ").trim();

        return narrative;
    }
}
```

**Important:** The logic is a direct 1-to-1 port. Don't add anything. Don't change the format. The AI server was tested with this exact text format. Match it character by character.

### 2.3 Update `AiServiceImpl.java` — Async Polling

The current AiService probably does a simple synchronous POST. The AI server uses a **job queue with polling**. You need to implement the same pattern as med.py lines 839-914.

```java
@Service
@RequiredArgsConstructor
public class AiServiceImpl implements AiService {

    private final UserRepository userRepository;
    private final AiConsultationRepository aiConsultationRepository;
    private final ArabicNarrativeBuilder narrativeBuilder;
    private final RestTemplate restTemplate;

    @Value("${ai.service.url}")       // http://100.51.212.220:8000/generate
    private String aiServiceUrl;

    @Value("${ai.service.api-key}")   // REMOVED
    private String aiServiceApiKey;

    @Override
    public AiConsultResponse consult(Long patientId, ChatbotSubmissionRequest request) {

        // 1. Build Arabic narrative (same as med.py)
        String narrative = narrativeBuilder.buildNarrative(request);

        // 2. Submit job to AI server
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("X-API-Key", aiServiceApiKey);

        Map<String, String> body = Map.of("text", narrative);
        HttpEntity<Map<String, String>> httpEntity = new HttpEntity<>(body, headers);

        ResponseEntity<Map> submitResponse;
        try {
            submitResponse = restTemplate.postForEntity(aiServiceUrl, httpEntity, Map.class);
        } catch (Exception e) {
            throw new RuntimeException("Cannot connect to AI server: " + e.getMessage());
        }

        if (submitResponse.getStatusCode().value() != 200) {
            throw new RuntimeException("AI server returned HTTP " + submitResponse.getStatusCode());
        }

        // 3. Get poll URL from response
        String pollPath = (String) submitResponse.getBody().get("poll_url");
        if (pollPath == null) {
            throw new RuntimeException("AI server did not return poll_url");
        }

        // Build the full poll URL: http://100.51.212.220:8000 + /jobs/<id>
        String baseUrl = aiServiceUrl.replaceAll("/generate$", "");
        String pollUrl = baseUrl + pollPath;

        // 4. Poll until done (max 5 minutes, every 2 seconds)
        int maxWaitSeconds = 300;
        int pollInterval = 2;
        int elapsed = 0;

        while (elapsed < maxWaitSeconds) {
            try {
                Thread.sleep(pollInterval * 1000L);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Polling interrupted");
            }
            elapsed += pollInterval;

            HttpEntity<Void> pollEntity = new HttpEntity<>(headers);
            ResponseEntity<Map> pollResponse;
            try {
                pollResponse = restTemplate.exchange(
                    pollUrl, HttpMethod.GET, pollEntity, Map.class
                );
            } catch (Exception e) {
                throw new RuntimeException("Error polling AI server: " + e.getMessage());
            }

            Map<String, Object> pollData = pollResponse.getBody();
            String status = (String) pollData.get("status");

            if ("completed".equals(status)) {
                Object result = pollData.get("result");
                String aiReport = result instanceof String
                    ? (String) result
                    : new ObjectMapper().writeValueAsString(result);

                // 5. Save to database
                AiConsultation consultation = new AiConsultation();
                consultation.setPatientId(patientId);
                consultation.setPatientInput(narrative);
                consultation.setAiReport(aiReport);
                consultation.setCreatedAt(LocalDateTime.now());
                aiConsultationRepository.save(consultation);

                return AiConsultResponse.builder()
                    .id(consultation.getId())
                    .patientId(patientId)
                    .patientInput(narrative)
                    .aiReport(aiReport)
                    .createdAt(consultation.getCreatedAt())
                    .build();
            }

            if ("failed".equals(status)) {
                String error = pollData.getOrDefault("error",
                    pollData.getOrDefault("message", "Unknown error")).toString();
                throw new RuntimeException("AI server failed: " + error);
            }

            // status is "processing" — keep polling
        }

        throw new RuntimeException("AI server timed out after " + maxWaitSeconds + " seconds");
    }
}
```

**Warning:** This method blocks the thread for up to 5 minutes. For production you'd want to make this async with `@Async` or a `CompletableFuture`. For the graduation demo, the synchronous version is fine — Flutter just shows a loading screen.

### 2.4 Update `AiController.java`

```java
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiController {

    private final AiService aiService;

    // Accept the full chatbot JSON and generate a report
    @PostMapping("/consult/{patientId}")
    public ResponseEntity<AiConsultResponse> consult(
            @PathVariable Long patientId,
            @Valid @RequestBody ChatbotSubmissionRequest request) {
        return ResponseEntity.status(201).body(aiService.consult(patientId, request));
    }

    // Doctor views patient's AI reports
    @GetMapping("/history/{patientId}")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<List<AiConsultResponse>> getHistory(
            @PathVariable Long patientId) {
        return ResponseEntity.ok(aiService.getHistory(patientId));
    }

    // NEW: Patient views their own reports
    @GetMapping("/my-reports")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<List<AiConsultResponse>> getMyReports() {
        Long currentUserId = SecurityUtil.getCurrentUserId();
        return ResponseEntity.ok(aiService.getHistory(currentUserId));
    }
}
```

### 2.5 Update `application.properties`

```properties
# Replace the old Azure URLs with the AWS server
ai.service.url=${AI_SERVICE_URL:http://100.51.212.220:8000/generate}
ai.service.api-key=${AI_SERVICE_KEY:REMOVED}
```

### 2.6 RestTemplate Timeout

```java
@Configuration
public class RestTemplateConfig {
    @Bean
    public RestTemplate restTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10_000);    // 10s to connect
        factory.setReadTimeout(120_000);       // 2 min per HTTP call (polling calls are fast)
        return new RestTemplate(factory);
    }
}
```

### 2.7 Database — No Schema Changes Needed

Looking at the existing `AiConsultation` entity:
- `patientInput` (TEXT) → stores the Arabic narrative ✓
- `aiReport` (TEXT) → stores the AI result JSON ✓
- `patientId` (Long) → links to the patient ✓
- `createdAt` (LocalDateTime) → timestamp ✓

The User entity already has `dateOfBirth` and `gender`. The chatbot collects age, weight, and height from the patient directly during the conversation (not from the DB), so you don't need to add columns to the User table. The demographics go straight into the narrative text.

---

## Part 3: What to Do with Flask

**For now:** Keep Flask running. Don't delete the `/api/chatbot/*` endpoints. The old flow still works as a fallback.

**After the new flow is tested:** You can remove:
- `ChatbotController.java`
- `ChatbotService.java` (if it exists)
- The `chatbot.service.url` config property
- The Flask EB deployment on AWS

---

## Part 4: Implementation Order

### Week 1 — Backend (You)

```
Day 1-2: Port the translation maps from med.py to Java
         Create ArabicNarrativeBuilder.java
         → Test with hardcoded data → compare output with med.py output

Day 3:   Create ChatbotSubmissionRequest DTO
         Update AiServiceImpl with polling logic
         Update AiController (new endpoint + my-reports)

Day 4:   Test with Postman:
         → POST /api/ai/consult/{patientId} with the sample JSON above
         → Verify the Arabic narrative matches med.py's output
         → Verify the AI server returns a result
         → Verify the report is saved in ai_consultations
         → GET /api/ai/my-reports returns the report

Day 5:   Fix bugs, edge cases, error handling
```

### Week 1-2 — Flutter (App Developer, in parallel)

```
Day 1-2: Build the Demographics and History screens
         Hardcode all questions from stage_questions.py / med.py

Day 3-4: Build Symptom Selection screen (16-checkbox grid)
         Build the Symptom Loop (the dynamic part)
         → For each selected symptom, show the common + extra questions
         → Handle depends_on logic

Day 5:   Build Red Flags + Free Text + Review screens

Day 6-7: Build the submit flow:
         → Collect all answers into the JSON structure
         → POST to /api/ai/consult/{patientId}
         → Show loading (up to 5 min)
         → Display the AI report

Day 8:   Build Report History screen
```

### Week 3 — Integration Testing

```
Day 1: Flutter → Spring Boot → AI server end-to-end
Day 2: Edge cases (no symptoms selected, all symptoms selected,
       "other" symptoms, female-only questions)
Day 3: Error handling (AI server down, timeout, network error)
Day 4: Doctor accessing patient reports
Day 5: Final polish
```

---

## Part 5: Critical Things to Get Right

### 5.1 The Arabic Narrative Must Match Exactly

The AI model was trained/tested with the exact text format from `_build_arabic_narrative()`. If your Java port produces different text, the model's output quality will degrade.

**How to verify:** Run med.py locally with test data, capture the narrative output. Then send the same test data to your Java endpoint and compare the narrative strings character by character.

### 5.2 The Polling Pattern Is Not Optional

The AI server at `100.51.212.220:8000` does NOT return the result synchronously. If you try to read the result from the POST response, you'll get a `poll_url` instead. You must poll.

### 5.3 The Symptom Loop Is the Hard Part

The symptom loop in med.py is complex — each symptom has common questions plus symptom-specific extras, and some questions depend on previous answers. The Flutter developer needs to understand this thoroughly.

**Give them this data:**
- The 16 symptom codes and their Arabic labels (med.py line 19-36)
- The common questions (med.py lines 143-201)
- The extra questions per symptom (med.py lines 204-249)
- The depends_on logic (if pattern ≠ episodic, skip episode_duration)

### 5.4 The "Other" Symptom Flow

If the patient selects "عرض آخر" (other):
1. Ask: how many other symptoms? (1-10)
2. For each: ask the name (free text in Arabic)
3. Then ask the common questions for each custom symptom

This is handled in med.py lines 440-444, 449-503.

---

## Files You're Changing (Backend)

| File | Action | What |
|------|--------|------|
| `dto/ChatbotSubmissionRequest.java` | **NEW** | The full chatbot JSON structure |
| `service/ArabicNarrativeBuilder.java` | **NEW** | Port of _build_arabic_narrative() |
| `service/AiServiceImpl.java` | **MODIFY** | Add polling logic, use new DTO |
| `controller/AiController.java` | **MODIFY** | Update consult(), add my-reports |
| `config/RestTemplateConfig.java` | **MODIFY** | Adjust timeouts |
| `application.properties` | **MODIFY** | Update AI URL to AWS |

**Total: 2 new files, 4 modified files. No database changes.**

---

## Quick Reference Card for Flutter Developer

```
┌──────────────────────────────────────────────────────────────┐
│                    CHATBOT INTEGRATION GUIDE                  │
│                    (for Flutter Developer)                    │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  FLOW: All questions are LOCAL in Flutter.                    │
│        No network calls until final submit.                  │
│                                                              │
│  STAGES:                                                     │
│    1. Demographics (5 questions)                             │
│    2. History (7 questions, some conditional)                │
│    3. Symptom Selection (16 checkboxes)                      │
│    4. Symptom Loop (5-10 questions PER selected symptom)     │
│    5. Red Flags (1-2 questions)                              │
│    6. Free Text (1 question)                                 │
│                                                              │
│  SUBMIT:                                                     │
│    POST /api/ai/consult/{patientId}                          │
│    Body: the full nested JSON (see sample in this doc)       │
│    Auth: Bearer {jwt_token}                                  │
│                                                              │
│  RESPONSE TIME: 30 seconds to 5 minutes (show loading)      │
│                                                              │
│  RESPONSE FORMAT:                                            │
│    {                                                         │
│      "id": 42,                                               │
│      "patientId": 25,                                        │
│      "patientInput": "Arabic narrative text...",             │
│      "aiReport": "{ ... AI result JSON ... }",               │
│      "createdAt": "2026-05-10T14:30:00"                     │
│    }                                                         │
│                                                              │
│  VIEW PAST REPORTS:                                          │
│    Patient: GET /api/ai/my-reports                           │
│    Doctor:  GET /api/ai/history/{patientId}                  │
│                                                              │
│  QUESTION DATA SOURCE:                                       │
│    Copy all questions from med.py STAGE_QUESTIONS (line 267) │
│    Copy symptom extras from _get_extras_for_code (line 204)  │
│    Copy all Arabic labels from SYMPTOM_LABELS (line 19)      │
│                                                              │
│  CONDITIONAL LOGIC (depends_on):                             │
│    "equals": show only if field == value                     │
│    "contains_any": show only if field list contains value    │
│    "not_contains_any": show only if field list doesn't have  │
│    "not_text_in": show only if text field ≠ any of values    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```
