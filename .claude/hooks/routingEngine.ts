#!/usr/bin/env node
/**
 * Shared Routing Engine for Sub-Agent Auto-Routing
 * Used by both agent-auto-route.ts hook and /route-agent command
 */

import * as fs from "fs";
import * as path from "path";
import { minimatch } from "minimatch";

// ===== Type Definitions =====

export interface SpecialistTriggers {
  filePaths: string[];
  keywords: string[];
  intentPatterns: string[];
}

export interface SpecialistConfig {
  description: string;
  triggers: SpecialistTriggers;
  contextFiles: string[];
  priority: "high" | "medium" | "low";
  specificity: number;
}

export interface RoutingRules {
  version: string;
  description: string;
  specialists: Record<string, SpecialistConfig>;
  chainRules: Record<string, string[]>;
  tieBreaking: {
    specificityBonus: Record<string, number>;
    conflictResolution: [string, string][];
  };
  antiLoop: {
    maxChainDepth: number;
    sessionHistoryPath: string;
    cooldownSeconds: number;
  };
  confidenceThreshold: {
    minScore: number;
    description: string;
  };
}

export interface RoutingInput {
  filePaths?: string[];
  keywords?: string[];
  intent?: string;
  recentSpecialist?: string;
}

export interface RoutingResult {
  specialist: string;
  score: number;
  reason: string;
  contextFiles: string[];
  confidence: "high" | "medium" | "low";
}

export interface ChainHistoryEntry {
  timestamp: number;
  specialist: string;
}

export interface ChainHistory {
  sessionId: string;
  chain: ChainHistoryEntry[];
}

// ===== Configuration Loading =====

let cachedRules: RoutingRules | null = null;

export function loadRoutingRules(configPath?: string): RoutingRules {
  if (cachedRules) {
    return cachedRules;
  }

  const defaultPath = path.join(
    process.cwd(),
    ".claude",
    "agents",
    "agent-routing-rules.json"
  );
  const finalPath = configPath || defaultPath;

  if (!fs.existsSync(finalPath)) {
    throw new Error(`Routing config not found at ${finalPath}`);
  }

  const content = fs.readFileSync(finalPath, "utf-8");
  cachedRules = JSON.parse(content) as RoutingRules;
  return cachedRules;
}

// ===== Scoring Engine =====

export function scoreSpecialists(
  input: RoutingInput,
  rules: RoutingRules
): Record<string, number> {
  const scores: Record<string, number> = {};

  for (const [name, config] of Object.entries(rules.specialists)) {
    let score = 0;

    // File path matching (+20 per match)
    if (input.filePaths && input.filePaths.length > 0) {
      for (const filePath of input.filePaths) {
        for (const pattern of config.triggers.filePaths) {
          if (minimatch(filePath, pattern, { dot: true })) {
            score += 20;
            break; // Only count once per file
          }
        }
      }
    }

    // Keyword matching (+10 per keyword)
    if (input.keywords && input.keywords.length > 0) {
      for (const keyword of input.keywords) {
        const lowerKeyword = keyword.toLowerCase();
        for (const trigger of config.triggers.keywords) {
          if (lowerKeyword.includes(trigger.toLowerCase())) {
            score += 10;
            break; // Only count once per keyword
          }
        }
      }
    }

    // Intent pattern matching (+15 for matching intent)
    if (input.intent) {
      const lowerIntent = input.intent.toLowerCase();
      for (const pattern of config.triggers.intentPatterns) {
        const regex = new RegExp(pattern, "i");
        if (regex.test(lowerIntent)) {
          score += 15;
          break; // Only count once
        }
      }
    }

    // Specificity bonus (from config)
    if (rules.tieBreaking.specificityBonus[name]) {
      score += rules.tieBreaking.specificityBonus[name];
    }

    scores[name] = score;
  }

  return scores;
}

// ===== Winner Selection with Tie-Breaking =====

export function selectWinner(
  scores: Record<string, number>,
  rules: RoutingRules
): RoutingResult | null {
  // Filter out specialists below confidence threshold
  const minScore = rules.confidenceThreshold.minScore;
  const candidates = Object.entries(scores).filter(([_, score]) => score >= minScore);

  if (candidates.length === 0) {
    return null; // No specialist meets threshold
  }

  // Sort by score descending
  candidates.sort((a, b) => b[1] - a[1]);

  // Check for ties at top score
  const topScore = candidates[0][1];
  const tied = candidates.filter(([_, score]) => score === topScore);

  let winner: string;

  if (tied.length === 1) {
    winner = tied[0][0];
  } else {
    // Apply conflict resolution rules
    winner = tied[0][0]; // Default to first
    for (const [higher, lower] of rules.tieBreaking.conflictResolution) {
      const tiedNames = tied.map(([name]) => name);
      if (tiedNames.includes(higher) && tiedNames.includes(lower)) {
        winner = higher;
        break;
      }
    }
  }

  const config = rules.specialists[winner];
  const finalScore = scores[winner];

  // Determine confidence level
  let confidence: "high" | "medium" | "low" = "low";
  if (finalScore >= 30) {
    confidence = "high";
  } else if (finalScore >= 20) {
    confidence = "medium";
  }

  // Build reason string
  const reasons: string[] = [];
  if (finalScore >= 20) reasons.push("file path match");
  if (finalScore >= 10) reasons.push("keyword match");
  const reason = reasons.length > 0 ? reasons.join(", ") : "default selection";

  return {
    specialist: winner,
    score: finalScore,
    reason,
    contextFiles: config.contextFiles,
    confidence,
  };
}

// ===== Chain Management & Anti-Loop Protection =====

export function loadChainHistory(rules: RoutingRules): ChainHistory | null {
  const historyPath = rules.antiLoop.sessionHistoryPath;

  if (!fs.existsSync(historyPath)) {
    return null;
  }

  try {
    const content = fs.readFileSync(historyPath, "utf-8");
    return JSON.parse(content) as ChainHistory;
  } catch {
    return null;
  }
}

export function saveChainHistory(history: ChainHistory, rules: RoutingRules): void {
  const historyPath = rules.antiLoop.sessionHistoryPath;
  fs.writeFileSync(historyPath, JSON.stringify(history, null, 2), "utf-8");
}

export function checkChainDepth(
  specialist: string,
  rules: RoutingRules
): { allowed: boolean; reason?: string } {
  const history = loadChainHistory(rules);

  if (!history) {
    return { allowed: true };
  }

  const now = Date.now();
  const cooldownMs = rules.antiLoop.cooldownSeconds * 1000;

  // Filter recent chain (within cooldown period)
  const recentChain = history.chain.filter(
    (entry) => now - entry.timestamp < cooldownMs
  );

  // Check chain depth
  if (recentChain.length >= rules.antiLoop.maxChainDepth) {
    return {
      allowed: false,
      reason: `Max chain depth (${rules.antiLoop.maxChainDepth}) exceeded`,
    };
  }

  // Check for immediate loops (same specialist twice in a row)
  if (recentChain.length > 0) {
    const lastSpecialist = recentChain[recentChain.length - 1].specialist;
    if (lastSpecialist === specialist) {
      return {
        allowed: false,
        reason: `Loop detected (${specialist} → ${specialist})`,
      };
    }
  }

  return { allowed: true };
}

export function updateChainHistory(specialist: string, rules: RoutingRules): void {
  let history = loadChainHistory(rules);

  if (!history) {
    history = {
      sessionId: Date.now().toString(),
      chain: [],
    };
  }

  const now = Date.now();
  const cooldownMs = rules.antiLoop.cooldownSeconds * 1000;

  // Prune old entries outside cooldown
  history.chain = history.chain.filter(
    (entry) => now - entry.timestamp < cooldownMs
  );

  // Add new entry
  history.chain.push({
    timestamp: now,
    specialist,
  });

  saveChainHistory(history, rules);
}

// ===== Chain Suggestions =====

export function suggestNextSpecialist(
  currentSpecialist: string,
  rules: RoutingRules
): string | null {
  const chainRules = rules.chainRules[currentSpecialist];
  if (!chainRules || chainRules.length === 0) {
    return null;
  }

  // Return first chained specialist (could be randomized or scored)
  return chainRules[0];
}

// ===== Main Routing Function =====

export function routeToSpecialist(
  input: RoutingInput,
  configPath?: string
): RoutingResult | null {
  const rules = loadRoutingRules(configPath);
  const scores = scoreSpecialists(input, rules);
  const result = selectWinner(scores, rules);

  if (!result) {
    return null;
  }

  // Check anti-loop protection
  const chainCheck = checkChainDepth(result.specialist, rules);
  if (!chainCheck.allowed) {
    console.error(`[Routing blocked] ${chainCheck.reason}`);
    return null;
  }

  return result;
}
