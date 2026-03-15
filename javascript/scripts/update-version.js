const fs = require('fs');
const path = require('path');

const versionFilePath = path.resolve(__dirname, '..', '..', 'VERSION');
const packageJsonPath = path.resolve(__dirname, '..', 'package.json');

// Read version from VERSION file and convert Ruby gem format to semver.
// Ruby gems use dots for pre-release (e.g., "3.0.0.alpha"),
// while npm/semver uses hyphens (e.g., "3.0.0-alpha.0").
const rawVersion = fs.readFileSync(versionFilePath, 'utf8').trim();
const version = rawVersion.replace(/\.([a-z]+)(?:\.(\d+))?$/, (_, tag, num) => {
  return `-${tag}.${num || '0'}`;
});

// Read package.json
const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));

// Update version if it's different
if (packageJson.version !== version) {
  packageJson.version = version;
  // Write updated package.json, preserving indentation (2 spaces)
  fs.writeFileSync(packageJsonPath, JSON.stringify(packageJson, null, 2) + '\n');
  console.log(`Updated package.json version to ${version}`);
} else {
  console.log(`package.json version (${packageJson.version}) is already up to date.`);
}
