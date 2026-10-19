import fs from 'node:fs';
import path from 'node:path';

const BANNED_WORDS = [
  { word: 'E' + 'VS', regex: /\bEVS\b/i },
  { word: 'environmental' + ' ' + 'studies', regex: /\benvironmental\s+studies\b/i },
  { word: 'capstone', regex: /\bcapstone\b/i },
  { word: 'course' + ' ' + 'project', regex: /\bcourse\s+project\b/i },
  { word: 'assignment', regex: /\bassignment\b/i },
  { word: 'college' + ' ' + 'project', regex: /\bcollege\s+project\b/i },
  { word: 'project' + ' ' + 'submission', regex: /\bproject\s+submission\b/i }
];

const TARGET_DIRS = ['src', 'dist'];
const IGNORED_EXTENSIONS = new Set(['.png', '.jpg', '.jpeg', '.gif', '.ico', '.woff', '.woff2', '.ttf', '.eot']);

let foundErrors = 0;

function checkFile(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  if (IGNORED_EXTENSIONS.has(ext)) return;

  try {
    const content = fs.readFileSync(filePath, 'utf-8');
    const lines = content.split('\n');

    lines.forEach((line, index) => {
      for (const item of BANNED_WORDS) {
        if (item.regex.test(line)) {
          console.error(`BANNED WORD FOUND: "${item.word}" in ${filePath}:${index + 1}`);
          console.error(`Line: ${line.trim()}`);
          foundErrors++;
        }
      }
    });
  } catch (err) {
    // ignore unreadable files
  }
}

function scanDir(dirPath) {
  if (!fs.existsSync(dirPath)) return;
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dirPath, entry.name);
    if (entry.isDirectory()) {
      scanDir(fullPath);
    } else if (entry.isFile()) {
      checkFile(fullPath);
    }
  }
}

for (const dir of TARGET_DIRS) {
  scanDir(path.resolve(process.cwd(), dir));
}

if (foundErrors > 0) {
  console.error(`Check failed: Found ${foundErrors} banned word occurrence(s).`);
  process.exit(1);
} else {
  console.log('Banned words check passed: No banned words found in src/ or built output.');
  process.exit(0);
}
