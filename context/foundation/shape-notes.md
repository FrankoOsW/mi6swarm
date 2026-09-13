---
project: "10xMI6Swarm"
context_type: greenfield
created: 2026-05-27
updated: 2026-05-29
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  gray_areas_resolved:
    - topic: "primary persona"
      decision: "Data Analyst (with PMs, data engineers, stakeholders as secondary)"
    - topic: "pain moment"
      decision: "Building reports, answering urgent questions, validating data"
    - topic: "insight"
      decision: "LLMs can synthesize scattered knowledge; aligns with OLX AI policy"
    - topic: "auth strategy"
      decision: "SSO via OLX corporate identity; flat access model"
    - topic: "MVP scope"
      decision: "2 specialists (Traffic + autoplac.pl); pre-indexed knowledge; no JIRA"
    - topic: "timeline"
      decision: "4-6 weeks mixed work/personal; acknowledged longer than typical"
  frs_drafted: 11
  quality_check_status: accepted
---

## Vision & Problem Statement

Data Analysts at OLX struggle to find, understand, and trust competitive data. The information is scattered across GitLab (ETL code), Confluence (internal documentation), and external vendor documentation — in multiple formats and with varying degrees of freshness.

The cost is high: hours of manual searching, interrupting domain experts who "just know" where things are, and proceeding with data they don't fully trust. The result is slower reporting, lower confidence in analysis, and wasted expert time.

**Insight**: Static documentation cannot solve this. The knowledge is too contextual — understanding competitive data requires connecting ETL code logic with internal docs and vendor specs. LLMs can now synthesize across these sources in a way that wasn't viable before. This also aligns with OLX's current strategic emphasis on AI and AI agents.

## User & Persona

### Primary persona

**Data Analyst** — responsible for analyzing competitive data and producing reports or dashboards. They need to find the right data source, understand its logic, and trust its quality. They feel the pain most acutely when building reports, answering urgent stakeholder questions, or validating data they've already found.

### Secondary personas

- **Product Manager** — needs competitive insights to inform product decisions
- **Data Engineer** — builds/maintains ETL pipelines; often the "expert" who gets interrupted
- **Business Stakeholder** — consumes insights but doesn't work with raw data

## Access Control

**Authentication**: SSO via OLX corporate identity. Users log in with their existing OLX account — no separate credentials or account creation.

**Authorization**: Flat model. All authenticated OLX employees have equal access to the agent swarm. No role separation (admin vs. member) in the MVP.

## Success Criteria

### Primary
- Specialists answer questions accurately — when asked about Traffic or autoplac.pl data, the specialist gives correct, sourced answers
- Routing works correctly — supervisor reliably sends Traffic questions to Traffic Specialist, autoplac.pl questions to autoplac.pl Specialist
- Users trust the answers — users don't feel the need to double-check the agent's answers manually

### Secondary
- Users discover data sources they didn't know existed — the agent surfaces relevant sources the user wouldn't have found on their own

### Guardrails
- No hallucinated data sources — agent must not invent sources that don't exist; better to say "I don't know" than fabricate
- Response time stays reasonable — users shouldn't wait more than ~30 seconds for an answer
- SSO must work reliably — auth failures block the entire product; login must be solid

## MVP Scope

**In scope (v1)**:
- Web app with SSO via OLX corporate identity
- Chat interface with supervisor agent
- Two specialist agents: Traffic + autoplac.pl
- Multi-turn conversation with dynamic re-routing when domain shifts
- Pre-indexed knowledge (GitLab ETL code, Confluence docs, vendor documentation)
- Live data queries via Data Platform MCP (Redshift, Trino)

**Out of scope (deferred to v2+)**:
- Additional specialist domains beyond Traffic and autoplac.pl
- Live knowledge ingestion (v1 uses pre-indexed snapshots)
- JIRA ticket creation
- Mobile version

**Timeline**: 4-6 weeks (mixed work/personal time) — acknowledged as longer than typical 3-week target

## Functional Requirements

### Authentication
- FR-001: User can log in via OLX SSO. Priority: must-have
  > Socrates: No counter-argument; SSO is the right choice for an internal OLX tool.

### Conversation
- FR-002: User can start a new conversation with the supervisor agent. Priority: must-have
  > Socrates: Counter-argument considered: "single ongoing conversation might be simpler." Resolution: kept; users need fresh starts when switching topics, but consider simplified UX.
- FR-003: User can ask a question in natural language. Priority: must-have
  > Socrates: No counter-argument; natural language is the whole point of an AI agent.
- FR-007: User can ask follow-up questions in the same conversation. Priority: must-have
  > Socrates: Counter-argument considered: "stateless Q&A is simpler." Resolution: kept; follow-ups are essential for exploring topics naturally.
- FR-009: User can view conversation history. Priority: nice-to-have
  > Socrates: No counter-argument; nice-to-have is the right priority for MVP.

### Routing
- FR-004: Supervisor can route a question to the appropriate specialist (Traffic or autoplac.pl). Priority: must-have
  > Socrates: Counter-argument considered: "overkill for only 2 specialists." Resolution: kept; needed for future scalability as more specialists will be added.
- FR-008: Supervisor can re-route mid-conversation when domain shifts. Priority: must-have
  > Socrates: Counter-argument considered: "re-routing might lose context." Resolution: kept; **must pass conversation context to new specialist** to avoid information loss.
- FR-010: Supervisor can ask clarifying questions when a query spans multiple domains. Priority: must-have
  > Socrates: Counter-argument considered: "might over-trigger on simple questions." Resolution: kept; **tune sensitivity carefully** to avoid frustrating users with unnecessary clarifications.

### Specialist Responses
- FR-005: Specialist can answer questions about its domain with sourced information. Priority: must-have
  > Socrates: Counter-argument considered: "risk of wrong citations / hallucinated sources." Resolution: kept; **critical guardrail** — better to say "I don't know the source" than cite incorrectly.
- FR-006: Specialist can explain the logic behind the data (ETL, best practices). Priority: must-have
  > Socrates: Counter-argument considered: "too technical for non-engineers." Resolution: kept; explanation should be optional/on-demand, not forced on every answer.
- FR-011: Specialist can query live data from Redshift/Trino via Data Platform MCP. Priority: must-have
  > Socrates: (Added late in shaping) This enables specialists to answer questions with current data, not just documentation.

## User Stories

### US-01: Data Analyst gets competitive data answer via agent swarm

- **Given** a logged-in Data Analyst with a question about competitive data
- **When** they type "What traffic data do we have for autoplac.pl?" into the chat
- **Then** the supervisor recognizes domain ambiguity and asks: "Are you asking about traffic data methodology, or specifically about autoplac.pl?"
- **And when** the user clarifies (e.g., "specifically autoplac.pl traffic")
- **Then** the supervisor routes to autoplac.pl specialist, who responds with sourced information

#### Acceptance Criteria
- Supervisor detects cross-domain ambiguity and asks clarifying question
- After clarification, response includes specific data source with location
- Response explains data freshness/update frequency
- If no relevant data exists, specialist says "I don't know" rather than fabricating
- Full exchange (including clarification) completes within 30 seconds

## Business Logic

The supervisor agent routes each question to a domain specialist who synthesizes knowledge across GitLab ETL code, Confluence documentation, and vendor specs to provide accurate, sourced answers with contextual best practices.

**Inputs**:
- User's natural language question
- Conversation context (prior turns in the thread)

**Output**:
- Sourced answer identifying where data lives (GitLab repo, Confluence page, vendor system)
- Explanation of data processing logic (ETL, update frequency) — on request or when relevant
- Best practice guidance for using the data correctly

**How user encounters it**: User asks a question in natural language. Routing to the appropriate specialist happens invisibly. The specialist responds with synthesized knowledge that would have taken hours to assemble manually by searching GitLab, Confluence, and vendor documentation separately.

## Non-Functional Requirements

- **Accuracy**: Specialists must not hallucinate data sources. If a source cannot be verified, the specialist says "I don't know" or "I'm not certain" rather than fabricating a citation.
- **Browser support**: The web application works correctly in Google Chrome (OLX's primary browser). Other browsers are not tested or supported in MVP.

## Non-Goals

### Functional non-goals
- **No code generation or feature implementation** — agents answer questions about data; they don't write code or implement features. Rationale: scope control; code generation is a different product.
- **No general market/competitor knowledge** — agents know OLX's internal data ecosystem (what data we have, how it's processed, where it lives). They do NOT provide external market intelligence or competitor strategy analysis. Rationale: bounded expertise; agents are data librarians, not market analysts.
- **No JIRA ticket creation** — deferred to v2. Agents only answer questions; they don't take actions in external systems. Rationale: MVP proves the knowledge synthesis; actions come later.
- **No mobile version** — web only for MVP. Rationale: internal tool used at desks; mobile adds complexity without clear value.

### Non-functional non-goals
- **No multi-language support** — English and Polish only; no internationalization effort. Rationale: internal OLX tool; these are the working languages.
- **No offline support** — requires internet connection. Rationale: agents query live systems (MCP, potentially GitLab/Confluence); offline doesn't make sense.

## Product Framing

- **Product type**: Web application
- **Target scale**: Dozens to a hundred users (team/department level)
- **Timeline**: 4-6 weeks (mixed work/personal time); no hard deadline
- **After-hours only**: No — mixed work and personal time

## Quality Cross-Check

All required elements present:
- Access Control: SSO + flat model defined
- Business Logic: one-sentence rule capturing routing + synthesis
- Timeline-cost: 4-6 weeks acknowledged
- Non-Goals: 6 entries (4 functional, 2 non-functional)

No gaps. Ready for /10x-prd.

