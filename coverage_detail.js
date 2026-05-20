const fs = require('fs');
const content = fs.readFileSync('coverage/lcov_filtered.info', 'utf8');
const fileBlocks = content.split('SF:').slice(1);
const results = [];
for (const block of fileBlocks) {
  const sfLine = block.split('\n')[0].trim();
  const daMatches = block.match(/^DA:\d+,\d+/mg) || [];
  let total = 0, uncovered = 0;
  const uncoveredLines = [];
  for (const da of daMatches) {
    total++;
    const parts = da.replace('DA:', '').split(',');
    if (parseInt(parts[1]) === 0) {
      uncovered++;
      uncoveredLines.push(parseInt(parts[0]));
    }
  }
  if (uncovered > 0) results.push({ file: sfLine, total, uncovered, lines: uncoveredLines });
}
results.sort((a, b) => b.uncovered - a.uncovered);
results.slice(0, 30).forEach(r => {
  const shortName = r.file.replace(/.*lib[/\\]/, '');
  console.log(r.uncovered + ' unc / ' + r.total + ' tot: ' + shortName + '  lines:' + r.lines.join(','));
});
