Perfect. Here’s a repo-ready package you can drop in and start shaping.

Repo structure

vision-reality-mvp/
├─ app/
│  ├─ api/
│  │  └─ generate-plan/
│  │     └─ route.ts
│  ├─ globals.css
│  ├─ layout.tsx
│  └─ page.tsx
├─ components/
│  ├─ UploadVision.tsx
│  ├─ CurrentStateForm.tsx
│  └─ PlanOutput.tsx
├─ lib/
│  ├─ openai.ts
│  ├─ prompt.ts
│  └─ types.ts
├─ public/
├─ .env.example
├─ package.json
├─ tailwind.config.ts
├─ tsconfig.json
└─ README.md

Product framing

Working name: Vision → Reality
Core promise: Upload what you want. Get a realistic path.

MVP inputs
	•	1–5 images
	•	freeform vision text
	•	current income
	•	time available per week
	•	skill level
	•	savings
	•	optional deadline

MVP outputs
	•	target lifestyle breakdown
	•	estimated income needed
	•	bottlenecks
	•	3 paths:
	•	fast / risky
	•	stable / slower
	•	hybrid
	•	next 7 days
	•	next 30 days
	•	key warning flags

Data types

lib/types.ts

export type SkillLevel = "beginner" | "intermediate" | "advanced";

export interface UserInput {
  visionText: string;
  imageSummaries?: string[];
  currentIncomeMonthly: number;
  savings: number;
  hoursPerWeek: number;
  skillLevel: SkillLevel;
  deadlineMonths?: number;
}

export interface PathOption {
  name: string;
  risk: "low" | "medium" | "high";
  speed: "slow" | "medium" | "fast";
  strategy: string;
  whyItFits: string;
  milestones: string[];
}

export interface PlanOutput {
  lifestyleCostMonthly: number;
  requiredIncomeAnnual: number;
  gapAnalysis: string[];
  bottlenecks: string[];
  paths: PathOption[];
  next7Days: string[];
  next30Days: string[];
  warnings: string[];
}

System prompt

lib/prompt.ts

import { UserInput } from "./types";

export function buildPlannerPrompt(input: UserInput) {
  return `
You are an elite strategy planner helping a user reverse-engineer a path from current reality to desired reality.

Your job is to:
1. Infer what the user's desired life likely requires.
2. Estimate lifestyle cost and annual income required.
3. Identify the biggest bottlenecks.
4. Generate 3 path options:
   - Fast / high risk
   - Stable / lower risk
   - Hybrid
5. Generate a concrete 7-day and 30-day action plan.
6. Be honest, practical, and specific.
7. Do not hype. Do not moralize. Do not give vague motivational language.

Use this input:

Vision text:
${input.visionText}

Image summaries:
${(input.imageSummaries || []).join("\n- ") || "None provided"}

Current income monthly:
${input.currentIncomeMonthly}

Savings:
${input.savings}

Hours available per week:
${input.hoursPerWeek}

Skill level:
${input.skillLevel}

Deadline in months:
${input.deadlineMonths ?? "Not specified"}

Rules:
- If the vision is ambiguous, state assumptions clearly.
- Prefer rough but useful estimates over fake precision.
- Highlight tradeoffs.
- Recommend one path as the default.
- Keep each action concrete and behaviorally specific.

Return ONLY valid JSON in this exact shape:
{
  "lifestyleCostMonthly": number,
  "requiredIncomeAnnual": number,
  "gapAnalysis": ["..."],
  "bottlenecks": ["..."],
  "paths": [
    {
      "name": "string",
      "risk": "low|medium|high",
      "speed": "slow|medium|fast",
      "strategy": "string",
      "whyItFits": "string",
      "milestones": ["..."]
    }
  ],
  "next7Days": ["..."],
  "next30Days": ["..."],
  "warnings": ["..."]
}
`;
}

OpenAI client

lib/openai.ts

import OpenAI from "openai";

export const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

API route

app/api/generate-plan/route.ts

import { NextRequest, NextResponse } from "next/server";
import { openai } from "@/lib/openai";
import { buildPlannerPrompt } from "@/lib/prompt";
import { UserInput, PlanOutput } from "@/lib/types";

export async function POST(req: NextRequest) {
  try {
    const input = (await req.json()) as UserInput;

    if (!input.visionText?.trim()) {
      return NextResponse.json(
        { error: "visionText is required" },
        { status: 400 }
      );
    }

    const prompt = buildPlannerPrompt(input);

    const response = await openai.responses.create({
      model: "gpt-5",
      input: prompt,
    });

    const text = response.output_text?.trim();

    if (!text) {
      return NextResponse.json(
        { error: "Model returned empty output" },
        { status: 500 }
      );
    }

    let parsed: PlanOutput;
    try {
      parsed = JSON.parse(text) as PlanOutput;
    } catch {
      return NextResponse.json(
        { error: "Model returned invalid JSON", raw: text },
        { status: 500 }
      );
    }

    return NextResponse.json(parsed);
  } catch (error) {
    console.error(error);
    return NextResponse.json(
      { error: "Failed to generate plan" },
      { status: 500 }
    );
  }
}

Main page

app/page.tsx

"use client";

import { useState } from "react";
import { UserInput, PlanOutput } from "@/lib/types";

const initialInput: UserInput = {
  visionText: "",
  currentIncomeMonthly: 0,
  savings: 0,
  hoursPerWeek: 10,
  skillLevel: "beginner",
  deadlineMonths: 12,
  imageSummaries: [],
};

export default function HomePage() {
  const [input, setInput] = useState<UserInput>(initialInput);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<PlanOutput | null>(null);
  const [error, setError] = useState("");

  async function handleSubmit() {
    setLoading(true);
    setError("");
    setResult(null);

    try {
      const res = await fetch("/api/generate-plan", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(input),
      });

      const data = await res.json();

      if (!res.ok) {
        throw new Error(data.error || "Request failed");
      }

      setResult(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : "Unknown error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="mx-auto max-w-4xl p-6 space-y-6">
      <h1 className="text-3xl font-bold">Vision → Reality</h1>
      <p className="text-sm text-neutral-400">
        Upload your goal. Get a realistic path.
      </p>

      <section className="space-y-4 rounded-2xl border p-4">
        <textarea
          className="w-full min-h-40 rounded-xl border p-3 bg-transparent"
          placeholder="Describe your ideal life, goal, business, physique, home, freedom, etc."
          value={input.visionText}
          onChange={(e) =>
            setInput((prev) => ({ ...prev, visionText: e.target.value }))
          }
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <input
            className="rounded-xl border p-3 bg-transparent"
            type="number"
            placeholder="Current monthly income"
            value={input.currentIncomeMonthly}
            onChange={(e) =>
              setInput((prev) => ({
                ...prev,
                currentIncomeMonthly: Number(e.target.value),
              }))
            }
          />
          <input
            className="rounded-xl border p-3 bg-transparent"
            type="number"
            placeholder="Savings"
            value={input.savings}
            onChange={(e) =>
              setInput((prev) => ({
                ...prev,
                savings: Number(e.target.value),
              }))
            }
          />
          <input
            className="rounded-xl border p-3 bg-transparent"
            type="number"
            placeholder="Hours per week available"
            value={input.hoursPerWeek}
            onChange={(e) =>
              setInput((prev) => ({
                ...prev,
                hoursPerWeek: Number(e.target.value),
              }))
            }
          />
          <input
            className="rounded-xl border p-3 bg-transparent"
            type="number"
            placeholder="Deadline in months"
            value={input.deadlineMonths ?? ""}
            onChange={(e) =>
              setInput((prev) => ({
                ...prev,
                deadlineMonths: Number(e.target.value),
              }))
            }
          />
        </div>

        <select
          className="rounded-xl border p-3 bg-transparent"
          value={input.skillLevel}
          onChange={(e) =>
            setInput((prev) => ({
              ...prev,
              skillLevel: e.target.value as UserInput["skillLevel"],
            }))
          }
        >
          <option value="beginner">Beginner</option>
          <option value="intermediate">Intermediate</option>
          <option value="advanced">Advanced</option>
        </select>

        <button
          onClick={handleSubmit}
          disabled={loading}
          className="rounded-xl border px-4 py-3 font-medium"
        >
          {loading ? "Generating..." : "Generate Path"}
        </button>

        {error && <p className="text-red-400">{error}</p>}
      </section>

      {result && (
        <section className="space-y-6 rounded-2xl border p-4">
          <div>
            <h2 className="text-xl font-semibold">Reality Translation</h2>
            <p>Lifestyle cost: ${result.lifestyleCostMonthly.toLocaleString()}/month</p>
            <p>Required income: ${result.requiredIncomeAnnual.toLocaleString()}/year</p>
          </div>

          <div>
            <h3 className="font-semibold">Gap Analysis</h3>
            <ul className="list-disc pl-5">
              {result.gapAnalysis.map((item, i) => <li key={i}>{item}</li>)}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold">Bottlenecks</h3>
            <ul className="list-disc pl-5">
              {result.bottlenecks.map((item, i) => <li key={i}>{item}</li>)}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold">Paths</h3>
            <div className="space-y-4">
              {result.paths.map((path, i) => (
                <div key={i} className="rounded-xl border p-4">
                  <p className="font-semibold">{path.name}</p>
                  <p>Risk: {path.risk}</p>
                  <p>Speed: {path.speed}</p>
                  <p className="mt-2">{path.strategy}</p>
                  <p className="mt-2 text-sm text-neutral-400">{path.whyItFits}</p>
                  <ul className="list-disc pl-5 mt-2">
                    {path.milestones.map((m, j) => <li key={j}>{m}</li>)}
                  </ul>
                </div>
              ))}
            </div>
          </div>

          <div>
            <h3 className="font-semibold">Next 7 Days</h3>
            <ul className="list-disc pl-5">
              {result.next7Days.map((item, i) => <li key={i}>{item}</li>)}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold">Next 30 Days</h3>
            <ul className="list-disc pl-5">
              {result.next30Days.map((item, i) => <li key={i}>{item}</li>)}
            </ul>
          </div>

          <div>
            <h3 className="font-semibold">Warnings</h3>
            <ul className="list-disc pl-5">
              {result.warnings.map((item, i) => <li key={i}>{item}</li>)}
            </ul>
          </div>
        </section>
      )}
    </main>
  );
}

Minimal layout

app/layout.tsx

import "./globals.css";

export const metadata = {
  title: "Vision to Reality",
  description: "Upload your goal. Get a realistic path.",
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}

Minimal styles

app/globals.css

@tailwind base;
@tailwind components;
@tailwind utilities;

html, body {
  background: #0a0a0a;
  color: #f5f5f5;
  font-family: Arial, Helvetica, sans-serif;
}

Package file

package.json

{
  "name": "vision-reality-mvp",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint"
  },
  "dependencies": {
    "next": "^15.0.0",
    "openai": "^5.0.0",
    "react": "^19.0.0",
    "react-dom": "^19.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.0.0",
    "@types/react": "^19.0.0",
    "autoprefixer": "^10.0.0",
    "postcss": "^8.0.0",
    "tailwindcss": "^3.4.0",
    "typescript": "^5.0.0"
  }
}

Environment file

.env.example

OPENAI_API_KEY=your_key_here

README starter

README.md

# Vision → Reality MVP

Upload a vision for the life you want and get a realistic path to build toward it.

## Features
- Vision text input
- Current-state intake
- AI-generated lifestyle estimate
- Gap analysis
- 3 execution paths
- 7-day and 30-day action plans

## Setup

```bash
npm install
cp .env.example .env.local
npm run dev

Environment

Set OPENAI_API_KEY in .env.local.

Roadmap
	•	Image upload + image understanding
	•	Saved plans / auth
	•	Weekly reroute check-ins
	•	Progress tracking
	•	Plan version history

# Phase 2 upgrades

Once the base works, add these in order:

## 1. Image analysis
Let users upload inspiration images, then turn them into structured summaries like:
- “modern coastal house”
- “luxury SUV”
- “lean muscular physique”
- “remote-work lifestyle”

Then feed those summaries into the planner prompt.

## 2. Goal categories
Tag outputs by category:
- money
- business
- fitness
- location
- relationships
- lifestyle

## 3. Reality score
Add a simple meter:
- achievable soon
- achievable with compound effort
- high fantasy without major leverage

## 4. Weekly reroute
User reports:
- what they did
- what changed
- what failed

AI updates the plan.

# Good product behavior

This thing gets much better if it does these three well:

## Translate
Turn aesthetic desire into concrete requirements.

## Constrain
Tell the truth about time, money, skill, and tradeoffs.

## Sequence
Give the next actions in the right order.

# Optional upgrade: image-to-summary route

Later, add a second endpoint:

`/api/analyze-images`

Input:
- uploaded images

Output:
- structured image summaries

Then combine those with text before planning.

Example output:

```json
[
  "luxury urban apartment with minimalist interior",
  "athletic lean male physique around 10-12% body fat",
  "high-status travel and autonomy signaling",
  "business-class lifestyle with flexible time"
]

Best simple positioning

Use copy like:
	•	Upload your dream life. Get the path.
	•	Turn vision into a real plan.
	•	A vision board that actually tells you what to do.

Smart guardrails

You want the app to avoid:
	•	fake precision
	•	hype
	•	vague hustle nonsense
	•	pretending every goal has the same path

Add this principle to the prompt if needed:

Never present speculation as certainty.
Prefer rough, useful estimates and explicit assumptions.

Clean next move

After you add this to the repo, the best next build is the image intake + structured image summarizer, because that’s what makes it feel magical instead of just “another form.”

I can write that next piece cleanly too.