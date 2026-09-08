import { sendSuccess, sendError } from "../utils/response.js";
import {
  createUpload,
  getUserUploads,
  searchChunks,
  getGeneratedContentByTopic,
} from "../db/inMemoryStore.js";

// Uploads a document and chunks it into semantic segments
export const uploadDocument = (req, res) => {
  try {
    const { fileName, fileType = "notes", content } = req.body;

    const result = createUpload({
      userId: req.user.id,
      fileName,
      fileType,
      content,
    });

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
export const getUploads = (req, res) => {
  try {
    const uploads = getUserUploads(req.user.id);
    return sendSuccess(res, uploads, "User uploads retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve uploads.", 500, error.message);
  }
};

// Searches document chunks for relevant context to ground AI prompts
export const searchRag = (req, res) => {
  try {
    const { query, limit = 5 } = req.body;
    const matches = searchChunks(query, limit);

    return sendSuccess(res, {
      query,
      matchCount: matches.length,
      chunks: matches,
    }, "Semantic context retrieved.");
  } catch (error) {
    return sendError(res, "RAG search failed.", 500, error.message);
  }
};

// Retrieves AI-generated textbook or diagram content for a topic
export const getTopicContent = (req, res) => {
  try {
    const { topicId } = req.params;
    const contents = getGeneratedContentByTopic(topicId);

    return sendSuccess(res, contents, "Topic content retrieved.");
  } catch (error) {
    return sendError(res, "Failed to retrieve topic content.", 500, error.message);
  }
};
