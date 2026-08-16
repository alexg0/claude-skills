#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import { existsSync, mkdirSync, rmSync, statSync } from "node:fs";
import path from "node:path";

function usage() {
  console.log(`Usage:
  sample-video-frames.mjs --input <video> --output-dir <directory> [options]

Options:
  --count <n>  Extract n evenly spaced frames (default: 9, range: 3–50)
  --force      Replace existing storyboard frames
  --help       Show this help

Extracts full-resolution storyboard PNGs for visual inspection. Requires ffmpeg
and ffprobe.`);
}

function fail(message) {
  console.error(`sample-video-frames: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const options = { count: 9, force: false };
  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    if (arg === "--help") {
      usage();
      process.exit(0);
    }
    if (arg === "--force") {
      options.force = true;
      continue;
    }
    const value = argv[index + 1];
    if (!value || value.startsWith("--")) fail(`${arg} requires a value`);
    if (arg === "--input") options.input = value;
    else if (arg === "--output-dir") options.outputDir = value;
    else if (arg === "--count") {
      options.count = Number(value);
      if (!Number.isInteger(options.count) || options.count < 3 || options.count > 50) {
        fail(`--count must be an integer from 3 to 50, got "${value}"`);
      }
    }
    else fail(`unknown option "${arg}"`);
    index += 1;
  }
  if (!options.input) fail("--input is required");
  if (!options.outputDir) fail("--output-dir is required");
  return options;
}

function run(command, args, options = {}) {
  try {
    return execFileSync(command, args, options);
  } catch (error) {
    fail(`${command} failed: ${error.message}`);
  }
}

function commandExists(command) {
  try {
    execFileSync(command, ["-version"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

const options = parseArgs(process.argv.slice(2));
if (!commandExists("ffmpeg") || !commandExists("ffprobe")) {
  fail("ffmpeg and ffprobe are required");
}

const input = path.resolve(options.input);
const outputDir = path.resolve(options.outputDir);
if (!existsSync(input) || !statSync(input).isFile()) {
  fail(`input is not a file: "${input}"`);
}
if (existsSync(outputDir) && !statSync(outputDir).isDirectory()) {
  fail(`output path is not a directory: "${outputDir}"`);
}

const duration = Number(
  run(
    "ffprobe",
    [
      "-v",
      "error",
      "-show_entries",
      "format=duration",
      "-of",
      "default=noprint_wrappers=1:nokey=1",
      input,
    ],
    { encoding: "utf8" }
  ).trim()
);
if (!Number.isFinite(duration) || duration <= 0) fail("video duration is unreadable");

const edgeOffset = Math.min(1, duration / 8);
const sampleSpan = Math.max(0, duration - edgeOffset * 2);
const samples = Array.from({ length: options.count }, (_, index) => {
  const progress = index / (options.count - 1);
  return [
    `frame-${String(index + 1).padStart(2, "0")}`,
    edgeOffset + sampleSpan * progress,
  ];
});
const outputs = samples.map(([name]) => path.join(outputDir, `${name}.png`));
for (const output of outputs) {
  if (existsSync(output) && !options.force) {
    fail(`output already exists: "${output}" (pass --force to replace it)`);
  }
}

mkdirSync(outputDir, { recursive: true });
const created = [];
try {
  for (let index = 0; index < samples.length; index += 1) {
    const [name, timestamp] = samples[index];
    const output = outputs[index];
    run(
      "ffmpeg",
      [
        "-y",
        "-loglevel",
        "error",
        "-ss",
        timestamp.toFixed(3),
        "-i",
        input,
        "-frames:v",
        "1",
        output,
      ],
      { stdio: "inherit" }
    );
    created.push(output);
    console.log(`${name}: ${timestamp.toFixed(2)}s -> ${output}`);
  }
} catch (error) {
  for (const output of created) {
    if (existsSync(output)) rmSync(output);
  }
  throw error;
}
