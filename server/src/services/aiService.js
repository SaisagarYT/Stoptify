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
export const callAiChat = async ({ systemPrompt, userPrompt, messages }) => {
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

  const chatMessages = messages && messages.length > 0
    ? messages
    : [
        { role: "system", content: systemPrompt },
        { role: "user", content: userPrompt },
      ];

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: chatMessages,
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
  ],
  "orderingChallenges": [
    {
      "id": string,
      "instruction": string,
      "scrambledItems": [string],
      "correctSequence": [string],
      "explanation": string
    }
  ]
}`;

  const userPrompt = `Topic Title: ${topicTitle}
Definition of Done:
- Conceptual: ${definitionOfDone.conceptual || "Explain core concept"}
- Practical: ${definitionOfDone.practical || "Hands-on implementation"}
- Anti-Scope: ${definitionOfDone.anti_scope || "Keep focused"}

Generate 2 MCQs, 3 progressive Feynman oral defense probes, and 1 sequence ordering challenge in strict JSON format.`;

  return await callAiChat({ systemPrompt, userPrompt });
};

// Analyzes resume text to extract skills, suggested domain categories, and gaps
export const analyzeResumeContent = async ({ resumeText }) => {
  const systemPrompt = `You are Stoptify's Senior Talent & Curriculum Architect.
Analyze the candidate's resume to identify demonstrated technical proficiencies and recommend targeted learning domains.
Output MUST be a valid JSON object matching this exact schema:
{
  "candidateSummary": string,
  "detectedSkills": [
    {
      "skillName": string,
      "proficiencyLevel": number, // integer from 1 (beginner) to 5 (master)
      "evidence": string
    }
  ],
  "suggestedDomains": [
    {
      "domainKey": string, // e.g. "sql_databases", "backend_engineering", "devops_cloud"
      "domainTitle": string, // e.g. "SQL & Database Engineering"
      "description": string,
      "matchReason": string
    }
  ],
  "identifiedGaps": [string]
}`;

  const userPrompt = `Candidate Resume Content:
${resumeText}

Analyze this resume and extract the skills and recommended domain categories in strict JSON format.`;

  return await callAiChat({ systemPrompt, userPrompt });
};

// Conducts a turn in the interactive diagnostic chat consultation
export const conductConsultationTurn = async ({
  domain,
  conversationHistory = [],
  userSkills = [],
  userMessage,
}) => {
  const systemPrompt = `You are Stoptify's Pedagogical Diagnostic Consultant.
Your core mission is to help the student eliminate "tutorial hell", uncertainty of "is it enough or not", and scope creep ("when to stop").
You are diagnosing the student's background for the domain: "${domain}".

In this diagnostic consultation, you must:
1. Probe what topics the student has ALREADY completed or mastered so we do NOT repeat them.
2. Calibrate their depth (conceptual ELI5 vs practical coding).
3. Ask if they have existing learning resources (notes, PDFs, documentation to upload for RAG) OR if they want Stoptify to generate dynamic textbooks and labs.
4. Keep replies conversational, encouraging, concise, and focused on finding their exact learning frontier.
5. If you have gathered sufficient information (completed topics, depth goal, resource preference), set "isReadyToFinalize" to true.

Output MUST be a valid JSON object matching this exact schema:
{
  "assistantReply": string,
  "isReadyToFinalize": boolean,
  "completedTopicsIdentified": [string],
  "resourcePreference": string, // "ai_generated" or "user_upload" or "hybrid"
  "targetDepth": string // e.g. "practical_production", "interview_prep", "foundational"
}`;

  const formattedMessages = [
    { role: "system", content: systemPrompt },
    ...conversationHistory.map((msg) => ({
      role: msg.sender === "assistant" ? "assistant" : "user",
      content: typeof msg.content === "string" ? msg.content : JSON.stringify(msg.content),
    })),
    {
      role: "user",
      content: `Known user skills: ${JSON.stringify(userSkills)}\nUser response: ${userMessage}`,
    },
  ];

  return await callAiChat({ messages: formattedMessages });
};

// Synthesizes a calibrated custom roadmap with explicit 3-Tier Definition of Done and Anti-Scope boundaries
export const synthesizeCalibratedRoadmap = async ({
  domain,
  consultationSummary = {},
  userSkills = [],
}) => {
  const systemPrompt = `You are Stoptify's Senior Curriculum Architect.
Synthesize a personalized, mastery-based learning roadmap tailored to the student's diagnostic consultation.
Every topic MUST solve the 3 core pedagogical problems:
1. "Which topic to learn next?" -> Strictly ordered sequence of 4-6 topics starting where their knowledge leaves off.
2. "Is it enough or not?" -> Explicit 3-Tier Definition of Done (Conceptual ELI5 + Practical hands-on task).
3. "When should I stop?" -> Explicit Anti-Scope boundaries (what NOT to study right now) to prevent rabbit holes and scope creep.

Output MUST be a valid JSON object matching this exact schema:
{
  "title": string,
  "slug": string, // url-safe lowercase kebab-case e.g. "sql-production-mastery"
  "targetCareer": string,
  "durationWeeks": number,
  "difficultyLevel": string, // "Beginner", "Intermediate", or "Advanced"
  "topics": [
    {
      "title": string,
      "slug": string,
      "description": string,
      "orderIndex": number, // starting from 1
      "estimatedDurationMin": string, // e.g. "45 min"
      "subtopics": [string], // array of 3-4 specific concepts covered
      "realWorldExample": {
        "company": string, // e.g. "Uber", "Netflix", "Stripe"
        "scenario": string, // concrete real-world engineering challenge
        "takeaway": string // how mastering this topic solved the problem
      },
      "definitionOfDone": {
        "conceptual": string, // plain English ELI5 explanation required to pass
        "practical": string, // concrete exercise, query, or build task
        "anti_scope": string // exact boundary of what to ignore/stop studying
      },
      "antiScopeList": [string], // array of 2-3 specific topics/tools to NOT touch yet
      "whenToStopCriteria": string // concise instruction telling the student when they are officially done
    }
  ]
}`;

  const userPrompt = `Target Domain: ${domain}
Consultation Summary: ${JSON.stringify(consultationSummary)}
User Existing Skills: ${JSON.stringify(userSkills)}

Synthesize the complete calibrated roadmap in strict JSON format.`;

  return await callAiChat({ systemPrompt, userPrompt });
};

