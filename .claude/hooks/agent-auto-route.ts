#!/usr/bin/env node
/**
 * Agent Auto-Route Hook
 * Silently routes to specialist sub-agents after file edits and task completions
 *
 * Triggers:
 * - AfterToolUse (Edit/Write): Routes based on edited file path
 * - AfterTaskCompletion: Chains to next specialist if defined
 */

import * as fs from "fs";
import * as path from "path";
import {
  loadRoutingRules,
  routeToSpecialist,
  checkChainDepth,
  updateChainHistory,
  suggestNextSpecialist,
  type RoutingInput,
  type RoutingResult,
} from "./routingEngine.js";

// ===== Type Definitions =====

interface HookInput {
  session_id?: string;
  transcript_path?: string;
  cwd?: string;
  permission_mode?: string;

  // AfterToolUse fields
  toolUse?: {
    name: string;
    path?: string;
  };

  // AfterTaskCompletion fields
  taskOutput?: {
    specialist?: string;
    status?: string;
  };
}

// ===== Configuration =====

const SILENT_MODE = true; // No output except specialist name
const TOOL_TRIGGERS = ["Edit", "Write", "MultiEdit"]; // Tools that trigger routing
const MIN_CONFIDENCE = "medium"; // Only route if confidence is medium or high

// ===== Helper Functions =====

function extractFilePath(input: HookInput): string | null {
  if (!input.toolUse) {
    return null;
  }

  // Check if tool is in trigger list
  if (!TOOL_TRIGGERS.includes(input.toolUse.name)) {
    return null;
  }

  return input.toolUse.path || null;
}

function extractKeywords(filePath: string): string[] {
  const keywords: string[] = [];

  // Extract from file path
  const pathParts = filePath.toLowerCase().split(/[\/\\]/);
  keywords.push(...pathParts);

  // Extract from filename
  const filename = path.basename(filePath, path.extname(filePath));
  const filenameParts = filename.split(/[-_]/);
  keywords.push(...filenameParts);

  return keywords.filter(k => k.length > 2); // Filter short tokens
}

function shouldRoute(result: RoutingResult | null): boolean {
  if (!result) {
    return false;
  }

  // Only route if confidence is medium or high
  if (MIN_CONFIDENCE === "medium" && result.confidence === "low") {
    return false;
  }

  if (MIN_CONFIDENCE === "high" && result.confidence !== "high") {
    return false;
  }

  return true;
}

function invokeTaskTool(
  specialist: string,
  contextFiles: string[],
  reason: string
): void {
  // SILENT MODE: Write to log file instead of console to avoid infinite loops
  const logDir = path.join(process.env.CLAUDE_PROJECT_DIR || process.cwd(), '.spec-flow', 'cache');
  const logFile = path.join(logDir, 'agent-routing.log');

  const logEntry = `[${new Date().toISOString()}] Route: ${specialist} (${reason})\n`;

  try {
    if (!fs.existsSync(logDir)) {
      fs.mkdirSync(logDir, { recursive: true });
    }
    fs.appendFileSync(logFile, logEntry);
  } catch (err) {
    // Silently fail - don't break the workflow
  }

  // NO CONSOLE OUTPUT - prevents infinite loops
}

// ===== Main Hook Logic =====

async function main() {
  try {
    // Read hook input from stdin
    const stdinBuffer = fs.readFileSync(0, "utf-8");
    const input: HookInput = JSON.parse(stdinBuffer);

    const rules = loadRoutingRules();

    // Handle AfterToolUse (file edits)
    if (input.toolUse) {
      const filePath = extractFilePath(input);

      if (!filePath) {
        // Not a relevant tool or no path
        process.exit(0);
      }

      const keywords = extractKeywords(filePath);

      const routingInput: RoutingInput = {
        filePaths: [filePath],
        keywords,
      };

      const result = routeToSpecialist(routingInput);

      if (shouldRoute(result)) {
        const chainCheck = checkChainDepth(result.specialist, rules);

        if (!chainCheck.allowed) {
          // SILENT MODE: No console output
          process.exit(0);
        }

        invokeTaskTool(result.specialist, result.contextFiles, result.reason);
        updateChainHistory(result.specialist, rules);
      }

      process.exit(0);
    }

    // Handle AfterTaskCompletion (chain to next specialist)
    if (input.taskOutput && input.taskOutput.specialist) {
      const currentSpecialist = input.taskOutput.specialist;
      const nextSpecialist = suggestNextSpecialist(currentSpecialist, rules);

      if (!nextSpecialist) {
        // No chain rule defined
        process.exit(0);
      }

      const chainCheck = checkChainDepth(nextSpecialist, rules);

      if (!chainCheck.allowed) {
        // SILENT MODE: No console output
        process.exit(0);
      }

      const config = rules.specialists[nextSpecialist];
      invokeTaskTool(
        nextSpecialist,
        config.contextFiles,
        `chained from ${currentSpecialist}`
      );
      updateChainHistory(nextSpecialist, rules);

      process.exit(0);
    }

    // No relevant trigger
    process.exit(0);

  } catch (error) {
    // SILENT MODE: No error output to avoid infinite loops
    process.exit(0);
  }
}

main();
