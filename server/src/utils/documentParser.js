import { createRequire } from "node:module";
import path from "node:path";
import mammoth from "mammoth";
import WordExtractor from "word-extractor";

const require = createRequire(import.meta.url);
const { PDFParse } = require("pdf-parse");

/**
 * Extracts raw textual content from uploaded file buffers (PDF, DOCX, DOC, TXT).
 *
 * @param {Object} file - Express multer file object
 * @returns {Promise<string>} Extracted plain text
 */
export async function parseDocumentBuffer(file) {
  if (!file || !file.buffer) {
    throw new Error("No document buffer provided.");
  }

  const ext = (
    path.extname(file.originalname || "").toLowerCase()
  ).replace(".", "");

  const mime = file.mimetype || "";

  // 1. DOCX (Modern Word Document)
  if (
    ext === "docx" ||
    mime === "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  ) {
    const result = await mammoth.extractRawText({ buffer: file.buffer });
    return (result.value || "").trim();
  }

  // 2. DOC (Legacy Word 97-2004 Document)
  if (ext === "doc" || mime === "application/msword") {
    const extractor = new WordExtractor();
    const extracted = await extractor.extract(file.buffer);
    return (extracted.getBody() || "").trim();
  }

  // 3. PDF Document
  if (ext === "pdf" || mime === "application/pdf") {
    const parser = new PDFParse({ data: file.buffer });
    const result = await parser.getText();
    const text = typeof result === "string" ? result : result.text || "";
    return text.trim();
  }

  // 4. Plain Text or Markdown
  if (
    ext === "txt" ||
    ext === "text" ||
    ext === "md" ||
    mime.startsWith("text/")
  ) {
    return file.buffer.toString("utf-8").trim();
  }

  // Fallback: try mammoth first, then pdf-parse, then utf-8 text
  try {
    const docxResult = await mammoth.extractRawText({ buffer: file.buffer });
    if (docxResult.value && docxResult.value.trim().length > 10) {
      return docxResult.value.trim();
    }
  } catch (_) {
    // Not a docx
  }

  try {
    const parser = new PDFParse({ data: file.buffer });
    const pdfResult = await parser.getText();
    const text = typeof pdfResult === "string" ? pdfResult : pdfResult.text || "";
    if (text.trim().length > 10) {
      return text.trim();
    }
  } catch (_) {
    // Not a pdf
  }

  return file.buffer.toString("utf-8").trim();
}
