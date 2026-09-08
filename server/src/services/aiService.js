import { config } from "../config/env.js";

// Cleans AI text output and parses it into a valid JSON object
const parseAiJsonResponse = (rawText) => {
  let cleaned = rawText.trim();

  // Strip markdown code block fences if present
  if (cleaned.startsWith("```json")) {
    cleaned = cleaned.slice(7);
  } else if (cleaned.startsWith("```")) {
    cleaned = cleaned.slice(3);
  }

  if (cleaned.endsWith("```")) {
    cleaned = cleaned.slice(0, -3);
  }

  cleaned = cleaned.trim();
  return JSON.parse(cleaned);
};

// Calls the configured LLM API (Qwen, DeepSeek, Gemini, or OpenAI)
export const callAiChat = async ({ systemPrompt, userPrompt }) => {
  const provider = config.aiProvider || "qwen";

  let endpoint = "https://dashscope-intl.aliyuncs.com/compatible-mode/v1/chat/completions";
  let apiKey = config.qwenApiKey;
  let model = "qwen-turbo";

  if (provider === "deepseek") {
    endpoint = "https://api.deepseek.com/chat/completions";
    apiKey = config.deepseekApiKey;
    model = "deepseek-chat";
  } else if (provider === "openai") {
    endpoint = "https://api.openai.com/v1/chat/completions";
    apiKey = config.openaiApiKey;
    model = "gpt-4o-mini";
  }

  if (!apiKey) {
    throw new Error(`API key for provider '${provider}' is not configured in .env`);
  }

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ],
      response_format: { type: "json_object" },
    }),
  });

  if (!response.ok) {
    const errorBody = await response.text();
    throw new Error(`AI API error (${response.status}): ${errorBody}`);
  }

  const data = await response.json();
  const content = data.choices?.[0]?.message?.content;

  if (!content) {
    throw new Error("AI provider returned empty response.");
  }

  return parseAiJsonResponse(content);
};

// Dynamically generates a structured learning chapter for a topic
export const generateChapterContent = async ({
  topicTitle,
  description = "",
  definitionOfDone = {},
  ragContext = "",
}) => {
  const systemPrompt = `You are Stoptify's Expert Curriculum Architect.
Generate a structured, mastery-based learning chapter.
Output MUST be a valid JSON object matching this exact schema:
{
  "title": string,
  "estimatedMinutes": number,
  "summary": string,
  "conceptualGuide": [
    { "heading": string, "explanation": string, "mentalModel": string }
  ],
  "practicalLab": {
    "task": string,
    "starterCode": string,
    "solutionCode": string,
    "verificationSteps": [string]
  },
  "antiScopeWarnings": [string],
  "mermaidDiagram": string
}`;

  const userPrompt = `Topic Title: ${topicTitle}
Description: ${description}
Definition of Done:
- Conceptual Goal: ${definitionOfDone.conceptual || "Clear explanation in plain English"}
- Practical Goal: ${definitionOfDone.practical || "Build a working example"}
- Anti-Scope (What to avoid): ${definitionOfDone.anti_scope || "Do not study advanced internals yet"}
${ragContext ? `Reference Context (RAG):\n${ragContext}` : ""}

Generate the complete learning chapter in strict JSON format.`;

  return await callAiChat({ systemPrompt, userPrompt });
};

// Dynamically generates MCQs and Feynman oral defense probes for a topic
export const generateAssessmentQuestions = async ({
  topicTitle,
  definitionOfDone = {},
}) => {
  const systemPrompt = `You are Stoptify's Lead AI Examiner.
Generate an assessment covering conceptual clarity, trade-offs, and practical application.
Output MUST be a valid JSON object matching this exact schema:
{
  "mcqs": [
    {
      "id": string,
      "prompt": string,
      "options": [string, string, string, string],
      "correct_index": number,
      "explanation": string
    }
  ],
  "oralProbes": [
    {
      "tier": "eli5_core",
      "question": string,
      "duration_seconds": 30,
      "pass_criteria": string
    },
    {
      "tier": "tradeoff_edge_case",
      "question": string,
      "duration_seconds": 45,
      "pass_criteria": string
    },
    {
      "tier": "real_world_application",
      "question": string,
      "duration_seconds": 45,
      "pass_criteria": string
    }
  ]
}`;

  const userPrompt = `Topic Title: ${topicTitle}
Definition of Done:
- Conceptual: ${definitionOfDone.conceptual || "Explain core concept"}
- Practical: ${definitionOfDone.practical || "Hands-on implementation"}
- Anti-Scope: ${definitionOfDone.anti_scope || "Keep focused"}

Generate 2 MCQs and 3 progressive Feynman oral defense probes in strict JSON format.`;

  return await callAiChat({ systemPrompt, userPrompt });
};

