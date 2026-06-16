---
name: habit-monthly-report
description: Use when user asks for a monthly habit report, habit statistics, habit summary, or a Telegram post about habits for a specific month — queries production DB and generates formatted markdown tables or a social media post
---

# Monthly Habit Report

Generate a comprehensive monthly report for a user's habits from the Privichkaysya production database. Supports two output formats: data table and Telegram post.

## Usage

User says something like:
- "Отчет по привычкам за март"
- "Покажи статистику привычек за февраль для пользователя X"
- "Сколько я сделал за прошлый месяц"
- "Сделай пост для телеграма по привычкам за март"

## Parameters

Ask the user if not provided:
- **Username** — DB username to look up (ask explicitly, never assume)
- **Month/Year** — target period (default: previous month)
- **Format** — `table` (default) or `post` (Telegram-style). If user says "пост"/"post" — use post format

## Production Access

**Always confirm before running queries.** Credentials are NOT stored here — use SSH + docker exec pattern from CLAUDE.md / deploy.conf.

```
ssh root@<PROD_HOST> "docker exec <DB_CONTAINER> psql -U <DB_USER> -d <DB_NAME> -c '<SQL>'"
```

## Query Sequence

### 0. Get public/private flag (needed for post format)

Add `uh.is_public` to the habits query in step 2. For post format, include ONLY `is_public = true` habits.

### 1. Find user

```sql
SELECT id, username, display_name FROM users WHERE username = '<USERNAME>';
```

### 2. Get active habits

```sql
SELECT
  uh.id, COALESCE(uh.custom_name, ht.name) as habit_name,
  uh.habit_type, uh.target_value, uh.unit, uh.is_public
FROM user_habits uh
LEFT JOIN habit_templates ht ON uh.habit_template_id = ht.id
WHERE uh.user_id = <UID> AND uh.deleted_at IS NULL
ORDER BY uh.id;
```

### 3. Get completions (run in parallel with step 4)

```sql
SELECT
  uh.id as habit_id,
  COALESCE(uh.custom_name, ht.name) as habit_name,
  COUNT(hc.id) as completions_count,
  STRING_AGG(hc.completion_date::text, ', ' ORDER BY hc.completion_date) as dates
FROM habit_completions hc
JOIN user_habits uh ON hc.user_habit_id = uh.id
LEFT JOIN habit_templates ht ON uh.habit_template_id = ht.id
WHERE uh.user_id = <UID>
  AND hc.completion_date >= '<YYYY-MM>-01'
  AND hc.completion_date < '<NEXT_MONTH>-01'
GROUP BY uh.id, uh.custom_name, ht.name
ORDER BY uh.id;
```

### 4. Get approaches (run in parallel with step 3)

```sql
SELECT
  uh.id as habit_id,
  COALESCE(uh.custom_name, ht.name) as habit_name,
  uh.habit_type, uh.target_value, uh.unit,
  ha.approach_date, SUM(ha.value) as day_total
FROM habit_approaches ha
JOIN user_habits uh ON ha.user_habit_id = uh.id
LEFT JOIN habit_templates ht ON uh.habit_template_id = ht.id
WHERE uh.user_id = <UID>
  AND ha.approach_date >= '<YYYY-MM>-01'
  AND ha.approach_date < '<NEXT_MONTH>-01'
GROUP BY uh.id, uh.custom_name, ht.name, uh.habit_type, uh.target_value, uh.unit, ha.approach_date
ORDER BY uh.id, ha.approach_date;
```

## Report Format

Group habits by type and present as markdown tables:

### Sum habits (daily cumulative)

| Привычка | Цель/день | Дней выполнено | Итого за месяц | % выполнения |
|----------|-----------|----------------|----------------|--------------|

- Calculate total from approaches (SUM of day_total)
- % = days completed / days in month
- Add human-readable conversion where appropriate (minutes -> hours)

### Checkbox habits (daily yes/no)

| Привычка | Дней выполнено | Пропуски | % выполнения |
|----------|----------------|----------|--------------|

- Count from completions table
- List skip count = days_in_month - completions

### Weekly habits

| Привычка | Цель/нед | Раз за месяц | Итого | Детали |
|----------|----------|--------------|-------|--------|

- Count sessions and sum values from approaches
- Note: target_value is times per week, not per day

### Goal habits (long-term targets)

| Привычка | Начало месяца | Конец месяца | Изменение |
|----------|---------------|--------------|-----------|

- First and last approach values in the month
- Calculate min/max for the period
- Note: values may be stored multiplied (e.g., 9570 = 95.70 kg)

### Tracking habits (no target, just logging)

| Привычка | Кол-во дней | Итого |
|----------|-------------|-------|

- Sum all approach values
- Count distinct days

### Summary section

At the end, add:
- **100% habits** — list names
- **70%+ habits** — list names
- **Needs attention (<50%)** — list names
- Notable achievements (streaks, personal records)

---

## Post Format (Telegram)

When user asks for a post — generate a Telegram-style text about the month. **Only include public habits** (`is_public = true`), unless the user explicitly asks to include a private habit by name in their own post.

If the user asks to "format as a file", "save for Telegram", or similar — save the final post as a `.md` file in the current working directory, named like `telegram_habits_<month>_<year>.md`.

Keep the post compact enough to fit into one Telegram message. Target length: **2200–3000 characters**. If the draft is too long, shorten comments before removing entire habit blocks.

### Structure

```
👋 Приветствие (1-2 предложения, разное каждый месяц)

Общая оценка месяца (1-2 предложения, личное впечатление)

[Блок на каждую публичную привычку — emoji + название + результат + комментарий]

Упоминание приватных привычек (1 предложение, без деталей)

👍 Вывод/мотивация (1-2 предложения)
```

### Правила написания

- **Язык:** русский, разговорный, от первого лица
- **Тон:** позитивный, честный (не скрывать провалы, но подавать конструктивно)
- **Длина:** 2200-3000 символов, чтобы помещалось в один Telegram-пост
- **Emoji:** один на привычку, ставить в начале абзаца
- **Свободная форма:** каждый месяц писать по-разному, но сохранять узнаваемый авторский стиль
- **Стиль автора:** живой личный отчёт от первого лица; честно отмечать провалы, но без самобичевания; сравнивать с прошлым месяцем, если данные есть; добавлять короткий личный комментарий, а не только цифры
- **Не копировать** структуру предыдущих постов дословно

### Что писать по каждой привычке

Для каждой публичной привычки — один абзац:
1. Emoji + название
2. Ключевая цифра: дней/месяц, итого за месяц
3. Сравнение с прошлым месяцем (если есть данные или пользователь предоставил)
4. Личный комментарий: что было легко/сложно, что изменилось, планы

### Примеры хороших абзацев

```
💪 Подтягивания — честно, просел. Всего 6 дней, 44 раза за месяц.
В феврале было 7 дней и 28 раз, так что по количеству за подход вырос
(с 4 до 7 за подход), но по регулярности надо подтягивать.

🚴 Велосипед — начал кататься в конце марта, 4 поездки на 43 км.
Весна пришла, сезон открыт!

📚 Чтение — каждое утро, все 31 день. 644 страницы за месяц.
В конце месяца увеличил норму — последние дни читал по 24-30 страниц
вместо обычных 20.
```

### Чего избегать

- Сухое перечисление цифр без комментариев
- Канцеляризмы ("данная привычка была выполнена на 77%")
- Одинаковая структура абзацев (не начинать каждый с "N дней из 31")
- Упоминание приватных привычек по названию, если пользователь сам не попросил включить их
- Хэштеги, ссылки, call-to-action
- Слишком длинные посты, которые не помещаются в одно сообщение

### Preferred Telegram post structure

Use this style as the default pattern:

```
👋 Привет!
Закончился <месяц> <год>, подвожу итоги по привычкам.

Короткая общая оценка месяца: что держится, что просело, что новое.

📚 Чтение — <результат>. <короткое сравнение/комментарий>.

🏋️ Силовой блок — <результат>. <комментарий про регулярность/нагрузку>.

💪 Подтягивания — <результат>. <честный комментарий, если просело>.

🎸 Гитара — <результат>. <комментарий>.

🏓 Настольный теннис — <результат>. <комментарий>.

🧖 Баня — <результат>. <комментарий про восстановление>.

⚖️ Вес — <начало, конец, изменение>. <комментарий>.

🧁 Без сахара — <результат>. <комментарий>.

🌙 Не есть после ужина — <результат>. <если новая привычка — отметить старт>.

🚴 Велосипед — <результат>. <если 0 из-за погоды — так и написать, не считать провалом>.

🫖 Чай на природе — <результат>. <комментарий>.

👍 Главный вывод <месяца> — <1-2 предложения>.
```

Adjust habit blocks to the actual data and user's edits. If the user provides corrections about context (weather, illness, travel, new habit, etc.), incorporate them into the final version and future drafts.
