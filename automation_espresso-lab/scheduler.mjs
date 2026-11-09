import { createHash } from 'node:crypto';
import { readFile, appendFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

export function dailyPlan(day) {
  const seed = createHash('sha256').update(day).digest().readUInt32BE(0);
  let state = seed || 1;
  const random = () => {
    state ^= state << 13;
    state ^= state >>> 17;
    state ^= state << 5;
    return (state >>> 0) / 0x1_0000_0000;
  };

  const target = 3 + Math.floor(random() * 3);
  const hours = Array.from({ length: 24 }, (_, hour) => hour);
  for (let i = hours.length - 1; i > 0; i--) {
    const j = Math.floor(random() * (i + 1));
    [hours[i], hours[j]] = [hours[j], hours[i]];
  }

  return { target, hours: hours.slice(0, target).sort((a, b) => a - b) };
}

export function dueByHour(plan, currentHour) {
  return plan.hours.filter((hour) => hour <= currentHour).length;
}

export function canPublish(count, target, allowOneExtra = false) {
  return allowOneExtra ? count <= target : count < target;
}

function configFromSource(source, name) {
  const match = source.match(new RegExp(`${name}:\\s*['"]([^'"]+)['"]`));
  if (!match) throw new Error(`Could not read ${name} from js/config.js`);
  return match[1];
}

async function getTodayCount(url, key, day) {
  const endpoint = new URL('/rest/v1/coffees', url);
  endpoint.searchParams.set('select', 'id');
  endpoint.searchParams.set('created_at', `gte.${day}T00:00:00.000Z`);
  endpoint.searchParams.set('limit', '1');

  const response = await fetch(endpoint, {
    headers: {
      apikey: key,
      Authorization: `Bearer ${key}`,
      Prefer: 'count=exact',
      Range: '0-0',
    },
  });
  if (!response.ok) throw new Error(`Supabase count query failed (${response.status})`);

  const range = response.headers.get('content-range');
  const total = range?.split('/')[1];
  if (total && total !== '*') return Number(total);
  return (await response.json()).length;
}

async function getDatabaseConfig() {
  const source = await readFile(new URL('../js/config.js', import.meta.url), 'utf8');
  return {
    url: configFromSource(source, 'SUPABASE_URL'),
    key: configFromSource(source, 'SUPABASE_ANON_KEY'),
  };
}

async function main() {
  const outputPath = process.env.GITHUB_OUTPUT;
  const manualMode = process.env.MANUAL_MODE;
  if (manualMode) {
    if (!['preview', 'publish', 'publish_once'].includes(manualMode)) throw new Error('Invalid manual mode');
    if (manualMode === 'preview') {
      await writeOutput(outputPath, { run: 'true', mode: manualMode, reason: 'manual preview' });
      return;
    }
    if (process.env.AUTO_PUBLISH_ENABLED !== 'true') {
      await writeOutput(outputPath, { run: 'false', mode: manualMode, reason: 'auto-publishing is disabled' });
      return;
    }
    const day = new Date().toISOString().slice(0, 10);
    const plan = dailyPlan(day);
    const { url, key } = await getDatabaseConfig();
    const count = await getTodayCount(url, key, day);
    const allowOneExtra = manualMode === 'publish_once';
    const shouldRun = canPublish(count, plan.target, allowOneExtra);
    await writeOutput(outputPath, {
      run: String(shouldRun),
      mode: 'publish',
      reason: shouldRun
        ? (allowOneExtra ? 'one-time manual publish; at most one entry above daily target' : 'manual publish within daily target')
        : (allowOneExtra ? 'daily target already exceeded; one-time override unavailable' : 'daily target already met'),
    });
    return;
  }

  if (process.env.AUTO_PUBLISH_ENABLED !== 'true') {
    await writeOutput(outputPath, { run: 'false', mode: 'publish', reason: 'auto-publishing is disabled' });
    return;
  }

  const now = new Date();
  const day = now.toISOString().slice(0, 10);
  const hour = now.getUTCHours();
  const plan = dailyPlan(day);
  const due = dueByHour(plan, hour);
  if (due === 0) {
    await writeOutput(outputPath, { run: 'false', mode: 'publish', reason: 'not a scheduled hour' });
    return;
  }

  const { url, key } = await getDatabaseConfig();
  const count = await getTodayCount(url, key, day);
  const shouldRun = count < Math.min(due, plan.target);
  const reason = shouldRun
    ? `scheduled window; ${count}/${plan.target} entries today`
    : `daily target met for current window; ${count}/${plan.target} entries today`;

  await writeOutput(outputPath, {
    run: String(shouldRun),
    mode: 'publish',
    reason,
    plan: `${plan.target} entries at UTC hours ${plan.hours.map((h) => String(h).padStart(2, '0')).join(',')}`,
  });
}

async function writeOutput(path, values) {
  for (const [key, value] of Object.entries(values)) {
    console.log(`${key}: ${value}`);
    if (path) await appendFile(path, `${key}=${String(value).replaceAll('\n', ' ')}\n`);
  }
}

if (process.argv[1] && import.meta.url === pathToFileURL(resolve(process.argv[1])).href) {
  main().catch((error) => {
    console.error(error.message);
    process.exitCode = 1;
  });
}
