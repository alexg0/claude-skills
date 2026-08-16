#!/usr/bin/env node

import { execFileSync } from "node:child_process";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  renameSync,
  rmSync,
  statSync,
} from "node:fs";
import path from "node:path";

const VIDEO_EXTENSIONS = new Set([".webm", ".mp4", ".mov", ".m4v"]);

function usage() {
  console.log(`Usage:
  finalize-video.mjs --source <file-or-directory> --output <file.mp4> [options]

Options:
  --min-seconds <n>  Reject videos shorter than n seconds (default: 3)
  --force            Replace an existing output file
  --help             Show this help

If ffmpeg is unavailable, a non-MP4 source is copied to a stable file with its
original extension. If ffprobe is available, duration and dimensions are
validated and reported.`);
}

function fail(message) {
  console.error(`finalize-video: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const options = { minSeconds: 3, force: false };
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
    if (arg === "--source") options.source = value;
    else if (arg === "--output") options.output = value;
    else if (arg === "--min-seconds") {
      options.minSeconds = Number(value);
      if (!Number.isFinite(options.minSeconds) || options.minSeconds < 0) {
        fail(`--min-seconds must be a non-negative number, got "${value}"`);
      }
    } else {
      fail(`unknown option "${arg}"`);
    }
    index += 1;
  }
  if (!options.source) fail("--source is required");
  if (!options.output) fail("--output is required");
  return options;
}

function commandExists(command) {
  try {
    execFileSync(command, ["-version"], { stdio: "ignore" });
    return true;
  } catch {
    return false;
  }
}

function collectVideos(candidate, output = []) {
  if (!existsSync(candidate)) return output;
  const stats = statSync(candidate);
  if (stats.isFile()) {
    if (VIDEO_EXTENSIONS.has(path.extname(candidate).toLowerCase())) {
      output.push({ path: candidate, mtimeMs: stats.mtimeMs });
    }
    return output;
  }
  if (!stats.isDirectory()) return output;
  for (const entry of readdirSync(candidate, { withFileTypes: true })) {
    collectVideos(path.join(candidate, entry.name), output);
  }
  return output;
}

function inspectVideo(videoPath, minSeconds) {
  if (!commandExists("ffprobe")) return null;
  let metadata;
  try {
    const raw = execFileSync(
      "ffprobe",
      [
        "-v",
        "error",
        "-select_streams",
        "v:0",
        "-show_entries",
        "format=duration:stream=codec_name,width,height,pix_fmt",
        "-of",
        "json",
        videoPath,
      ],
      { encoding: "utf8" }
    );
    metadata = JSON.parse(raw);
  } catch (error) {
    fail(`ffprobe could not read "${videoPath}": ${error.message}`);
  }
  const stream = metadata.streams?.[0];
  const duration = Number(metadata.format?.duration);
  if (!stream?.width || !stream?.height) fail("output has no readable video stream");
  if (!Number.isFinite(duration) || duration < minSeconds) {
    fail(
      `output duration ${Number.isFinite(duration) ? duration.toFixed(2) : "unknown"}s ` +
        `is shorter than required ${minSeconds}s`
    );
  }
  return {
    duration,
    width: stream.width,
    height: stream.height,
    codec: stream.codec_name,
    pixelFormat: stream.pix_fmt,
  };
}

const options = parseArgs(process.argv.slice(2));
const sourcePath = path.resolve(options.source);
const requestedOutput = path.resolve(options.output);
const videos = collectVideos(sourcePath).sort((a, b) => b.mtimeMs - a.mtimeMs);
if (videos.length === 0) fail(`no video found under "${sourcePath}"`);

const selected = videos[0].path;
const sourceExtension = path.extname(selected).toLowerCase();
const wantsMp4 = path.extname(requestedOutput).toLowerCase() === ".mp4";
const canConvert = commandExists("ffmpeg");
const finalOutput =
  wantsMp4 && sourceExtension !== ".mp4" && !canConvert
    ? requestedOutput.slice(0, -path.extname(requestedOutput).length) + sourceExtension
    : requestedOutput;

if (path.resolve(selected) === finalOutput) {
  fail("source video and output path must be different");
}
if (existsSync(finalOutput) && !options.force) {
  fail(`output already exists: "${finalOutput}" (pass --force to replace it)`);
}

mkdirSync(path.dirname(finalOutput), { recursive: true });
const temporaryOutput = path.join(
  path.dirname(finalOutput),
  `.${path.basename(finalOutput)}.${process.pid}.tmp${path.extname(finalOutput)}`
);

try {
  if (wantsMp4 && sourceExtension !== ".mp4" && canConvert) {
    execFileSync(
      "ffmpeg",
      [
        "-y",
        "-loglevel",
        "error",
        "-i",
        selected,
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-movflags",
        "+faststart",
        temporaryOutput,
      ],
      { stdio: "inherit" }
    );
  } else {
    copyFileSync(selected, temporaryOutput);
  }

  const metadata = inspectVideo(temporaryOutput, options.minSeconds);
  if (existsSync(finalOutput)) rmSync(finalOutput);
  renameSync(temporaryOutput, finalOutput);

  console.log(`Walkthrough saved to ${finalOutput}`);
  console.log(`Source preserved at ${selected}`);
  if (!canConvert && wantsMp4 && sourceExtension !== ".mp4") {
    console.log(`ffmpeg not found; preserved ${sourceExtension.slice(1).toUpperCase()} fallback`);
  }
  if (metadata) {
    console.log(
      `${metadata.duration.toFixed(2)}s · ${metadata.width}x${metadata.height} · ` +
        `${metadata.codec} · ${metadata.pixelFormat ?? "unknown pixel format"}`
    );
  } else {
    console.log("ffprobe not found; duration and dimensions were not verified");
  }
} finally {
  if (existsSync(temporaryOutput)) rmSync(temporaryOutput);
}
