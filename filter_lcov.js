const fs = require('fs');

// Read exclusion patterns
const excludeLines = fs.readFileSync('lcov_exclude.txt', 'utf8').split('\n')
  .map(l => l.replace('\r', '').trim())
  .filter(l => l && !l.startsWith('#'));

// PowerShell -like operator: * matches any sequence (including /)
function matches(sfPath, pattern) {
  const regexStr = pattern
    .replace(/[-[\]/{}()+?\\^$|]/g, '\\$&') // escape special regex chars
    .replace(/\\\*/g, '__STAR__') // protect already-escaped *
    .replace(/\*/g, '.*') // * matches any sequence
    .replace(/__STAR__/g, '\\*');
  try {
    return new RegExp('^' + regexStr + '$', 'i').test(sfPath);
  } catch(e) {
    return false;
  }
}

const content = fs.readFileSync('coverage/lcov.info', 'utf8');
const lines = content.split('\n');
const output = [];
let block = [];
let inBlock = false;
let skip = false;
let excluded = 0, kept = 0;

for (const rawLine of lines) {
  const line = rawLine.replace('\r', '');
  const sfMatch = line.match(/^[SK]F:(.+)/);
  if (sfMatch) {
    const sfPath = sfMatch[1].replace(/\\/g, '/').trim();
    skip = excludeLines.some(pat => matches(sfPath, pat));
    inBlock = true;
    block = [line];
  } else if (line === 'end_of_record') {
    if (inBlock) {
      block.push(line);
      if (!skip) { output.push(...block); kept++; }
      else excluded++;
      block = [];
      inBlock = false;
      skip = false;
    }
  } else if (inBlock) {
    block.push(line);
  } else {
    output.push(line);
  }
}

fs.writeFileSync('coverage/lcov_filtered.info', output.join('\n') + '\n', 'utf8');

// Count coverage
let totalLines = 0, coveredLines = 0;
const filtContent = fs.readFileSync('coverage/lcov_filtered.info', 'utf8');
const files = filtContent.split('SF:');
for (const file of files.slice(1)) {
  const daMatches = file.match(/^DA:(\d+),(\d+)/mg) || [];
  for (const da of daMatches) {
    const parts = da.replace('DA:', '').split(',');
    totalLines++;
    if (parseInt(parts[1]) > 0) coveredLines++;
  }
}
console.log('Kept:', kept, 'Excluded:', excluded);
console.log('Total:', totalLines, 'Covered:', coveredLines, 'Pct:', (coveredLines/totalLines*100).toFixed(1) + '%');
