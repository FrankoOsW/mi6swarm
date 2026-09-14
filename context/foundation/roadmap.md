---
project: "10xMI6Swarm"
version: 1
status: draft
created: 2026-08-29
updated: 2026-09-14
prd_version: 1
main_goal: quality
top_blocker: decisions
milestone_id: first-working-agent
milestone_seq: 1
milestone_status: open
---

# Roadmap: 10xMI6Swarm

> Derived from PRD at `context/foundation/prd.md` (v1) + auto-researched codebase baseline.
> Edit-in-place; archive when superseded.
> Slices below are listed in dependency order. The "At a glance" table is the index.

## Milestone

**M-1: First working agent** — Status: open

- **Intent:** Prove that LLM-based knowledge synthesis works for competitive data questions — a Data Analyst can log in, ask a question, and receive an accurate, sourced answer from a specialist agent.
- **Source materials:** `context/foundation/prd.md` (v1)
- **Done when:** every F-NN and S-NN below is `done`.
- **Scope anchors:** FR-001 through FR-011, US-01

## Vision recap

Data Analysts at OLX waste hours searching scattered sources (GitLab ETL code, Confluence docs, vendor specs) to answer competitive data questions. The product hypothesis is that LLMs can now synthesize across these sources in a way static documentation cannot — delivering accurate, sourced answers that would have taken hours to assemble manually. This milestone proves that hypothesis with one working specialist before expanding to multi-specialist routing.

## North star

**S-01: First gated answer** — The smallest end-to-end flow that proves the product works: a user logs in, asks a question, and receives a sourced answer from one specialist. This slice validates the core hypothesis — that LLM-based knowledge synthesis delivers trusted, accurate answers. Everything else only matters if this works.

## At a glance

| ID   | Change ID                  | Outcome (user can ...)                                                      | Prerequisites | PRD refs                         | Status   |
| ---- | -------------------------- | --------------------------------------------------------------------------- | ------------- | -------------------------------- | -------- |
| F-01 | sso-auth-scaffold          | (foundation) log in via OLX SSO                                             | —             | FR-001, Access Control           | in-progress |
| S-01 | first-gated-answer         | ask a question and receive a sourced answer from one specialist             | F-01          | FR-002, FR-003, FR-005, FR-006, US-01 | in-progress |
| S-02 | conversation-followups     | ask follow-up questions in the same conversation                            | S-01          | FR-007                           | proposed |
| S-03 | supervisor-routing         | ask about Traffic OR autoplac.pl and get routed to the right specialist     | S-01          | FR-004, US-01                    | proposed |
| S-04 | clarifying-questions       | receive a clarifying question when query spans multiple domains             | S-03          | FR-010, US-01                    | proposed |
| S-05 | mid-conversation-rerouting | have the conversation re-routed when domain shifts mid-thread               | S-02, S-03    | FR-008                           | proposed |
| S-06 | live-data-queries          | receive answers that include live data from Redshift/Trino via MCP          | S-01          | FR-011                           | proposed |

## Streams

Navigation aid — groups items that share a Prerequisites chain. Canonical ordering still lives in the dependency graph below; this table is the proposed reading order across parallel tracks.

| Stream | Theme              | Chain                     | Note                                                                 |
| ------ | ------------------ | ------------------------- | -------------------------------------------------------------------- |
| A      | Core conversation  | `F-01` → `S-01` → `S-02`  | Auth to first answer to follow-ups; quality goal's critical path     |
| B      | Multi-specialist   | `S-03` → `S-04` → `S-05`  | Routing and clarification; S-05 joins Stream A at S-02               |
| C      | Live data          | `S-06`                    | Data Platform MCP integration; independent track after S-01          |

## Baseline

What's already in place in the codebase as of 2026-08-29 (auto-researched + user-confirmed).
Foundations below assume these are present and do NOT re-scaffold them.

- **Frontend:** absent — headless API backend, no browser UI or templates
- **Backend / API:** present — Django project `config` + `core` app, health endpoints at `src/config/urls.py`
- **Data:** absent — no Django models or migrations
- **Auth:** absent — Django default session only, no SSO/OIDC integration
- **Deploy / infra:** present — Dockerfile, GitLab CI, Terraform modules under `assets-cd/`, K8s Helm charts
- **Observability:** present — Sentry, OpenTelemetry, New Relic configured in Pipfile and K8s values

## Foundations

### F-01: SSO Auth scaffold

- **Outcome:** (foundation) OLX SSO integration wired; users can log in with corporate identity and session is established.
- **Change ID:** sso-auth-scaffold
- **PRD refs:** FR-001, Access Control section, Guardrail "SSO must work reliably"
- **Unlocks:** S-01, S-02, S-03, S-04, S-05, S-06 (all slices require authenticated user)
- **Prerequisites:** —
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** SSO is a gating foundation; if it doesn't work reliably, users can't access the product at all. Sequenced first because it's on the critical path and has no dependencies.
- **Status:** in-progress

## Slices

### S-01: First gated answer

- **Outcome:** user can log in, ask a question in natural language, and receive a sourced answer from one specialist that explains where the data lives and how it's processed.
- **Change ID:** first-gated-answer
- **PRD refs:** FR-002, FR-003, FR-005, FR-006, US-01
- **Prerequisites:** F-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - Which knowledge sources to index for the first specialist (GitLab repos, Confluence spaces, vendor docs)? — Owner: user. Block: no (can build pipeline with test data; real sources needed before launch).
- **Risk:** This is the north star — the smallest proof that the product hypothesis works. If knowledge synthesis doesn't produce accurate, sourced answers here, the entire product is invalidated. Quality goal means we invest deeply in prompt engineering and retrieval quality.
- **Status:** in-progress

### S-02: Conversation follow-ups

- **Outcome:** user can ask follow-up questions in the same conversation, with the specialist maintaining context from prior turns.
- **Change ID:** conversation-followups
- **PRD refs:** FR-007
- **Prerequisites:** S-01
- **Parallel with:** S-03, S-06
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Context passing between turns is where hallucination risk compounds — earlier context can prime incorrect associations. Quality goal means conversation state design must preserve grounding.
- **Status:** proposed

### S-03: Supervisor routing to two specialists

- **Outcome:** user can ask about Traffic OR autoplac.pl and the supervisor agent routes the question to the appropriate specialist.
- **Change ID:** supervisor-routing
- **PRD refs:** FR-004, US-01
- **Prerequisites:** S-01
- **Parallel with:** S-02, S-06
- **Blockers:** —
- **Unknowns:**
  - What are the exact boundaries between Traffic domain and autoplac.pl domain? — Owner: user. Block: no (can build routing architecture; tuning needs domain knowledge).
- **Risk:** Routing errors send questions to the wrong specialist, producing confidently wrong answers. Quality goal means supervisor classification must be conservative — when uncertain, escalate to clarification (S-04) rather than guess.
- **Status:** proposed

### S-04: Supervisor clarifying questions

- **Outcome:** when a query spans multiple domains or is ambiguous, the supervisor asks a clarifying question before routing.
- **Change ID:** clarifying-questions
- **PRD refs:** FR-010, US-01 (acceptance criteria: "Supervisor detects cross-domain ambiguity and asks clarifying question")
- **Prerequisites:** S-03
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Over-triggering clarification frustrates users; under-triggering sends ambiguous queries to the wrong specialist. Quality goal means tuning sensitivity carefully per PRD Socrates note.
- **Status:** proposed

### S-05: Mid-conversation re-routing

- **Outcome:** when the user shifts domains mid-conversation (e.g., starts with Traffic, then asks about autoplac.pl), the supervisor re-routes to the new specialist while preserving conversation context.
- **Change ID:** mid-conversation-rerouting
- **PRD refs:** FR-008
- **Prerequisites:** S-02, S-03
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Re-routing must pass conversation context to the new specialist (per PRD Socrates note) to avoid information loss. Quality goal means context handoff is explicit, not implicit.
- **Status:** proposed

### S-06: Live data queries

- **Outcome:** specialist can query live data from Redshift/Trino via Data Platform MCP to answer questions with current information, not just pre-indexed documentation.
- **Change ID:** live-data-queries
- **PRD refs:** FR-011
- **Prerequisites:** S-01
- **Parallel with:** S-02, S-03
- **Blockers:** —
- **Unknowns:**
  - Which Redshift/Trino tables are relevant and what access does the agent need? — Owner: user. Block: no (can build MCP integration; table access is config).
- **Risk:** Live queries can return large or sensitive data; agent must summarize appropriately and respect access controls. Quality goal means query generation must be conservative.
- **Status:** proposed

## Backlog Handoff

| Roadmap ID | Change ID                  | Suggested issue title                                      | Ready for `/10x-plan` | Notes                              |
| ---------- | -------------------------- | ---------------------------------------------------------- | --------------------- | ---------------------------------- |
| F-01       | sso-auth-scaffold          | Integrate OLX SSO authentication                           | yes                   | Run `/10x-plan sso-auth-scaffold`  |
| S-01       | first-gated-answer         | First gated answer: single specialist with sourced response| no                    | Needs F-01 done first              |
| S-02       | conversation-followups     | Enable follow-up questions in conversation                 | no                    | Needs S-01 done first              |
| S-03       | supervisor-routing         | Supervisor routes between Traffic and autoplac.pl specialists | no                 | Needs S-01 done first              |
| S-04       | clarifying-questions       | Supervisor asks clarifying questions for ambiguous queries | no                    | Needs S-03 done first              |
| S-05       | mid-conversation-rerouting | Re-route conversation when domain shifts                   | no                    | Needs S-02 and S-03 done first     |
| S-06       | live-data-queries          | Specialist queries live data via Data Platform MCP         | no                    | Needs S-01 done first              |

## Open Roadmap Questions

1. **What specific GitLab repositories contain the competitive data ETL code?** — Owner: user. Block: S-01 content (not planning).
2. **What Confluence spaces contain relevant documentation?** — Owner: user. Block: S-01 content (not planning).
3. **What external vendor documentation needs to be indexed?** — Owner: user. Block: S-01 content (not planning).
4. **What are the exact boundaries between Traffic domain and autoplac.pl domain?** — Owner: user. Block: S-03, S-04, S-05 tuning (not planning).

## Parked

- **FR-009: View conversation history** — Why parked: nice-to-have per PRD; MVP proves knowledge synthesis first.
- **Additional specialist domains** — Why parked: PRD §Non-Goals; MVP covers Traffic + autoplac.pl only.
- **JIRA ticket creation** — Why parked: PRD §Non-Goals; deferred to v2.
- **Mobile version** — Why parked: PRD §Non-Goals; internal tool used at desks.
- **Code generation / feature implementation** — Why parked: PRD §Non-Goals; agents answer questions, don't write code.
- **General market/competitor knowledge** — Why parked: PRD §Non-Goals; agents are data librarians, not market analysts.
- **Multi-language support beyond EN/PL** — Why parked: PRD §Non-Goals; internal OLX tool.
- **Offline support** — Why parked: PRD §Non-Goals; agents query live systems.

## Milestone History

(Empty — this is the first milestone.)

## Done

(Empty on first generation. `/10x-archive` appends entries here when changes are archived.)
