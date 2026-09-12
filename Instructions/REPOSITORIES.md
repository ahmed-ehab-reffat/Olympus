# Olympus Repositories

Where to find issues — ranked repos, issue analysis, and Happy-DOM deep dive.

---

## Go Repositories

### Tier 1: Proven / Highly Recommended

| Rank | Repository | Stars | Category | Proven |
|------|------------|-------|----------|--------|
| 1 | mvdan/sh | 7.4k | Shell Parser/Interpreter | Similar repo (bunster) 2 approved |
| 2 | traefik/yaegi | 6.4k | Go Interpreter | 1 approved (#1674) |
| 3 | dop251/goja | 6.7k | JavaScript Engine | Pure Go ECMAScript |
| 4 | tetratelabs/wazero | 5.2k | WASM Runtime | 100% Go, no CGO |
| 5 | google/cel-go | 2.6k | Expression Language | Complex type system |

**mvdan/sh — BEST BET**
- Shell parser + interpreter (like bunster which had 2 approved)
- Feature ideas: coreutils builtins, variable expansion, arithmetic
- 99.9% Go, easy Docker

**dop251/goja — PROVEN**
- Full ECMAScript/JavaScript engine in pure Go
- Feature ideas: ES6+ features, Promise improvements, module system
- 6.7k stars, 24 open issues

### Tier 2: High Potential

| Rank | Repository | Stars | Category |
|------|------------|-------|----------|
| 6 | antonmedv/expr | 6.7k | Expression Language |
| 7 | rogchap/v8go | 3.6k | V8 Bindings |
| 8 | nicholasgasior/gopher-lua | 6.4k | Lua VM |

### Tier 3: Specialized

| Rank | Repository | Stars | Category |
|------|------------|-------|----------|
| 9 | d5/tengo | 3.7k | Scripting Language |
| 10 | ArelSHO/aho-corasick | 2.1k | String Matching |

---

## TypeScript Repositories

### Tier 1: Proven

| Rank | Repository | Stars | Category | Proven |
|------|------------|-------|----------|--------|
| 1 | elysiajs/elysia | 10k+ | Web Framework | 12 approved |
| 2 | capricorn86/happy-dom | 3.5k | DOM Implementation | 2 approved |
| 3 | harrisiirak/cron-parser | 1.5k | Cron Parser | 1 approved |

### Tier 2: Recommended

| Rank | Repository | Stars | Category |
|------|------------|-------|----------|
| 4 | privatenumber/cleye | 500+ | CLI Framework |
| 5 | unjs/citty | 500+ | CLI Framework |
| 6 | lukeed/clsx | 7k+ | Utility |

### Tier 3: Potential

| Rank | Repository | Stars | Category |
|------|------------|-------|----------|
| 7 | date-fns/date-fns | 35k | Date Utility |
| 8 | validatorjs/validator.js | 23k | Validation |

---

## Python Repositories

| Repository | Stars | Category | Proven |
|------------|-------|----------|--------|
| python-attrs/attrs | 5.4k | Classes | 1 approved (#734) |
| beetbox/beets | 13k | Music Manager | 1 approved (#6010) |
| python-jsonschema/jsonschema | 4.6k | JSON Schema | 1 approved (#191) |
| pimutils/khal | 2.7k | Calendar | 1 approved (#1406) |
| Textualize/textual | 26k | TUI Framework | 1 approved (#4968) |
| dooit-org/dooit | 2k | TUI Todo | Feature requests approved |

---

## Rust Repositories

### Potential
| Rank | Repository | Stars | Category |
|------|------------|-------|----------|
| 1 | TBD — use Query 2 to discover | | |

Rust is a newly supported language. Use Query 2 from PROMPTS.md with `SEARCH_CRITERIA` targeting Rust repos with behavioral testing infrastructure.

---

## Best Feature Request Ideas

### Go
- **goja**: Iterator helpers, decorators, using declarations, coverage API, memory limits
- **wazero**: Function stats, call graphs, fuel metering, memory tracing, debug info
- **mvdan/sh**: Coreutils builtins (date, printf), arithmetic expansion, process substitution
- **yaegi**: min/max builtins, type parameter support

### TypeScript
- **happy-dom**: CloseWatcher API, namespace handling, Cookie Store API
- **cron-parser**: DST gap/overlap resolution
- **cleye**: Union types with type inference
- **elysia**: Complex lifecycle scenarios (already well-mined)

### Python
- **dooit**: Archive functionality, completion, recurrence

---

## Happy-DOM Deep Dive

### Selection Criteria

**"Hard Enough" Requirements (based on approved/rejected):**
- Solution: 400+ lines across 3+ files
- Tests: 15+ tests, comprehensive coverage, behavior-focused
- Problem description: 70-120 words
- Must not have obvious fix in issue comments

### Recommended Issues (Ranked by Complexity)

**HARD Feature Requests (Recommended):**
1. CloseWatcher API — new module, event system, lifecycle management
2. Namespace handling — SVG/XML namespace support
3. CSSStyleSheet adoption — constructable stylesheets
4. Range/Selection API — complex DOM operations
5. IntersectionObserver improvements — partial implementation exists

**HARD Bugs (Recommended):**
1. Complex event propagation issues
2. CSS cascade/specificity edge cases
3. Shadow DOM boundary issues
4. Custom element lifecycle bugs

### Already Used/Unsuitable Issues
- #1283 — elementFromPoint (APPROVED)
- #1893 — Cookie Store API (APPROVED)
- #1878 — WeakRef pattern (REJECTED — too obvious)
- #1963 — Fix in comments (REJECTED)

### Happy-DOM Bug Clusters

**Event System (20+ issues):**
- Event propagation across shadow DOM
- Custom event handling
- Event target resolution

**CSS (15+ issues):**
- Computed style calculation
- Specificity resolution
- Shorthand property expansion

**DOM API (25+ issues):**
- TreeWalker/NodeIterator edge cases
- Range API gaps
- MutationObserver limitations

**HTML Parsing (10+ issues):**
- Self-closing tag handling
- Attribute parsing edge cases
- Template element behavior

### Happy-DOM Dockerfile
```dockerfile
FROM public.ecr.aws/d3j8x8q7/olympus-base:latest
WORKDIR /app
COPY . .
ENV NODE_ENV=development
RUN npm install --include=dev --ignore-scripts
CMD ["/bin/bash"]
```

---

## Docker Reference by Language

| Language | Install Command | Notes |
|----------|----------------|-------|
| Python (pip) | `pip install -e .` | |
| Python (uv) | `uv sync --frozen` | |
| Python (poetry) | `poetry install` | |
| TypeScript (bun) | `bun install` | |
| TypeScript (npm) | `npm install` | Add `--include=dev` if needed |
| Go | `go mod download` | |
| Rust | `cargo build` | |

Always use `CMD ["/bin/bash"]`.

