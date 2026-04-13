import { z } from "zod"

export const requestTypeSchema = z.string().min(1).catch("unknown")

export const confidenceSchema = z.enum(["low", "medium", "high"])

export const confidenceScoreSchema = z.object({
  overall: z.number().min(0).max(100),
  level: confidenceSchema,
  interpretationScore: z.number().min(0).max(100),
  evidenceRelevanceScore: z.number().min(0).max(100),
  evidenceCoverageScore: z.number().min(0).max(100),
  reasons: z.array(z.string()),
})

export const evidenceSourceTypeSchema = z.enum([
  "brief",
  "dataset",
  "program",
  "sap-section",
  "tlf-spec",
  "adrg-section",
  "fda-request",
  "ads-spec",
  "case-data",
  "network-file",
])

export const requestInterpretationSchema = z.object({
  requestType: requestTypeSchema,
  summary: z.string().min(1),
  population: z.string().min(1),
  endpoint: z.string().min(1),
  timepoints: z.array(z.string().min(1)),
  analysisType: z.string().min(1),
  statisticalModel: z.string().nullable(),
  outputTypes: z.array(z.string().min(1)),
  datasetHints: z.array(z.string().min(1)),
  outputFamilyHints: z.array(z.string().min(1)),
  confidence: confidenceSchema,
  confidenceScore: confidenceScoreSchema,
})

export const evidenceDocumentSchema = z.object({
  id: z.string().min(1),
  title: z.string().min(1),
  sourceType: evidenceSourceTypeSchema,
  path: z.string().min(1),
  /** Path under the network ingest root (forward slashes), e.g. pgms/start.sas — for display next to full UNC. */
  relativePath: z.string().optional(),
  summary: z.string().min(1),
  keywords: z.array(z.string().min(1)),
  datasetNames: z.array(z.string().min(1)),
  outputFamilies: z.array(z.string().min(1)),
  sourceText: z.string().min(1),
  embedding: z.array(z.number()).nullable().default(null),
})

export const readmeBriefSchema = z.object({
  id: z.literal("brief:product"),
  title: z.string().min(1),
  path: z.literal("README.md"),
  summary: z.string().min(1),
  keywords: z.array(z.string().min(1)),
  sourceText: z.string().min(1),
})

export const defineDatasetVariableSchema = z.object({
  name: z.string().min(1),
  label: z.string(),
})

export const defineDatasetSchema = z.object({
  name: z.string().min(1),
  label: z.string().min(1),
  structure: z.string().min(1),
  className: z.string().nullable(),
  leaf: z.string().nullable(),
  variables: z.array(defineDatasetVariableSchema),
})

export const sasProgramSchema = z.object({
  name: z.string().min(1),
  path: z.string().min(1),
  title: z.string().min(1),
  purpose: z.string().min(1),
  datasetsUsed: z.array(z.string().min(1)),
  outputFamilies: z.array(z.string().min(1)),
  keywords: z.array(z.string().min(1)),
  sourceText: z.string().min(1),
  studyNumber: z.string().nullable().default(null),
  compound: z.string().nullable().default(null),
  statisticalMethods: z.array(z.string()).default([]),
  titlesAndFootnotes: z.array(z.string()).default([]),
  filterConditions: z.array(z.string()).default([]),
  parameters: z.array(z.string()).default([]),
  analysisVariables: z.array(z.string()).default([]),
  visitTimepoints: z.array(z.string()).default([]),
})

export const evidenceHitSchema = z.object({
  document: evidenceDocumentSchema,
  score: z.number().min(0),
  matchedTerms: z.array(z.string().min(1)),
  retrievalReason: z.string().min(1),
  vectorSimilarity: z.number().nullable(),
  keywordScore: z.number(),
  hybridRank: z.number(),
})

export const uncertaintyItemSchema = z.object({
  title: z.string().min(1),
  detail: z.string().min(1),
})

export const responsibilitySchema = z.object({
  role: z.string().min(1),
  tasks: z.array(z.string().min(1)),
})

export const candidateDatasetPathSchema = z.object({
  dataset: z.string().min(1),
  path: z.string().min(1),
})

export const rankedCodeAssetSchema = z.object({
  assetType: z.enum(["program", "macro"]),
  relevancePercent: z.number().min(0).max(100),
  title: z.string().min(1),
  path: z.string().min(1),
  relativePath: z.string().optional(),
  documentId: z.string().min(1),
  callingProgramPaths: z.array(z.string()),
})

export const responsePlanSchema = z.object({
  objective: z.string().min(1),
  recommendedApproach: z.string().min(1),
  recommendedDatasets: z.array(z.string().min(1)),
  candidateOutputs: z.array(z.string().min(1)),
  deliverables: z.array(z.string().min(1)),
  responsibilities: z.array(responsibilitySchema),
  citations: z.array(z.string().min(1)),
  candidateDatasetPaths: z.array(candidateDatasetPathSchema).default([]),
  rankedCodeAssets: z.array(rankedCodeAssetSchema).default([]),
})

export const evidencePoolSchema = z.enum(["repository", "network"])

export const retrievalMetadataSchema = z.object({
  method: z.enum(["hybrid", "keyword-only", "vector-primary"]),
  documentCount: z.number(),
  topSimilarity: z.number().nullable(),
  evidencePool: evidencePoolSchema.default("repository"),
  /** When using the network pool, the scan root used to resolve relative paths to full UNC (env or default). */
  networkScanRootUsed: z.string().optional(),
})

export const tokenUsageSchema = z.object({
  promptTokens: z.number(),
  completionTokens: z.number(),
  totalTokens: z.number(),
})

export const copilotResultSchema = z.object({
  interpretation: requestInterpretationSchema,
  evidence: z.array(evidenceHitSchema),
  responsePlan: responsePlanSchema,
  assumptions: z.array(uncertaintyItemSchema),
  openQuestions: z.array(uncertaintyItemSchema),
  evidenceGaps: z.array(uncertaintyItemSchema),
  warnings: z.array(z.string().min(1)),
  retrievalMetadata: retrievalMetadataSchema,
  tokenUsage: tokenUsageSchema,
})

export const evidenceCorpusSchema = z.object({
  generatedAt: z.string().min(1),
  embeddingModel: z.string().nullable().default(null),
  embeddingDimensions: z.number().nullable().default(null),
  brief: readmeBriefSchema,
  datasets: z.array(defineDatasetSchema),
  programs: z.array(sasProgramSchema),
  documents: z.array(evidenceDocumentSchema),
  /** Set for network corpora: the directory that was scanned at ingest (joins legacy relative `path` values correctly). */
  networkScanRoot: z.string().optional(),
})

export type RequestType = z.infer<typeof requestTypeSchema>
export type Confidence = z.infer<typeof confidenceSchema>
export type ConfidenceScore = z.infer<typeof confidenceScoreSchema>
export type RetrievalMetadata = z.infer<typeof retrievalMetadataSchema>
export type EvidencePool = z.infer<typeof evidencePoolSchema>
export type TokenUsage = z.infer<typeof tokenUsageSchema>
export type EvidenceSourceType = z.infer<typeof evidenceSourceTypeSchema>
export type RequestInterpretation = z.infer<typeof requestInterpretationSchema>
export type EvidenceDocument = z.infer<typeof evidenceDocumentSchema>
export type ReadmeBrief = z.infer<typeof readmeBriefSchema>
export type DefineDatasetVariable = z.infer<typeof defineDatasetVariableSchema>
export type DefineDataset = z.infer<typeof defineDatasetSchema>
export type SasProgram = z.infer<typeof sasProgramSchema>
export type EvidenceHit = z.infer<typeof evidenceHitSchema>
export type UncertaintyItem = z.infer<typeof uncertaintyItemSchema>
export type Responsibility = z.infer<typeof responsibilitySchema>
export type ResponsePlan = z.infer<typeof responsePlanSchema>
export type RankedCodeAsset = z.infer<typeof rankedCodeAssetSchema>
export type CandidateDatasetPath = z.infer<typeof candidateDatasetPathSchema>
export type CopilotResult = z.infer<typeof copilotResultSchema>
export type EvidenceCorpus = z.infer<typeof evidenceCorpusSchema>

// --- Follow-up chat schemas ---

export const followUpMessageSchema = z.object({
  role: z.enum(["user", "assistant"]),
  content: z.string().min(1),
})

export const followUpResultSchema = z.object({
  answer: z.string().min(1),
})

// --- Predicted questions schemas ---

export const predictedQuestionSchema = z.object({
  question: z.string().min(1),
  reasoning: z.string().min(1),
  likelihood: z.enum(["high", "medium", "low"]),
  evidenceAvailable: z.boolean(),
  suggestedAction: z.string().min(1),
})

export const predictionsResultSchema = z.object({
  predictedQuestions: z.array(predictedQuestionSchema),
})

export type FollowUpMessage = z.infer<typeof followUpMessageSchema>
export type FollowUpResult = z.infer<typeof followUpResultSchema>
export type PredictedQuestion = z.infer<typeof predictedQuestionSchema>
export type PredictionsResult = z.infer<typeof predictionsResultSchema>
