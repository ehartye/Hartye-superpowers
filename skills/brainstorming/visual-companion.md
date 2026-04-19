# Visual Companion Guide

Browser-based visual brainstorming companion for showing mockups, diagrams, and options.

## When to Use

Decide per-question, not per-session. The test: **would the user understand this better by seeing it than reading it?**

**Use the browser** when the content itself is visual:

- **UI mockups** — wireframes, layouts, navigation structures, component designs
- **Architecture diagrams** — system components, data flow, relationship maps
- **Side-by-side visual comparisons** — comparing two layouts, two color schemes, two design directions
- **Design polish** — when the question is about look and feel, spacing, visual hierarchy
- **Spatial relationships** — state machines, flowcharts, entity relationships rendered as diagrams

**Use the terminal** when the content is text or tabular:

- **Requirements and scope questions** — "what does X mean?", "which features are in scope?"
- **Conceptual A/B/C choices** — picking between approaches described in words
- **Tradeoff lists** — pros/cons, comparison tables
- **Technical decisions** — API design, data modeling, architectural approach selection
- **Clarifying questions** — anything where the answer is words, not a visual preference

A question *about* a UI topic is not automatically a visual question. "What kind of wizard do you want?" is conceptual — use the terminal. "Which of these wizard layouts feels right?" is visual — use the browser.

## How It Works

The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.

**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.

## Starting a Session

```bash
# Start server with persistence (mockups saved to project)
scripts/start-server.sh --project-dir /path/to/project

# Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
```

Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.

**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.

**Note:** Pass the project root as `--project-dir` so mockups persist in `.superpowers/brainstorm/` and survive server restarts. Without it, files go to `/tmp` and get cleaned up. Remind the user to add `.superpowers/` to `.gitignore` if it's not already there.

**Launching the server by platform:**

**Claude Code (macOS / Linux):**
```bash
# Default mode works — the script backgrounds the server itself
scripts/start-server.sh --project-dir /path/to/project
```

**Claude Code (Windows):**
```bash
# Windows auto-detects and uses foreground mode, which blocks the tool call.
# Use run_in_background: true on the Bash tool call so the server survives
# across conversation turns.
scripts/start-server.sh --project-dir /path/to/project
```
When calling this via the Bash tool, set `run_in_background: true`. Then read `$STATE_DIR/server-info` on the next turn to get the URL and port.

**Codex:**
```bash
# Codex reaps background processes. The script auto-detects CODEX_CI and
# switches to foreground mode. Run it normally — no extra flags needed.
scripts/start-server.sh --project-dir /path/to/project
```

**Gemini CLI:**
```bash
# Use --foreground and set is_background: true on your shell tool call
# so the process survives across turns
scripts/start-server.sh --project-dir /path/to/project --foreground
```

**Other environments:** The server must keep running in the background across conversation turns. If your environment reaps detached processes, use `--foreground` and launch the command with your platform's background execution mechanism.

If the URL is unreachable from your browser (common in remote/containerized setups), bind a non-loopback host:

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

Use `--url-host` to control what hostname is printed in the returned URL JSON.

## The Loop

1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
   - Before each write, check that `$STATE_DIR/server-info` exists. If it doesn't (or `$STATE_DIR/server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
   - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
   - **Never reuse filenames** — each screen gets a fresh file
   - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
   - Server automatically serves the newest file

2. **Tell user what to expect and end your turn:**
   - Remind them of the URL (every step, not just first)
   - Give a brief text summary of what's on screen (e.g., "Showing 3 layout options for the homepage")
   - Ask them to respond in the terminal: "Take a look and let me know what you think. Click to select an option if you'd like."

3. **On your next turn** — after the user responds in the terminal:
   - Read `$STATE_DIR/events` if it exists — this contains the user's browser interactions (clicks, selections) as JSON lines
   - Merge with the user's terminal text to get the full picture
   - The terminal message is the primary feedback; `state_dir/events` provides structured interaction data

4. **Iterate or advance** — if feedback changes current screen, write a new file (e.g., `layout-v2.html`). Only move to the next question when the current step is validated.

5. **Unload when returning to terminal** — when the next step doesn't need the browser (e.g., a clarifying question, a tradeoff discussion), push a waiting screen to clear the stale content:

   ```html
   <!-- filename: waiting.html (or waiting-2.html, etc.) -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">Continuing in terminal...</p>
   </div>
   ```

   This prevents the user from staring at a resolved choice while the conversation has moved on. When the next visual question comes up, push a new content file as usual.

6. Repeat until done.

## Writing Content Fragments

Write just the content that goes inside the page. The server wraps it in the frame template automatically (header, theme CSS, selection indicator, and all interactive infrastructure).

**Minimal example:**

```html
<h2>Which layout works better?</h2>
<p class="subtitle">Consider readability and visual hierarchy</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Single Column</h3>
      <p>Clean, focused reading experience</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>Two Column</h3>
      <p>Sidebar navigation with main content</p>
    </div>
  </div>
</div>
```

That's it. No `<html>`, no CSS, no `<script>` tags needed. The server provides all of that.

## CSS Classes Available

The frame template provides these CSS classes for your content:

### Options (A/B/C choices)

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>Title</h3>
      <p>Description</p>
    </div>
  </div>
</div>
```

**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item. The indicator bar shows the count.

```html
<div class="options" data-multiselect>
  <!-- same option markup — users can select/deselect multiple -->
</div>
```

### Cards (visual designs)

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- mockup content --></div>
    <div class="card-body">
      <h3>Name</h3>
      <p>Description</p>
    </div>
  </div>
</div>
```

### Mockup container

```html
<div class="mockup">
  <div class="mockup-header">Preview: Dashboard Layout</div>
  <div class="mockup-body"><!-- your mockup HTML --></div>
</div>
```

### Split view (side-by-side)

```html
<div class="split">
  <div class="mockup"><!-- left --></div>
  <div class="mockup"><!-- right --></div>
</div>
```

### Pros/Cons

```html
<div class="pros-cons">
  <div class="pros"><h4>Pros</h4><ul><li>Benefit</li></ul></div>
  <div class="cons"><h4>Cons</h4><ul><li>Drawback</li></ul></div>
</div>
```

### Mock elements (wireframe building blocks)

```html
<div class="mock-nav">Logo | Home | About | Contact</div>
<div style="display: flex;">
  <div class="mock-sidebar">Navigation</div>
  <div class="mock-content">Main content area</div>
</div>
<button class="mock-button">Action Button</button>
<input class="mock-input" placeholder="Input field">
<div class="placeholder">Placeholder area</div>
```

### Typography and sections

- `h2` — page title
- `h3` — section heading
- `.subtitle` — secondary text below title
- `.section` — content block with bottom margin
- `.label` — small uppercase label text

## Diagrams and Architecture

For architecture diagrams, flowcharts, sequences, and state machines, use **Mermaid**. The frame template lazy-loads Mermaid when it sees a `<pre class="mermaid">` block — no setup needed, just drop the block in.

**The pattern:**

```html
<h2>Our proposed service architecture</h2>
<pre class="mermaid">
graph LR
    Client --> API
    API --> Auth[Auth Service]
    API --> DB[(Postgres)]
    API --> Queue[[Job Queue]]
    Queue --> Worker
    Worker --> DB
</pre>
```

That's it. The mermaid block renders inline as an SVG on page load. Combine freely with options, cards, mockups, and pros/cons.

### Which diagram type for which question

| Question shape | Mermaid diagram type |
|---|---|
| "How do these services talk to each other?" | `graph LR` / `graph TD` (flowchart) |
| "What are the layers of this system?" | `graph TB` with subgraphs |
| "How does data move through the pipeline?" | `graph LR` with labeled edges |
| "What's the request/response flow for X?" | `sequenceDiagram` |
| "Where does this run — which servers, containers, clouds?" | `graph TB` with subgraphs representing zones |
| "What states can this resource be in?" | `stateDiagram-v2` |
| "What's the decision logic for Y?" | `flowchart TD` with diamond decision nodes |

### Worked examples

Each example below is ready to paste into a `<pre class="mermaid">` block.

**1. System / component diagram** — services and their dependencies:

```
graph LR
    Client[Web Client] --> Gateway[API Gateway]
    Mobile[Mobile App] --> Gateway
    Gateway --> Auth[Auth Service]
    Gateway --> Orders[Orders Service]
    Gateway --> Inventory[Inventory Service]
    Orders --> OrdersDB[(Orders DB)]
    Inventory --> InvDB[(Inventory DB)]
    Orders -.publishes.-> Queue[[Event Queue]]
    Queue -.consumes.-> Notifier[Notifier]
```

Use `[(...)]` for databases, `[[...]]` for queues, dashed arrows (`-.-`) for async events.

**2. Layered architecture** — use subgraphs to stack tiers:

```
graph TB
    subgraph Presentation
        UI[Web UI]
        API[REST API]
    end
    subgraph Business
        OrdersSvc[Orders Service]
        PaymentSvc[Payments Service]
    end
    subgraph Data
        DB[(Postgres)]
        Cache[(Redis)]
    end
    UI --> API
    API --> OrdersSvc
    API --> PaymentSvc
    OrdersSvc --> DB
    OrdersSvc --> Cache
    PaymentSvc --> DB
```

**3. Data flow diagram** — edges labeled with what moves across them:

```
graph LR
    Source[Event Source] -->|raw events| Ingest[Ingestion]
    Ingest -->|normalized| Validator
    Validator -->|valid| Stream[[Kafka]]
    Validator -->|rejected| DLQ[[Dead Letter Queue]]
    Stream --> Processor
    Processor -->|aggregates| Warehouse[(Data Warehouse)]
    Processor -->|metrics| Metrics[Prometheus]
```

**4. Sequence diagram** — interactions over time:

```
sequenceDiagram
    participant U as User
    participant W as Web App
    participant A as Auth Service
    participant D as Database

    U->>W: Login (email, password)
    W->>A: POST /authenticate
    A->>D: SELECT user WHERE email=?
    D-->>A: user record
    A->>A: verify password hash
    A-->>W: JWT token
    W-->>U: Set session, redirect
```

Use `->>` for requests, `-->>` for responses, `->>` with a note for internal work.

**5. Deployment diagram** — physical zones as subgraphs:

```
graph TB
    subgraph Browser
        App[SPA]
    end
    subgraph CloudFront
        CDN[Static Assets]
    end
    subgraph AWS_VPC[AWS VPC]
        subgraph Public_Subnet[Public Subnet]
            LB[Application Load Balancer]
        end
        subgraph Private_Subnet[Private Subnet]
            API1[API Instance 1]
            API2[API Instance 2]
            RDS[(RDS Postgres)]
        end
    end
    App --> CDN
    App --> LB
    LB --> API1
    LB --> API2
    API1 --> RDS
    API2 --> RDS
```

**6. State machine** — lifecycle of a resource:

```
stateDiagram-v2
    [*] --> Draft
    Draft --> PendingReview: submit
    PendingReview --> Approved: reviewer approves
    PendingReview --> Draft: reviewer requests changes
    Approved --> Published: publish
    Published --> Archived: archive
    Archived --> [*]
    PendingReview --> Rejected: reviewer rejects
    Rejected --> [*]
```

Use `[*]` for start/end; the colon after each transition is the event.

**7. Decision flowchart** — branching logic:

```
flowchart TD
    Start([Incoming request]) --> Auth{Authenticated?}
    Auth -->|no| Reject[401 Unauthorized]
    Auth -->|yes| Rate{Within rate limit?}
    Rate -->|no| RateLimit[429 Too Many Requests]
    Rate -->|yes| Tier{User tier?}
    Tier -->|free| FreeHandler[Free handler]
    Tier -->|paid| PaidHandler[Paid handler]
    FreeHandler --> Response([Respond])
    PaidHandler --> Response
```

Diamond shapes (`{...}`) are decisions; rounded-rectangle (`([...])`) are start/end.

### Styling notes

- Diagrams render centered inside a card-style container that matches the theme (light/dark auto-switches with OS preference).
- For larger diagrams, wrap the `<pre class="mermaid">` in a `.mockup` if you want a labeled header.
- Combine with a `.subtitle` above for context: `<p class="subtitle">Three candidate architectures — click the one to refine</p>`.
- To show multiple architecture *options* for the user to pick, use `.options` or `.cards` with one `<pre class="mermaid">` inside each. The user clicks the container to select; the diagrams render regardless of selection.

### Combining mermaid with choice options

For "here are three architecture approaches, which do you prefer?", embed a diagram inside each option:

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content" style="width:100%">
      <h3>Monolith</h3>
      <pre class="mermaid">graph LR; Client --> App; App --> DB[(Postgres)]</pre>
      <p>Single deployable. Simplest to ship, hardest to scale parts independently.</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content" style="width:100%">
      <h3>Service-per-bounded-context</h3>
      <pre class="mermaid">
graph LR
    Client --> Gateway
    Gateway --> Orders
    Gateway --> Catalog
    Orders --> OrdersDB[(Orders)]
    Catalog --> CatalogDB[(Catalog)]
      </pre>
      <p>Isolated data stores per service. Heavier to operate, clearer boundaries.</p>
    </div>
  </div>
</div>
```

## Browser Events Format

When the user clicks options in the browser, their interactions are recorded to `$STATE_DIR/events` (one JSON object per line). The file is cleared automatically when you push a new screen.

```jsonl
{"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
{"type":"click","choice":"c","text":"Option C - Complex Grid","timestamp":1706000108}
{"type":"click","choice":"b","text":"Option B - Hybrid","timestamp":1706000115}
```

The full event stream shows the user's exploration path — they may click multiple options before settling. The last `choice` event is typically the final selection, but the pattern of clicks can reveal hesitation or preferences worth asking about.

If `$STATE_DIR/events` doesn't exist, the user didn't interact with the browser — use only their terminal text.

## Design Tips

- **Scale fidelity to the question** — wireframes for layout, polish for polish questions
- **Explain the question on each page** — "Which layout feels more professional?" not just "Pick one"
- **Iterate before advancing** — if feedback changes current screen, write a new version
- **2-4 options max** per screen
- **Use real content when it matters** — for a photography portfolio, use actual images (Unsplash). Placeholder content obscures design issues.
- **Keep mockups simple** — focus on layout and structure, not pixel-perfect design

## File Naming

- Use semantic names: `platform.html`, `visual-style.html`, `layout.html`
- Never reuse filenames — each screen must be a new file
- For iterations: append version suffix like `layout-v2.html`, `layout-v3.html`
- Server serves newest file by modification time

## Cleaning Up

```bash
scripts/stop-server.sh $SESSION_DIR
```

If the session used `--project-dir`, mockup files persist in `.superpowers/brainstorm/` for later reference. Only `/tmp` sessions get deleted on stop.

## Reference

- Frame template (CSS reference): `scripts/frame-template.html`
- Helper script (client-side): `scripts/helper.js`
