# Flutter AI Assessment Feature Prompt

I want you to implement a complete Flutter feature based on the attached files.

The feature is a medical cardiac intake chatbot / assessment flow.

We will use Approach C.

Important architecture decision:

Flutter must NOT call Flask at all.

Do not call:

- Flask `/chat`
- Flask `/reset`
- any message-by-message Flask chatbot endpoint

The new flow is:

Flutter  
→ collects all assessment answers locally  
→ sends one final JSON request to Spring Boot  
→ Spring Boot talks to the AI server  
→ Spring Boot saves the report  
→ Flutter displays the report

So the final runtime architecture must be:

```text
Flutter → Spring Boot → AI Server
```

Not:

```text
Flutter → Flask
```

---

## FILES YOU MUST READ FIRST

You must read the attached files carefully before coding:

- `CHATBOT_AI_INTEGRATION_PLAN_v2.md`
- `med.py`
- `stage_questions.py`
- `app.py`

Important:

`med.py` is the source of truth for the current working flow. It contains:

- The stages
- The symptom labels and symptom codes
- The common symptom questions
- The extra questions per symptom
- The dependency logic
- The exact JSON structure
- The old Flask flow
- The AI integration idea

Use the flow from `CHATBOT_AI_INTEGRATION_PLAN_v2.md`, but copy the exact questions/options/codes from `med.py` whenever there is any difference.

Also note:

The backend project is here:

```text
D:\engineer\4th\GP\GP_BE
```

Chatbot:

```text
D:\engineer\4th\GP\Chatbot
```

You can read the backend from:

```text
D:\engineer\4th\GP\GP_BE\.qoder
```

---

## MAIN GOAL

Build a Flutter feature for a patient to complete a cardiac health assessment.

Flutter should handle the whole question flow locally.

No network calls should happen during the questions.

At the end, Flutter sends the full final JSON to Spring Boot:

```http
POST /api/ai/consult/{patientId}
```

Then Flutter shows a beautiful loading screen while the backend/AI generates the report.

Finally Flutter displays the AI report in a polished report screen.

Also add a report history screen using:

```http
GET /api/ai/my-reports
```

---

## VERY IMPORTANT UPDATE ABOUT DEMOGRAPHICS

The backend already stores the patient demographics in the database.

The patient table/user profile already has:

- `date_of_birth`
- `gender`
- `height`
- `weight`

So do NOT ask the patient for these values again in Flutter.

Do not build a Demographics input screen.

Do not ask:

- age
- gender
- height
- weight

Do not ask pregnancy unless the backend/profile flow already supports it.

For now, skip pregnancy from Flutter unless there is an existing profile field for it.

The source of truth for demographics is the backend patient profile, not the assessment flow.

Spring Boot should fetch:

- `date_of_birth`
- `gender`
- `height`
- `weight`

Then Spring Boot should calculate age from `date_of_birth` and use the stored profile data when building the Arabic narrative.

If the current backend DTO temporarily still requires a `demographics` key, Flutter may send an empty demographics object:

```json
{
  "demographics": {}
}
```

But the preferred solution is:

Do not send demographics from Flutter at all.

The assessment flow should start directly from Medical History after the Welcome Screen.

---

## FINAL FLUTTER FLOW

Build this flow:

1. Welcome Screen
2. Medical History Screen
3. Symptom Selection Screen
4. Symptom Details Screen
5. Red Flags Screen
6. Free Text Screen
7. Review Screen
8. Loading / Generating Report Screen
9. Report Result Screen
10. Report History Screen

Do not include Demographics as an editable step.

If profile data is already available in the app, you may show demographics as read-only in the review screen, but do not allow editing them here.

---

## UI / UX GOAL

The flow should feel premium, modern, smooth, and trustworthy.

I want the best UI/UX possible, not a basic form.

The UI should look like a high-quality modern medical app:

- Clean Arabic-first design
- RTL support
- Soft gradients
- Beautiful cards
- Progress indicators
- Smooth transitions
- Friendly microcopy
- Large readable Arabic typography
- Clear selected/unselected states
- Elegant loading screen
- Professional report screen

Do not build it as a boring plain form.

Make it feel like a guided medical assistant.

---

## LANGUAGE AND DIRECTION

The UI text should be Arabic.

The layout should support RTL.

Questions should appear in Arabic exactly as much as possible from the attached files.

Stored values must remain the English codes from `med.py`.

Examples:

- `male`
- `female`
- `chest_pain`
- `dyspnea`
- `moderate`
- `episodic`
- `yes`

Do not rename these codes.

---

## SCREEN DETAILS

### 1. Welcome Screen

Create a beautiful intro screen with:

- Medical assistant illustration/icon
- Arabic title, for example:
  "تقييم صحة القلب"
- Subtitle explaining that the patient will answer some questions to generate an AI-assisted cardiac report
- Start button
- Small disclaimer that this does not replace a doctor

The design should be premium and calming.

After pressing start, go directly to Medical History.

Do not go to Demographics.

---

### 2. Medical History Screen

Collect:

#### Field: `history.known_cardiac`

Type: multi choice

Question:

```text
هل سبق تشخيصك بمرض في القلب؟ (يمكنك اختيار أكثر من إجابة)
```

Options:

- "لا يوجد تشخيص سابق" -> `none`
- "ارتخاء في الصمام الميترالي" -> `mvp`
- "ثقب في القلب / عيب خلقي" -> `hole_congenital`
- "تضخم في القلب" -> `enlarged`
- "عدم انتظام في ضربات القلب / خوارج انقباض" -> `arrhythmia`
- "جلطة أو ذبحة صدرية أو سكتة سابقة" -> `prior_mi_stroke`
- "قسطرة / دعامة / عملية قلب" -> `catheter_stent`
- "تشخيص آخر" -> `other`

#### Field: `history.prior_workup`

Type: multi choice

Question:

```text
هل قمت سابقاً بأي من الفحوصات التالية للقلب؟ (يمكنك اختيار أكثر من إجابة)
```

Options:

- "لا شيء" -> `none`
- "رسم قلب (ECG)" -> `ecg`
- "أشعة تلفزيونية على القلب (إيكو)" -> `echo`
- "هولتر (رسم قلب لمدة 24 ساعة)" -> `holter`
- "رسم قلب بالمجهود" -> `stress`
- "قسطرة تشخيصية" -> `cath`

#### Field: `history.chronic_conditions`

Type: multi choice

Question:

```text
هل تعاني من أي من الحالات التالية؟ (يمكنك اختيار أكثر من إجابة)
```

Options:

- "لا شيء" -> `none`
- "ارتفاع ضغط الدم" -> `htn`
- "انخفاض ضغط الدم" -> `low_bp`
- "السكري" -> `dm`
- "ارتفاع الكوليسترول" -> `chol`
- "اضطراب في الغدة الدرقية" -> `thyroid`
- "فقر دم / أنيميا" -> `anemia`
- "القولون العصبي" -> `ibs`
- "ارتجاع / حموضة / جرثومة المعدة" -> `reflux`

#### Field: `history.medications`

Type: text

Question:

```text
ما الأدوية التي تتناولها حالياً بانتظام؟ (اذكر الاسم والجرعة إن أمكن، أو اكتب لا شيء)
```

#### Field: `history.med_adherence`

Type: choice

Question:

```text
هل توقفت عن تناول أي من أدويتك مؤخراً؟
```

Options:

- "لا، ملتزم بالدواء" -> `compliant`
- "نعم، توقفت منذ أيام أو أسابيع" -> `recently_stopped`
- "أتناول جرعات غير منتظمة" -> `irregular`

Only show this question if medications is not one of:

- "لا شيء"
- "لا"
- "none"
- "لا يوجد"

#### Field: `history.family_history`

Type: choice

Question:

```text
هل يعاني أحد الأقارب من الدرجة الأولى من مرض في القلب قبل سن 55؟
```

Options:

- "نعم" -> `yes`
- "لا" -> `no`
- "لا أعرف" -> `unknown`

#### Field: `history.lifestyle`

Type: multi choice

Question:

```text
هل ينطبق عليك أي من التالي؟ (يمكنك اختيار أكثر من إجابة)
```

Options:

- "لا شيء" -> `none`
- "أدخن حالياً" -> `smoker`
- "مدخن سابق وتركت" -> `ex_smoker`
- "أتناول كمية كبيرة من القهوة أو الشاي (أكثر من 3 أكواب يومياً)" -> `heavy_caffeine`
- "أمارس الرياضة بانتظام" -> `gym`
- "أتناول منشطات أو هرمونات" -> `supplements`

Important multi-choice behavior:

- If the user selects `none`, clear other selected options.
- If the user selects any real option, remove `none`.

---

### 3. Symptom Selection Screen

Collect:

Field:

```text
symptom_selection.chosen
```

Type: multi choice

Question:

```text
ما الأعراض التي تشعر بها؟ (اختر كل ما ينطبق عليك)
```

Options:

- "خفقان / تسارع في ضربات القلب" -> `palpitations`
- "عدم انتظام / إحساس بتوقف لحظي" -> `irregular`
- "ألم أو ضغط أو ضيق في الصدر" -> `chest_pain`
- "ألم في منطقة القلب تحديداً" -> `heart_pain`
- "نغزات / وخز / طعنات" -> `stabs`
- "ضيق أو صعوبة في التنفس" -> `dyspnea`
- "دوخة / دوار / عدم اتزان" -> `dizziness`
- "إغماء أو فقدان وعي" -> `fainting`
- "تعب / إرهاق / ضعف عام" -> `fatigue`
- "تعرق (خصوصاً عرق بارد)" -> `sweating`
- "غثيان / قيء" -> `nausea`
- "ألم ينتشر إلى الذراع أو الكتف أو اليد اليسرى" -> `arm_radiation`
- "تنميل أو خدر في الأطراف" -> `tingling`
- "رجفة / ارتعاش" -> `tremor`
- "برودة في الأطراف" -> `cold_extremities`
- "عرض آخر" -> `other`

Use a beautiful grid of selectable symptom cards with icons.

The user must select at least one symptom.

---

### 4. Symptom Details Screen

This is the most important and complex screen.

For every selected symptom except `other`, ask:

- common questions
- then symptom-specific extra questions

Show progress:

- "العرض 1 من 3"
- symptom label
- progress bar

Store answers in:

```text
symptom_detail.{code}.{field}
```

Examples:

- `symptom_detail.chest_pain.severity`
- `symptom_detail.chest_pain.duration_general`
- `symptom_detail.dyspnea.orthopnea`

---

## COMMON QUESTIONS FOR EVERY SYMPTOM

### A)

Field:

```text
symptom_detail.{code}.severity
```

Question:

```text
ما شدة [{label}] عندما تحدث؟
```

Type: choice

Options:

- "بسيطة / خفيفة" -> `mild`
- "متوسطة / مزعجة" -> `moderate`
- "شديدة / قوية" -> `severe`
- "لا أحتمل" -> `unbearable`

### B)

Field:

```text
symptom_detail.{code}.duration_general
```

Question:

```text
منذ متى وأنت تعاني من [{label}]؟
```

Type: choice

Options:

- "بدأت اليوم" -> `today`
- "منذ أيام" -> `days`
- "منذ أسابيع" -> `weeks`
- "منذ شهور" -> `months`
- "منذ سنوات" -> `years`
- "منذ الطفولة" -> `since_childhood`

### C)

Field:

```text
symptom_detail.{code}.pattern
```

Question:

```text
كيف يأتي [{label}]؟
```

Type: choice

Options:

- "مستمر طوال الوقت / موجود الآن" -> `continuous`
- "نوبات تأتي وتذهب" -> `episodic`
- "نوبة واحدة فقط حتى الآن" -> `single`

### D)

Field:

```text
symptom_detail.{code}.episode_duration
```

Question:

```text
كم تستمر نوبة [{label}] عادةً؟
```

Type: choice

Options:

- "ثوانٍ" -> `seconds`
- "دقائق قليلة (< 5 دقائق)" -> `minutes_short`
- "من 5 إلى 30 دقيقة" -> `minutes_long`
- "ساعات" -> `hours`
- "مستمر لا يزول" -> `continuous`

Only show if:

```text
symptom_detail.{code}.pattern == episodic
```

### E)

Field:

```text
symptom_detail.{code}.triggers
```

Question:

```text
متى يحدث [{label}] عادةً؟ (اختر كل ما ينطبق)
```

Type: multi choice

Options:

- "فجأة بدون سبب واضح" -> `sudden`
- "في الليل" -> `night`
- "أثناء النوم (يوقظني)" -> `sleep`
- "عند الاستيقاظ" -> `waking`
- "عند المجهود / الرياضة / الدرج" -> `exertion`
- "عند الراحة" -> `rest`
- "بعد الأكل" -> `after_meals`
- "عند التوتر أو الغضب" -> `emotional`
- "بعد القهوة / الشاي" -> `after_caffeine`
- "بعد التدخين" -> `after_smoking`
- "مع ملامسة الماء البارد" -> `cold_water`
- "مع الدورة الشهرية" -> `menstruation`

### F)

Field:

```text
symptom_detail.{code}.relieving_factors
```

Question:

```text
ما الذي يخفف [{label}]؟ (اختر كل ما ينطبق)
```

Type: multi choice

Options:

- "الراحة" -> `rest`
- "الدواء" -> `medication`
- "تغيير الوضعية" -> `position_change`
- "التنفس العميق" -> `deep_breathing`
- "لا شيء يخففه" -> `nothing`
- "يزول من تلقاء نفسه" -> `self_resolves`

---

## SYMPTOM-SPECIFIC EXTRA QUESTIONS

### For `chest_pain`

#### 1.

Field:

```text
symptom_detail.chest_pain.radiation
```

Question:

```text
هل ينتشر ألم الصدر إلى مناطق أخرى؟ (اختر كل ما ينطبق)
```

Type: multi choice

Options:

- "لا ينتشر" -> `no_radiation`
- "الذراع / الكتف / اليد اليسرى" -> `left_arm`
- "الذراع / الكتف / اليد اليمنى" -> `right_arm`
- "الظهر / بين الكتفين" -> `back`
- "الرقبة" -> `neck`
- "الفك أو الأسنان" -> `jaw`
- "أعلى البطن" -> `upper_abdomen`

#### 2.

Field:

```text
symptom_detail.chest_pain.exertional
```

Question:

```text
هل يزداد ألم الصدر مع المجهود ويخف مع الراحة؟
```

Type: choice

Options:

- "نعم" -> `yes`
- "لا" -> `no`
- "لست متأكداً" -> `not_sure`

#### 3.

Field:

```text
symptom_detail.chest_pain.quality
```

Question:

```text
كيف تصف طبيعة ألم الصدر؟
```

Type: choice

Options:

- "ضغط / ثقل" -> `pressure`
- "حرقة / حموضة" -> `burning`
- "طعنة / وخز حاد" -> `stabbing`
- "شد / تشنج" -> `tightness`
- "إحساس غريب يصعب وصفه" -> `vague`

### For `heart_pain`

#### 1.

Field:

```text
symptom_detail.heart_pain.radiation
```

Question:

```text
هل ينتشر ألم منطقة القلب إلى مناطق أخرى؟ (اختر كل ما ينطبق)
```

Type: multi choice

Options:

- "لا ينتشر" -> `no_radiation`
- "الذراع / الكتف / اليد اليسرى" -> `left_arm`
- "الرقبة" -> `neck`
- "الفك" -> `jaw`
- "الظهر" -> `back`

#### 2.

Field:

```text
symptom_detail.heart_pain.exertional
```

Question:

```text
هل يزداد ألم منطقة القلب مع المجهود ويخف مع الراحة؟
```

Type: choice

Options:

- "نعم" -> `yes`
- "لا" -> `no`
- "لست متأكداً" -> `not_sure`

### For `stabs`

Field:

```text
symptom_detail.stabs.location
```

Question:

```text
أين تقع النغزات / الوخز بالضبط؟
```

Type: choice

Options:

- "منطقة القلب (اليسار)" -> `left_precordial`
- "منتصف الصدر" -> `central`
- "اليمين" -> `right`
- "عشوائية تتنقل" -> `moving`

### For `palpitations`

Field:

```text
symptom_detail.palpitations.rate_feel
```

Question:

```text
كيف تشعر بضربات القلب أثناء الخفقان؟
```

Type: choice

Options:

- "سريعة جداً ومنتظمة" -> `fast_regular`
- "سريعة وغير منتظمة" -> `fast_irregular`
- "قوية وأشعر بها في صدري" -> `forceful`
- "أشعر بها في رقبتي" -> `neck_pounding`

### For `irregular`

Field:

```text
symptom_detail.irregular.skip_or_extra
```

Question:

```text
ما أقرب وصف لما تشعر به؟
```

Type: choice

Options:

- "إحساس بتوقف لحظي ثم عودة" -> `pause_then_thump`
- "ضربة إضافية خارج النظام" -> `extra_beat`
- "اضطراب كامل في الإيقاع" -> `full_irregular`
- "تسارع مفاجئ ثم عودة طبيعية" -> `svt_like`

### For `dyspnea`

#### 1.

Field:

```text
symptom_detail.dyspnea.orthopnea
```

Question:

```text
هل يزداد ضيق التنفس عند الاستلقاء؟
```

Type: choice

Options:

- "نعم، أحتاج وسائد إضافية" -> `yes_orthopnea`
- "لا" -> `no`
- "لست متأكداً" -> `not_sure`

#### 2.

Field:

```text
symptom_detail.dyspnea.exertion_level
```

Question:

```text
ما مستوى الجهد الذي يسبب ضيق التنفس؟
```

Type: choice

Options:

- "عند المشي السريع / صعود الدرج" -> `moderate_exertion`
- "عند أدنى مجهود (المشي البطيء)" -> `minimal_exertion`
- "عند الراحة التامة" -> `at_rest`
- "لا يرتبط بالمجهود" -> `unrelated`

### For `dizziness`

Field:

```text
symptom_detail.dizziness.type
```

Question:

```text
كيف تصف الدوخة؟
```

Type: choice

Options:

- "إحساس بالدوران (كأن الأرض تدور)" -> `vertigo`
- "ضبابية / عدم وضوح" -> `lightheaded`
- "إحساس بالإغماء الوشيك" -> `presyncope`
- "عدم اتزان عند المشي" -> `imbalance`

### For `fainting`

#### 1.

Field:

```text
symptom_detail.fainting.full_loss
```

Question:

```text
هل فقدت الوعي تماماً أم كاد فقط؟
```

Type: choice

Options:

- "فقدت الوعي تماماً" -> `complete_loss`
- "كاد يحدث / اسودّ أمامي" -> `near_syncope`

#### 2.

Field:

```text
symptom_detail.fainting.recovery_time
```

Question:

```text
كم استغرق التعافي؟
```

Type: choice

Options:

- "ثوانٍ (< 1 دقيقة)" -> `seconds`
- "دقيقة أو أكثر" -> `minutes`
- "استدعى التدخل" -> `required_intervention`

### For `arm_radiation`

Field:

```text
symptom_detail.arm_radiation.side
```

Question:

```text
الانتشار في أي جانب؟
```

Type: choice

Options:

- "اليسار فقط" -> `left_only`
- "اليمين فقط" -> `right_only`
- "الجانبين" -> `both`

### For `fatigue`

Field:

```text
symptom_detail.fatigue.exertional_change
```

Question:

```text
هل يزداد الإرهاق مع أي مجهود؟
```

Type: choice

Options:

- "نعم بشكل واضح" -> `yes`
- "قليلاً" -> `slightly`
- "لا" -> `no`

Symptoms without extras still get the common questions only:

- `sweating`
- `nausea`
- `tingling`
- `tremor`
- `cold_extremities`

---

## OTHER SYMPTOM FLOW

If the user selected `other` in symptom selection:

1. Ask:

```text
كم عدد الأعراض الإضافية الأخرى التي تريد وصفها؟
```

Type: number

Min: 1

Max: 10

2. For each extra symptom, ask:

```text
ما هو العرض الإضافي رقم {index}؟ (اكتب وصفاً مختصراً بالعربي)
```

3. Add each custom symptom to:

```text
other_symptoms
```

Example structure:

`other_symptoms` should contain objects like:

- code: `other_0`
- label: Arabic symptom name typed by the user

4. Ask the common symptom questions for each custom symptom.

Store its details in:

```text
symptom_detail.other_0
```

---

### 5. Red Flags Screen

Collect:

#### Field: `red_flags.exertional_chest`

Question:

```text
هل يوجد ألم في الصدر يزداد مع المجهود ويخف مع الراحة؟
```

Type: choice

Options:

- "نعم" -> `yes`
- "لا" -> `no`
- "لست متأكداً" -> `not_sure`

Only show if selected symptoms do NOT contain:

- `chest_pain`
- `heart_pain`

#### Field: `red_flags.syncope_exertion`

Question:

```text
هل سبق أن أُغمي عليك أثناء الرياضة أو المجهود الشديد؟
```

Type: choice

Options:

- "نعم" -> `yes`
- "لا" -> `no`

---

### 6. Free Text Screen

Collect:

Field:

```text
free_text.additional
```

Question:

```text
هل هناك أي شيء آخر تود إضافته عن حالتك؟ (إذا لا، اكتب لا)
```

Type: text

Use a beautiful textarea-style input.

---

### 7. Review Screen

Before submitting, show a full summary of the patient answers.

Group by:

- التاريخ المرضي
- الأعراض
- تفاصيل الأعراض
- علامات الخطورة
- ملاحظات إضافية

Do not show Demographics as an editable section.

If profile data is available in the app, you may show it as read-only only.

Allow editing each section if feasible.

The submit button should say:

```text
إرسال وإنشاء التقرير
```

---

### 8. Loading Screen

After submit, show a polished loading screen.

The backend may take from 30 seconds up to 5 minutes.

Show:

- animated loading indicator
- friendly Arabic messages rotating every few seconds

Examples:

- "جاري تحليل البيانات..."
- "نراجع عوامل الخطورة..."
- "نجهز التقرير الطبي..."
- "قد يستغرق هذا بعض الوقت..."

Do not allow double submit.

Handle timeout/error gracefully.

---

### 9. Report Result Screen

Display the returned report from backend.

Backend response example shape:

- `id`
- `patientId`
- `patientInput`
- `aiReport`
- `createdAt`

The `aiReport` may be:

- a JSON string
- a plain Arabic markdown/string report

Handle both.

If JSON:

- parse it safely
- display it in beautiful sections/cards

If plain markdown/text:

- display it clearly with Arabic typography
- support line breaks and headings

Show:

- report date
- patient summary if available
- AI report
- disclaimer:

```text
هذا التقرير استرشادي ولا يغني عن استشارة الطبيب.
```

---

### 10. Report History Screen

Call:

```http
GET /api/ai/my-reports
```

Display previous reports as cards:

- date
- short preview
- open report details

Handle:

- loading state
- empty state
- error state

---

## DATA MODEL REQUIREMENTS

Create clean Dart models where useful:

- `QuestionType`
- `AssessmentQuestion`
- `QuestionOption`
- `DependsOn`
- `ChatbotAssessmentState`
- `AiConsultResponse`

But do not over-engineer.

The final JSON body should contain these sections:

- `history`
- `symptom_selection`
- `symptom_detail`
- `other_symptoms`
- `red_flags`
- `free_text`

Do not send demographics unless the backend DTO currently requires it.

If the backend still requires demographics temporarily, send:

```json
{
  "demographics": {}
}
```

Important naming:

- Use `symptom_selection`, not `symptoms`
- Use `symptom_detail`, not `symptomDetails`
- Use `free_text`, not `freeText`
- Use `other_symptoms`, not `otherSymptoms`
- Use snake_case exactly because backend expects this structure

Example final body without demographics:

```json
{
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

---

## API REQUIREMENTS

Use the existing authenticated API client in the project if available.

### Submit endpoint

Method: POST

Path:

```http
/api/ai/consult/{patientId}
```

Headers:

- `Authorization: Bearer {jwt_token}`
- `Content-Type: application/json`

Body:

The full assessment JSON.

Response:

`AiConsultResponse`

### Report history endpoint

Method: GET

Path:

```http
/api/ai/my-reports
```

Headers:

- `Authorization: Bearer {jwt_token}`

Response:

List of `AiConsultResponse`

---

## VALIDATION REQUIREMENTS

Validate all required fields before allowing next/submit.

Do not validate age, gender, height, or weight in Flutter because Flutter should not ask for them.

For number inputs:

- other symptoms count must be 1 to 10

For choice:

- exactly one selected option

For multi choice:

- at least one selected option

For text:

- allow Arabic text
- trim whitespace
- do not block numbers because medication dosage may include numbers

Conditional logic:

- Medication adherence only if medications is not empty and not equal to:
  - "لا شيء"
  - "لا"
  - "none"
  - "لا يوجد"

- Episode duration only if pattern is `episodic`

- Red flag exertional chest only if selected symptoms do not include:
  - `chest_pain`
  - `heart_pain`

---

## DESIGN REQUIREMENTS

Make the design excellent.

Use:

- RTL layout
- Arabic typography
- soft medical color palette
- modern cards
- icons
- animated transitions
- progress indicator
- large tap targets
- disabled/enabled next button states
- selected option chips/cards
- subtle shadows
- rounded corners
- clean spacing

The app should feel premium.

Suggested visual direction:

- Background: soft gradient, light blue/white/teal
- Cards: white with soft shadow
- Primary color: medical teal/blue
- Danger/red flag color: soft red
- Success/selected color: teal/green
- Progress: stepper or linear progress bar

Use Flutter best practices:

- split code into widgets
- avoid one huge file if the project architecture supports folders
- keep question data separate from UI
- keep API logic separate from screens
- handle loading/error states
- keep code readable and maintainable

---

## FILES / STRUCTURE SUGGESTION

Create something like:

```text
lib/features/ai_assessment/
  data/
    cardiac_questions.dart
    ai_assessment_api.dart

  models/
    assessment_models.dart

  screens/
    assessment_welcome_screen.dart
    assessment_flow_screen.dart
    review_screen.dart
    report_loading_screen.dart
    report_result_screen.dart
    report_history_screen.dart

  widgets/
    assessment_theme.dart
    medical_gradient_background.dart
    assessment_progress_header.dart
    question_card.dart
    choice_option_card.dart
    assessment_next_button.dart
    report_section_card.dart
```

If the existing project uses another architecture, follow the existing style instead.

---

## IMPORTANT IMPLEMENTATION NOTES

1. Do not call Flask.
2. Do not call the old Flask `/chat` endpoint.
3. Do not call Flask `/reset`.
4. Do not implement a message-by-message chatbot API.
5. Flutter should collect answers locally.
6. Flutter should submit only once at the end to Spring Boot.
7. Match the JSON structure exactly.
8. Copy question codes exactly from `med.py`.
9. Do not rename English codes.
10. Make the UI Arabic/RTL.
11. Make the design premium, not basic.
12. Handle errors gracefully.
13. Backend is the source of truth for:
    - `date_of_birth`
    - `gender`
    - `height`
    - `weight`
14. Do not duplicate patient demographics in the Flutter assessment flow.
15. Do not refactor unrelated project files.
16. Do not rewrite already working files unless needed.

---

## IMPORTANT IF CONTEXT GETS TOO LARGE

If the conversation context becomes too large or you fail while generating a big file:

Do not try to implement the full feature in one huge response.

Work incrementally file by file.

Recommended order:

1. Create models
2. Create question data
3. Create API client
4. Create shared UI widgets
5. Create Welcome screen
6. Create minimal compiling `assessment_flow_screen.dart`
7. Create Review screen
8. Add API submit
9. Create Loading screen
10. Create Report Result screen
11. Create Report History screen
12. Polish UI

If `assessment_flow_screen.dart` becomes too large, first create a minimal compiling version.

Minimal `assessment_flow_screen.dart` requirements:

- be a `StatefulWidget`
- show one question at a time from `cardiac_questions.dart`
- start from Medical History
- support choice, multiChoice, text, number
- store answers in `AssessmentState`
- have Back and Next buttons
- skip questions with failed `dependsOn`
- end with a simple placeholder text: "Review screen TODO"

No beautiful UI is required in the first version of this coordinator screen.

Make it compile first.

Then polish it in a second pass.

---

## FINAL DELIVERABLE

Please implement the full Flutter feature.

At the end, give me a final implementation report with:

1. Files created
2. Files modified
3. What is fully implemented
4. What is partially implemented
5. What is still missing
6. How to navigate to the assessment flow
7. How to test the full flow
8. Any assumptions made
9. Any backend/API constants that need configuration
10. Any backend changes needed because demographics now come from the backend profile
