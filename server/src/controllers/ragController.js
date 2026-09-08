import { sendSuccess, sendError } from "../utils/response.js";
import { supabase, isDatabaseConnected } from "../config/db.js";
import {
  createUpload,
  getUserUploads,
  searchChunks,
  getGeneratedContentByTopic,
} from "../db/inMemoryStore.js";

// Uploads a document and chunks it into semantic segments
export const uploadDocument = async (req, res) => {
  try {
    const { fileName, fileType = "notes", content } = req.body;

    const result = createUpload({
      userId: req.user.id,
      fileName,
      fileType,
      content,
    });

    if (isDatabaseConnected && supabase) {
      try {
        const { data: uploadData } = await supabase
          .from("user_uploads")
          .insert([
            {
              id: result.upload.id,
              user_id: req.user.id,
              file_name: fileName,
              file_url: result.upload.file_url,
              file_type: fileType,
              file_size_bytes: result.upload.file_size_bytes,
              mime_type: result.upload.mime_type,
              storage_path: result.upload.storage_path,
            },
          ])
          .select()
          .single();

        if (uploadData && result.chunks.length > 0) {
          const chunkInserts = result.chunks.map((c) => ({
            id: c.id,
            upload_id: result.upload.id,
            content: c.content,
            chunk_index: c.chunk_index,
            source_page: c.source_page,
          }));

          await supabase.from("document_chunks").insert(chunkInserts);
        }
      } catch (dbErr) {
        // Fallback to in-memory store
      }
    }

    return sendSuccess(
      res,
      {
        upload: result.upload,
        chunksCount: result.chunks.length,
        chunks: result.chunks,
      },
      "Document uploaded and chunked successfully.",
      201
    );
  } catch (error) {
    return sendError(res, "Document upload failed.", 500, error.message);
  }
};

// Lists all documents uploaded by the authenticated user
export const getUploads = async (req, res) => {
  try {
    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("user_uploads")
        .select("*")
        .eq("user_id", req.user.id);

      if (!error && data && data.length > 0) {
        return sendSuccess(res, data, "User uploads retrieved.");
      }
    }

    const uploads = getUserUploads(req.user.id);
    return sendSuccess(res, uploads, "User uploads retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve uploads.", 500, error.message);
  }
};

// Searches document chunks for relevant context to ground AI prompts
export const searchRag = async (req, res) => {
  try {
    const { query, limit = 5 } = req.body;

    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("document_chunks")
        .select("*")
        .ilike("content", `%${query}%`)
        .limit(limit);

      if (!error && data && data.length > 0) {
        return sendSuccess(
          res,
          {
            query,
            matchCount: data.length,
            chunks: data,
          },
          "Semantic context retrieved."
        );
      }
    }

    const matches = searchChunks(query, limit);
    return sendSuccess(
      res,
      {
        query,
        matchCount: matches.length,
        chunks: matches,
      },
      "Semantic context retrieved."
    );
  } catch (error) {
    return sendError(res, "RAG search failed.", 500, error.message);
  }
};

// Retrieves AI-generated textbook or diagram content for a topic
export const getTopicContent = async (req, res) => {
  try {
    const { topicId } = req.params;

    if (isDatabaseConnected && supabase) {
      const { data, error } = await supabase
        .from("generated_content")
        .select("*")
        .eq("topic_id", topicId);

      if (!error && data && data.length > 0) {
        const parsedData = data.map((item) => {
          try {
            return { ...item, body: JSON.parse(item.body) };
          } catch {
            return item;
          }
        });
        return sendSuccess(res, parsedData, "Topic content retrieved.");
      }
    }

    const contents = getGeneratedContentByTopic(topicId);
    return sendSuccess(res, contents, "Topic content retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve topic content.", 500, error.message);
  }
};

// Dynamically generates a structured learning chapter using AI
export const generateTopicChapterEndpoint = async (req, res) => {
  try {
    const { topicId } = req.params;

    let topic = null;
    if (isDatabaseConnected && supabase) {
      const { data } = await supabase
        .from("topics")
        .select("*")
        .eq("id", topicId)
        .maybeSingle();
      topic = data;
    }

    if (!topic) {
      return sendError(res, "Topic not found.", 404);
    }

    let ragContext = "";
    if (isDatabaseConnected && supabase) {
      const { data: chunks } = await supabase
        .from("document_chunks")
        .select("content")
        .ilike("content", `%${topic.title.split(" ")[0]}%`)
        .limit(3);

      if (chunks && chunks.length > 0) {
        ragContext = chunks.map((c) => c.content).join("\n\n");
      }
    }

    const { generateChapterContent } = await import("../services/aiService.js");
    const chapterJson = await generateChapterContent({
      topicTitle: topic.title,
      description: topic.description,
      definitionOfDone: topic.definition_of_done,
      ragContext,
    });

    if (isDatabaseConnected && supabase) {
      await supabase.from("generated_content").insert([
        {
          topic_id: topic.id,
          content_type: "textbook_chapter",
          body: JSON.stringify(chapterJson),
          version: "v1.0",
          metadata: { estimatedMinutes: chapterJson.estimatedMinutes },
          generated_by_ai_model: config.aiProvider || "qwen",
        },
      ]);
    }

    return sendSuccess(
      res,
      chapterJson,
      "AI dynamic content generated and parsed successfully.",
      201
    );
  } catch (error) {
    return sendError(res, "Failed to generate dynamic AI content.", 500, error.message);
  }
};
