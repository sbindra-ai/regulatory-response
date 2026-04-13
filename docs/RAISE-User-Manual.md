# Regulatory AI for Structured Execution (RAISE)

**User manual — end users and maintainers**

Version note: aligned with the current application (product name RAISE; dual evidence pools; network share indexing).

---

## 1. What RAISE does

RAISE helps SPA and biostatistics teams respond to regulatory questions (for example FDA Information Requests) by:

1. **Interpreting** the question (request type, datasets, endpoints, outputs).
2. **Retrieving** ranked evidence from a **knowledge index** (demo repository and/or a **network share** you index).
3. **Producing** a **traceable internal response plan** (approach, deliverables, candidate data paths, strongest matching SAS programs/macros, assumptions, gaps, warnings).

It does **not** replace human review or final authority-facing wording. Treat outputs as **draft planning aids** grounded in cited evidence where retrieval succeeded.

---

## 2. Quick start (local)

| Step | Action |
|------|--------|
| 1 | Clone the repository and open a terminal in the project root. |
| 2 | **Option A:** Run `start-dev.bat` (Windows). It switches to the repo folder, finds Node (system `PATH` or portable `.\node\node-v*-win-x64\`), runs `npm install` only if needed, then `npm run dev`. **Option B:** Run `npm install` then `npm run dev`. |
| 3 | Open **http://localhost:3000**. |
| 4 | Expand **Settings**, paste your **MGA** bearer token (stored in the browser for the session). Without it, the app uses fallbacks; full LLM interpretation/plan quality and embeddings need a valid token. |

**Repository index:** after changing README, Define-XML, PDFs under **`docs/examples/documents/`**, or SAS under **`docs/examples/programs/`** and **`docs/examples/macros/`**, run `npm run ingest` (or **Rebuild repo index** in the UI when available).

---

## 3. End-user workflow

### 3.1 Enter the question

Paste the regulatory question (or use a demo prompt). Avoid restricted identifiers unless your environment is approved for them.

### 3.2 Choose how evidence is retrieved

In the **Knowledge retrieval** area:

| Control | Purpose |
|---------|---------|
| **Evidence source** | **Repository** — bundled demo corpus (`data/copilot/evidence-corpus.json`). **Network share** — your built index (`data/copilot/evidence-corpus.network.json` from a UNC/mapped folder). |
| **Ranking mode** | **Hybrid** — keywords + vectors (when embeddings exist). **Vector-first** — semantic similarity first; often better on large, heterogeneous shares. |

**Important:** Interpretation still uses the **repository** program catalog for consistent “families” and hints; only **retrieval** switches to the network pool when you select **Network share**.

### 3.3 Run the copilot

Click **Run Copilot**. Wait for the run to finish.

### 3.4 Review the results (tabs)

| Tab | Content |
|-----|---------|
| **Interpretation** | Structured summary of the ask (population, endpoint, datasets, confidence, etc.). |
| **Evidence** | Ranked hits with scores, match reasons, paths, and source excerpts. An **Active index** line shows which pool and ranking mode were used. |
| **Response plan** | Recommended approach, deliverables, responsibilities, candidate datasets/paths, **Evidence base** summary, and **Most likely programs / macros** (type, relevance, program/macro name, **full path** where available, expandable **Code**). |

**Paths:** Full UNC/absolute paths depend on correct indexing: the network corpus stores **`networkScanRoot`** (the folder actually scanned). If you still see only `pgms/...`, rebuild the network index from the real folder or set **`EVIDENCE_SCAN_ROOT`** to that same folder. The app does **not** invent a corporate share path.

### 3.5 Export

Use **Export PDF** (or other export controls shown in your build) when you need a shareable artifact. Keep internal disclaimers in mind.

---

## 4. Network share indexing (maintainers)

### 4.1 What gets indexed

From the scan root, the indexer walks the tree and picks up **`.sas`, `.txt`, `.pdf`, `.sas7bdat`, `.xpt`** (other extensions are skipped). A **Samba-style layout** works well: **`documents/`** (PDFs, Define-XML, specs), **`macros/`** (macro `.sas`), **`programs/`** (TLF and listing `.sas`) — the same structure as **`docs/examples`** in the bundled repo. Large files and noisy directories (e.g. `node_modules`, `.git`) are skipped.

### 4.2 Build or refresh the network JSON

- **CLI:** `npm run ingest:network`  
  Optional: pass the scan root as the first argument, or set **`EVIDENCE_SCAN_ROOT`** in `.env`.
- **UI:** **Rebuild network index** (uses the **Network scan root** field and server env; server must reach the path).

Output default: **`data/copilot/evidence-corpus.network.json`**.

### 4.3 Embeddings

Set **`MGA_TOKEN`** for the **ingest** process when you want vector embeddings in the network corpus. Without it, the index is keyword-oriented (ranking may behave like keyword-only).

### 4.4 `networkScanRoot`

New ingests write **`networkScanRoot`** into the JSON — the **exact directory** scanned. That value is used at retrieval time to resolve relative paths to full UNC paths. See **`docs/NETWORK_SHARE_AND_RETRIEVAL.md`** for environment variables, APIs, and technical detail.

---

## 5. Environment variables (reference)

| Variable | Role |
|----------|------|
| `MGA_TOKEN` | Bayer myGenAssist access (runtime LLM + optional embeddings at ingest). |
| `EVIDENCE_SCAN_ROOT` | Default folder for `ingest:network` / rebuild when no override is passed. Should match the folder you actually indexed for path display. |
| `EVIDENCE_NETWORK_OUTPUT` | Optional path for the network corpus JSON output. |
| `EVIDENCE_NETWORK_CORPUS_PATH` | Optional path the **server** reads for the network corpus at runtime. |
| `COPILOT_EVIDENCE_LIMIT` | Optional. Cap retrieval hits (e.g. `20` for faster demos); skips SAS backfill beyond that cap. |
| `COPILOT_PLAN_EVIDENCE_CAP` | Optional. Max evidence rows sent to the **plan** LLM (default **24**). Full hits still drive the merged plan table. |

---

## 6. Best practices

- **Validate interpretation** before relying on the plan; refine the question and re-run if fields are wrong or vague.
- **Prefer specific questions** (endpoint names, timepoints, dataset acronyms) for better retrieval.
- **Treat uncited or weak-evidence areas** as hypotheses; use **warnings**, **assumptions**, and **evidence gaps** in the plan.
- **Use anonymized** materials in demos; follow your org’s rules for tokens and share paths.

### Demos and runtime speed

- Prefer **Repository** for live demos: smaller index, fewer retrieved rows, and more predictable timing than a large **Network share** index.
- Use **Hybrid** ranking unless you specifically need **Vector-first** on a big share.
- **Warm up** once before the audience: run Copilot on your demo question so the server and API paths are hot.
- Optional **server** tuning (`.env` on the machine running `npm run dev`): set `COPILOT_EVIDENCE_LIMIT=20` and keep the default plan cap (24) for shorter plan prompts and faster MGA responses.

---

## 7. Troubleshooting

| Symptom | What to check |
|---------|----------------|
| AI steps fail | MGA token valid? Network from browser to API allowed? |
| No or poor evidence | Wrong **Evidence source**? Re-run **ingest** / **Rebuild**? For network, is the JSON present and non-placeholder? |
| Paths look wrong under `pgms\` | Rebuild network index from the **real** study folder so **`networkScanRoot`** is correct, or set **`EVIDENCE_SCAN_ROOT`** to that folder. |
| `npm` / Node errors | Node 20+; run from repo root; try `start-dev.bat install` to force `npm install`. |
| Stale index after file changes | **Rebuild repo index** or **Rebuild network index**; restart dev server if needed. |

Corpus locations: **`data/copilot/evidence-corpus.json`** (repository), **`data/copilot/evidence-corpus.network.json`** (network).

---

## 8. Maintainer tasks (short)

| Task | Command / location |
|------|---------------------|
| Rebuild demo corpus | `npm run ingest` |
| Rebuild network corpus | `npm run ingest:network` or UI **Rebuild network index** |
| Tests | `npm run test` |
| Prompt / copilot logic | `lib/server/copilot/` (e.g. `prompts.ts`, `retrieve-evidence.ts`, `generate-plan.ts`) |
| UI | `components/copilot/`, `app/page.tsx` |

Deep technical notes, flow diagrams, and change history: **`docs/NETWORK_SHARE_AND_RETRIEVAL.md`**.

---

## 9. Glossary

| Term | Meaning |
|------|---------|
| **RAISE** | Regulatory AI for Structured Execution — product name for this tool. |
| **Corpus / index** | Searchable evidence built from repo files and/or a network folder. |
| **Repository pool** | In-repo demo evidence (`evidence-corpus.json`). |
| **Network pool** | Evidence from your share (`evidence-corpus.network.json`). |
| **RAG** | Retrieval-augmented generation: retrieve passages, then generate text grounded on them. |
| **MGA** | myGenAssist — internal AI API; access via bearer token. |
| **networkScanRoot** | Directory recorded at network ingest; used to build correct full paths for files. |

---

## 10. Converting this file to Word

1. Open **`docs/RAISE-User-Manual.md`** in **Visual Studio Code**, **Typora**, or **Word** (File → Open).  
2. In Word: review headings, then **File → Save As → Word Document (.docx)**.  
3. Optionally replace older manuals (e.g. “AI-Powered Regulatory Response Accelerator”) with this document for consistency with **RAISE**.

---

*For hackathon or pilot demos, keep this manual next to the repo README; both describe scope, setup, and governance at a high level.*
