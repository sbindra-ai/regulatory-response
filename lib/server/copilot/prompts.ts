import type { EvidenceHit, FollowUpMessage, RequestInterpretation, ResponsePlan } from "@/lib/server/copilot/schemas"
import { getKnowledgeBase } from "@/lib/server/copilot/knowledge-base"

function buildKnowledgeBaseCatalog(): string {
  const { corpus } = getKnowledgeBase()
  const families = new Map<string, { datasets: Set<string>; titles: string[]; count: number }>()
  const sourceTypeCounts = new Map<string, number>()

  for (const doc of corpus.documents) {
    sourceTypeCounts.set(doc.sourceType, (sourceTypeCounts.get(doc.sourceType) ?? 0) + 1)

    if (doc.sourceType !== "program") continue
    for (const family of doc.outputFamilies) {
      if (!families.has(family)) families.set(family, { datasets: new Set(), titles: [], count: 0 })
      const entry = families.get(family)!
      entry.count++
      doc.datasetNames.forEach((d) => entry.datasets.add(d))
      if (entry.titles.length < 3) entry.titles.push(doc.title)
    }
  }

  const catalogLines = [...families.entries()]
    .map(
      ([family, info]) =>
        `- ${family} (${info.count} programs): datasets ${[...info.datasets].join(", ")}. Examples: ${info.titles.join("; ")}`,
    )
    .join("\n")

  const sourceLines = [...sourceTypeCounts.entries()]
    .map(([type, count]) => `- ${type}: ${count} documents`)
    .join("\n")

  return `Analysis families in the knowledge base:\n${catalogLines}\n\nDocument sources:\n${sourceLines}`
}

export function buildInterpretationSystemPrompt(): string {
  return [
    "You interpret regulatory response requests for clinical trial SPA (Statistical and Pharmacovigilance Analysis) teams.",
    "You have access to a knowledge base of real SAS programs, datasets (CDISC ADaM standard), and regulatory documents (SAP, TLF specifications, ADRG, FDA information requests).",
    "",
    "Domain context:",
    "- CDISC ADaM datasets: ADSL (subject-level), ADAE (adverse events), ADLB (laboratory), ADCM (concomitant meds), ADMH (medical history), ADMK (markers/BMD), ADQS (questionnaires), ADTTE (time-to-event), ADVS (vital signs), ADEG (ECG), ADEX (exposure).",
    "- Common analysis types: AE summaries, SOC/PT breakdowns, AESI, EAIR, Kaplan-Meier survival, laboratory shift tables, subgroup analyses, questionnaire summaries, bone mineral density figures, liver safety/CLO packages.",
    "- The knowledge base contains real programs - derive your understanding from these, do not assume standard templates.",
    "",
    "Return JSON only.",
    "The requestType should be a short descriptive slug derived from what you see in the evidence (e.g., 'ae-summary', 'km-survival', 'lab-shift', 'questionnaire-summary', 'fracture-incidence'). Do NOT limit yourself to a fixed set of types.",
    "Prefer grounded dataset and output-family hints over free-form prose.",
    "If the request is weakly specified, lower confidence and avoid guessing.",
    'The "confidence" field MUST be exactly one of: "low", "medium", "high".',
  ].join("\n")
}

export function buildInterpretationUserPrompt(question: string, fallback: RequestInterpretation): string {
  const catalog = buildKnowledgeBaseCatalog()

  return [
    `Question: ${question}`,
    "",
    catalog,
    "",
    "Fallback interpretation to improve if justified:",
    JSON.stringify(fallback, null, 2),
    "",
    "Return the same JSON shape. Derive requestType, datasetHints, and outputFamilyHints from the knowledge base catalog above. Do not invent analysis families that don't exist in the catalog.",
  ].join("\n")
}

export function buildPlanGenerationSystemPrompt(): string {
  return [
    "You draft internal response plans for clinical trial SPA teams.",
    "You have access to evidence from a knowledge base containing real SAS programs, CDISC ADaM dataset metadata, SAP sections, TLF specifications, ADRG sections, and FDA information requests.",
    "",
    "Ground every recommendation in the supplied evidence hits.",
    "Cite specific program IDs (e.g., 'program:t_adae_iss_overall_week12').",
    "Reference the statistical methods and datasets described in the evidence.",
    "When SAP or TLF spec sections are available in the evidence, reference them.",
    "Do not produce final authority-facing prose.",
    "If evidence is weak, keep deliverables conservative and let the caller surface uncertainty separately.",
    "Return JSON only.",
  ].join("\n")
}

export function buildPlanGenerationUserPrompt(
  question: string,
  interpretation: RequestInterpretation,
  evidence: EvidenceHit[],
): string {
  return [
    `Question: ${question}`,
    "",
    "Interpretation:",
    JSON.stringify(interpretation, null, 2),
    "",
    "Evidence hits:",
    JSON.stringify(
      evidence.map((hit) => ({
        id: hit.document.id,
        title: hit.document.title,
        sourceType: hit.document.sourceType,
        summary: hit.document.summary,
        datasetNames: hit.document.datasetNames,
        outputFamilies: hit.document.outputFamilies,
        retrievalReason: hit.retrievalReason,
      })),
      null,
      2,
    ),
    "",
    "Return JSON matching this exact shape:",
    JSON.stringify(
      {
        objective: "string - one-sentence goal of the response plan",
        recommendedApproach: "string - how to start building the response, grounded in evidence",
        recommendedDatasets: ["string - ADaM dataset names, e.g. ADAE, ADSL"],
        candidateOutputs: ["string - output titles to consider producing, derived from evidence"],
        deliverables: ["string - concrete deliverable names"],
        responsibilities: [
          {
            role: "string - team role, e.g. Statistician, SAS Programmer, Data Scientist, Data Manager, Medical Writer, Statistical Lead",
            tasks: ["string - specific tasks this role should perform for this plan"],
          },
        ],
        citations: ["string - evidence document IDs from the hits above, e.g. program:t_adae_iss_overall_week12"],
      },
      null,
      2,
    ),
  ].join("\n")
}

// --- Follow-up chat prompts ---

export function buildFollowUpSystemPrompt(): string {
  return [
    "You are a friendly, knowledgeable regulatory response planning assistant having a conversation with an SPA team member.",
    "A response plan was already generated for a regulatory question. The user is now asking follow-up questions about it.",
    "",
    "RESPONSE STYLE RULES — follow these strictly:",
    "- Be BRIEF. Aim for 3-6 sentences total. Never more than 2 short paragraphs.",
    "- Write like a knowledgeable colleague in a quick chat — concise, direct, friendly.",
    "- Use **bold** for key terms and dataset names. Use bullet points only if listing 3+ items.",
    "- NEVER dump raw field names, JSON, or technical metadata. Explain in plain English.",
    "- When mentioning datasets like ADAE, just say what they provide (e.g. '**ADAE** has the adverse event records').",
    "- Reference programs by purpose, not IDs (e.g. 'the Week 12 AE summary program').",
    "- If something is outside scope, say so in one sentence.",
    "",
    "Return JSON with a single 'answer' field containing your conversational response in markdown.",
  ].join("\n")
}

export function buildFollowUpUserPrompt(
  originalQuestion: string,
  interpretation: RequestInterpretation,
  evidence: EvidenceHit[],
  responsePlan: ResponsePlan,
  conversationHistory: FollowUpMessage[],
  newMessage: string,
): string {
  // Build a human-readable evidence summary instead of raw JSON
  const evidenceSummary = evidence.slice(0, 8).map((hit) => {
    const datasets = hit.document.datasetNames.join(", ")
    return `- "${hit.document.title}" (${hit.document.sourceType}) — uses datasets: ${datasets}`
  }).join("\n")

  const planSummary = [
    `Objective: ${responsePlan.objective}`,
    `Approach: ${responsePlan.recommendedApproach}`,
    `Datasets: ${responsePlan.recommendedDatasets.join(", ")}`,
    `Deliverables: ${responsePlan.deliverables.join(", ")}`,
    `Key citations: ${responsePlan.citations.join(", ")}`,
  ].join("\n")

  return [
    `The user originally asked: "${originalQuestion}"`,
    "",
    `The copilot interpreted this as a "${interpretation.requestType}" request targeting ${interpretation.population} at ${interpretation.timepoints.join(", ")}.`,
    "",
    "The response plan recommended:",
    planSummary,
    "",
    "The evidence used to build this plan includes:",
    evidenceSummary,
    "",
    ...(conversationHistory.length > 0
      ? [
          "Previous conversation:",
          ...conversationHistory.map((m) =>
            m.role === "user" ? `User: ${m.content}` : `You: ${m.content}`
          ),
          "",
        ]
      : []),
    `The user now asks: "${newMessage}"`,
    "",
    "Answer in 3-6 sentences max. Use **bold** for key terms. No raw data dumps.",
    'Return JSON: { "answer": "your brief markdown response" }',
  ].join("\n")
}

// --- Predicted questions prompts ---

export function buildPredictionsSystemPrompt(): string {
  return [
    "You are an expert in regulatory affairs for clinical trials, specifically FDA Information Requests (IRs) and EMA Lists of Questions (LoQs).",
    "Given a regulatory question that was just answered with a response plan, predict 3-5 follow-up questions that the health authority is likely to ask next.",
    "",
    "Base your predictions on:",
    "- Common regulatory review patterns (FDA/EMA typically follow up on safety signals, subgroup differences, sensitivity analyses)",
    "- The specific analysis type and therapeutic area",
    "- Gaps or limitations in the current response plan",
    "- Standard regulatory expectations for the type of submission",
    "",
    "For each predicted question:",
    "- Write it as the health authority would phrase it",
    "- Explain why this follow-up is likely",
    "- Assess whether the team's evidence corpus can support answering it",
    "- Suggest a concrete action the team should take to prepare",
    "",
    "Return JSON only.",
  ].join("\n")
}

export function buildPredictionsUserPrompt(
  question: string,
  interpretation: RequestInterpretation,
  evidence: EvidenceHit[],
  responsePlan: ResponsePlan,
): string {
  const evidenceSummary = evidence.slice(0, 10).map((hit) => ({
    id: hit.document.id,
    title: hit.document.title,
    sourceType: hit.document.sourceType,
    datasetNames: hit.document.datasetNames,
    outputFamilies: hit.document.outputFamilies,
  }))

  return [
    `Original regulatory question: ${question}`,
    "",
    "Interpretation:",
    JSON.stringify(interpretation, null, 2),
    "",
    "Available evidence:",
    JSON.stringify(evidenceSummary, null, 2),
    "",
    "Response plan generated:",
    JSON.stringify(responsePlan, null, 2),
    "",
    "Return JSON matching this shape:",
    JSON.stringify({
      predictedQuestions: [
        {
          question: "string - the anticipated follow-up question as the authority would phrase it",
          reasoning: "string - why this follow-up is likely given the original request",
          likelihood: "high | medium | low",
          evidenceAvailable: true,
          suggestedAction: "string - what the team should do to prepare for this question",
        },
      ],
    }, null, 2),
    "",
    "Predict 3-5 questions. Order by likelihood (highest first).",
  ].join("\n")
}
