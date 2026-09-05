// Real Codex runs in disposable fixtures; no tool restrictions or global install.
// Usage: node tests/codex/run-smoke-tests.mjs [--baseline]
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, mkdirSync, readFileSync, writeFileSync, cpSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = fileURLToPath(new URL('../../', import.meta.url));
const baseline = process.argv.includes('--baseline');
const run = mkdtempSync(join(tmpdir(), 'superpowers-codex-'));
const source = join(run, 'source checkout');
const target = join(run, 'isolated worktree');
mkdirSync(source);
console.log(`Artifacts: ${run}`);

function command(bin, args, cwd = source) {
  // Windows Codex worktrees belong to its sandbox account. Trust only this
  // known fixture for this verification command, never alter global Git config.
  if (bin === 'git') args = ['-c', `safe.directory=${resolve(cwd).replaceAll('\\', '/')}`, ...args];
  const result = spawnSync(bin, args, { cwd, encoding: 'utf8', timeout: 30000, windowsHide: true });
  assert.ifError(result.error);
  assert.equal(result.status, 0, `${bin}: ${result.stderr || result.stdout}`);
  return result.stdout.trim();
}
function git(...args) { return command('git', args); }

git('init', '-b', 'main');
git('config', 'user.name', 'Codex smoke test');
git('config', 'user.email', 'codex-smoke@example.invalid');
writeFileSync(join(source, 'README.md'), 'Committed fixture.\n');
writeFileSync(join(source, 'package.json'), JSON.stringify({
  private: true, scripts: { test: 'node --test probe.test.cjs' },
}));
writeFileSync(join(source, 'probe.test.cjs'),
  "const { test } = require('node:test');\ntest('baseline', () => {});\n");
git('add', '.');
git('commit', '-m', 'Fixture');
writeFileSync(join(source, 'README.md'), 'Committed fixture.\nKeep my unfinished edit.\n');
const originalHead = git('rev-parse', 'HEAD');
const originalStatus = git('status', '--porcelain');
const originalReadme = readFileSync(join(source, 'README.md'), 'utf8');

if (!baseline) {
  for (const name of ['using-superpowers', 'using-git-worktrees']) {
    cpSync(join(repo, 'skills', name), join(run, '.agents', 'skills', name), { recursive: true });
  }
}
writeFileSync(join(run, 'AGENTS.md'),
  '# Test fixture\n\nThis is a disposable worktree test. Work only on the requested fixture task.\n');

function ask(name, prompt) {
  const log = join(run, `${name}.jsonl`);
  const result = spawnSync('codex', ['exec', '--ephemeral', '--skip-git-repo-check',
    '--sandbox', 'workspace-write', '-C', run, '--json', '-o', join(run, `${name}.md`), prompt], {
    cwd: run, input: '', encoding: 'utf8', timeout: 240000, maxBuffer: 16 * 1024 * 1024, windowsHide: true,
  });
  writeFileSync(log, result.stdout || '');
  writeFileSync(join(run, `${name}.stderr.log`), result.stderr || '');
  assert.ifError(result.error);
  assert.equal(result.status, 0, `Codex failed; inspect ${log}`);
  const commands = result.stdout.split(/\r?\n/).filter(Boolean).map(line => JSON.parse(line))
    .filter(event => event.type === 'item.completed' &&
      event.item?.type === 'command_execution' && event.item.exit_code === 0)
    .map(event => event.item.command).join('\n');
  assert.match(commands, /(?:node|npm)(?:\.cmd|\.exe)?[^\n]*?(?:--test|\btest\b)/,
    'Transcript must show a successful baseline test command');
  if (!baseline) {
    // Native discovery must lead to reading the worktree skill, not just a good guess.
    assert.match(commands, /using-git-worktrees[\\/]+SKILL\.md/,
      'Transcript must show the requested skill being read');
    assert.match(commands, /using-git-worktrees[\\/]+codex\.md/,
      'Transcript must show the Codex worktree reference being read');
    if (name === 'create') {
      assert.match(commands, /using-superpowers[\\/]+SKILL\.md/);
      assert.match(commands, /using-superpowers[\\/]+codex\.md/);
    }
  }
}

const skills = baseline ? '' : 'Use using-superpowers and using-git-worktrees. ';
ask('create', `${skills}Create an isolated worktree from "${source}" at "${target}" ` +
  'on new branch feature/probe. Preserve my existing changes. Run the baseline tests ' +
  'and report the worktree path and results. Worktree creation is authorized.');
assert.equal(git('rev-parse', 'HEAD'), originalHead, 'Source must not acquire incidental commits');
assert.equal(git('status', '--porcelain'), originalStatus, 'Source status must be preserved');
assert.equal(readFileSync(join(source, 'README.md'), 'utf8'), originalReadme);
assert.ok(existsSync(target), `Worktree was not created; inspect ${join(run, 'create.md')}`);
assert.equal(command('git', ['branch', '--show-current'], target), 'feature/probe');
assert.equal(command('git', ['rev-parse', 'HEAD'], target), originalHead, 'Must start from the requested base');
assert.equal(command('git', ['status', '--porcelain'], target), '', 'New worktree must be clean');
command('node', ['--test', 'probe.test.cjs'], target);
console.log('PASS: create worktree, run tests, preserve source and clean destination');

const worktrees = git('worktree', 'list', '--porcelain');
ask('reuse', `${baseline ? '' : 'Use using-git-worktrees. '}Continue in "${target}". Ensure this workspace is isolated, ` +
  'run its baseline tests, and report the path and results.');
assert.equal(git('worktree', 'list', '--porcelain'), worktrees, 'Must reuse the existing worktree');
assert.equal(command('git', ['status', '--porcelain'], target), '');
assert.equal(git('status', '--porcelain'), originalStatus);
assert.equal(git('rev-parse', 'HEAD'), originalHead);
assert.equal(readFileSync(join(source, 'README.md'), 'utf8'), originalReadme);
console.log('PASS: reuse existing worktree without nesting');
console.log(`Fixtures and transcripts retained at ${resolve(run)}`);
