#!/usr/bin/env node
import { readFileSync } from 'fs';
import { join } from 'path';

interface HookInput {
    session_id: string;
    transcript_path: string;
    cwd: string;
    permission_mode: string;
    prompt: string;
}

interface PromptTriggers {
    keywords?: string[];
    intentPatterns?: string[];
}

interface SkillRule {
    type: 'guardrail' | 'domain';
    enforcement: 'block' | 'suggest' | 'warn';
    priority: 'critical' | 'high' | 'medium' | 'low';
    promptTriggers?: PromptTriggers;
}

interface SkillRules {
    version: string;
    skills: Record<string, SkillRule>;
}

interface MatchedSkill {
    name: string;
    matchType: 'keyword' | 'intent';
    config: SkillRule;
}

async function main() {
    try {
        // Read input from stdin
        const input = readFileSync(0, 'utf-8');
        const data: HookInput = JSON.parse(input);
        const prompt = data.prompt.toLowerCase();

        // Load skill rules
        const projectDir = process.env.CLAUDE_PROJECT_DIR || '$HOME/project';
        const rulesPath = join(projectDir, '.claude', 'skills', 'skill-rules.json');
        const rules: SkillRules = JSON.parse(readFileSync(rulesPath, 'utf-8'));

        const matchedSkills: MatchedSkill[] = [];

        // Check each skill for matches
        for (const [skillName, config] of Object.entries(rules.skills)) {
            const triggers = config.promptTriggers;
            if (!triggers) {
                continue;
            }

            // Keyword matching
            if (triggers.keywords) {
                const keywordMatch = triggers.keywords.some(kw =>
                    prompt.includes(kw.toLowerCase())
                );
                if (keywordMatch) {
                    matchedSkills.push({ name: skillName, matchType: 'keyword', config });
                    continue;
                }
            }

            // Intent pattern matching
            if (triggers.intentPatterns) {
                const intentMatch = triggers.intentPatterns.some(pattern => {
                    const regex = new RegExp(pattern, 'i');
                    return regex.test(prompt);
                });
                if (intentMatch) {
                    matchedSkills.push({ name: skillName, matchType: 'intent', config });
                }
            }
        }

        // Generate output if matches found
        if (matchedSkills.length > 0) {
            // SILENT MODE: Write to log file instead of console to avoid infinite loops
            const logDir = join(process.env.CLAUDE_PROJECT_DIR || process.cwd(), '.spec-flow', 'cache');
            const logFile = join(logDir, 'skill-activation.log');

            let output = `[${new Date().toISOString()}] SKILL ACTIVATION CHECK\n`;

            // Group by priority
            const critical = matchedSkills.filter(s => s.config.priority === 'critical');
            const high = matchedSkills.filter(s => s.config.priority === 'high');
            const medium = matchedSkills.filter(s => s.config.priority === 'medium');
            const low = matchedSkills.filter(s => s.config.priority === 'low');

            if (critical.length > 0) {
                output += 'CRITICAL SKILLS: ';
                output += critical.map(s => s.name).join(', ') + '\n';
            }

            if (high.length > 0) {
                output += 'RECOMMENDED SKILLS: ';
                output += high.map(s => s.name).join(', ') + '\n';
            }

            if (medium.length > 0) {
                output += 'SUGGESTED SKILLS: ';
                output += medium.map(s => s.name).join(', ') + '\n';
            }

            if (low.length > 0) {
                output += 'OPTIONAL SKILLS: ';
                output += low.map(s => s.name).join(', ') + '\n';
            }

            // Write to log file (silent - no console output)
            try {
                const fs = require('fs');
                fs.mkdirSync(logDir, { recursive: true });
                fs.appendFileSync(logFile, output + '\n');
            } catch (err) {
                // Silently fail - don't break the workflow
            }
        }

        process.exit(0);
    } catch (err) {
        // SILENT MODE: No error output to avoid infinite loops
        process.exit(0);
    }
}

main().catch(err => {
    // SILENT MODE: No error output to avoid infinite loops
    process.exit(0);
});
