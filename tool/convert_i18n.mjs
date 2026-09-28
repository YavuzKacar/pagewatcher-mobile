#!/usr/bin/env node
// Converts the web app's i18next JSON locales into Flutter ARB files.
//
//   node tool/convert_i18n.mjs [path/to/pagewatcher/frontend/src/i18n/locales]
//
// Sources, per language:
//   - web namespaces (common, app, auth) from the web repo
//   - mobile-only strings from i18n/mobile/<lang>.json in this repo
// Output: lib/l10n/app_<lang>.arb (app_en.arb is the gen-l10n template).
//
// Key mapping: namespace + nested path, camelCased.
//   auth.json  modal.signIn            -> authModalSignIn
//   app.json   toolNames.create_monitor -> appToolNamesCreateMonitor
// i18next `{{var}}` becomes an ARB `{var}` placeholder, and `key_one`/`key_other`
// pairs are merged into a single ICU plural message keyed on `count`.
// Messages missing from a language fall back to English at generation time.

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const webLocales = path.resolve(
  process.argv[2] ?? path.join(root, '..', 'pagewatcher', 'frontend', 'src', 'i18n', 'locales'),
);
const mobileLocales = path.join(root, 'i18n', 'mobile');
const outDir = path.join(root, 'lib', 'l10n');

const LANGUAGES = ['en', 'de', 'fr', 'tr', 'ko', 'ja'];
const WEB_NAMESPACES = ['common', 'app', 'auth'];
const PLURAL_SUFFIXES = ['zero', 'one', 'two', 'few', 'many', 'other'];

const camel = (parts) =>
  parts
    .flatMap((p) => String(p).split(/[_\-\s]+/))
    .filter(Boolean)
    .map((p, i) => (i === 0 ? p[0].toLowerCase() + p.slice(1) : p[0].toUpperCase() + p.slice(1)))
    .join('');

function flatten(obj, prefix, out) {
  for (const [k, v] of Object.entries(obj)) {
    const keyPath = [...prefix, k];
    if (v !== null && typeof v === 'object') flatten(v, keyPath, out);
    else out.push([keyPath, String(v)]);
  }
  return out;
}

const readJson = (file) => (fs.existsSync(file) ? JSON.parse(fs.readFileSync(file, 'utf8')) : null);

/** Collects `{{var}}` names and rewrites them to ARB `{var}` syntax. */
function convertText(text, placeholders) {
  return text.replace(/\{\{\s*([A-Za-z0-9_]+)\s*\}\}/g, (_, name) => {
    const dartName = camel([name]);
    placeholders.add(dartName);
    return `{${dartName}}`;
  });
}

function buildArb(lang) {
  const entries = [];
  for (const ns of WEB_NAMESPACES) {
    const data = readJson(path.join(webLocales, lang, `${ns}.json`));
    if (data) flatten(data, [ns], entries);
    else if (lang === 'en') throw new Error(`Missing English namespace ${ns} in ${webLocales}`);
  }
  const mobile = readJson(path.join(mobileLocales, `${lang}.json`));
  if (mobile) flatten(mobile, ['mobile'], entries);

  // Group plural variants: [..., 'foo_one'] and [..., 'foo_other'] -> 'foo'.
  const messages = new Map(); // key -> {text} | {plural: {one, other}}
  for (const [keyPath, rawText] of entries) {
    const last = keyPath[keyPath.length - 1];
    const m = /^(.*)_(zero|one|two|few|many|other)$/.exec(last);
    if (m && PLURAL_SUFFIXES.includes(m[2])) {
      const key = camel([...keyPath.slice(0, -1), m[1]]);
      const entry = messages.get(key) ?? { plural: {} };
      entry.plural[m[2]] = rawText;
      messages.set(key, entry);
    } else {
      let key = camel(keyPath);
      if (!/^[a-z][A-Za-z0-9]*$/.test(key)) key = key.replace(/[^A-Za-z0-9]/g, '');
      messages.set(key, { text: rawText });
    }
  }

  const arb = { '@@locale': lang };
  for (const [key, entry] of [...messages.entries()].sort(([a], [b]) => a.localeCompare(b))) {
    const placeholders = new Set();
    let value;
    if (entry.plural) {
      const branches = Object.entries(entry.plural)
        .map(([form, text]) => `${form === 'zero' ? '=0' : form}{${convertText(text, placeholders)}}`)
        .join(' ');
      value = `{count, plural, ${branches}}`;
      placeholders.add('count');
    } else {
      value = convertText(entry.text, placeholders);
    }
    arb[key] = value;
    if (lang === 'en' && placeholders.size > 0) {
      arb[`@${key}`] = {
        placeholders: Object.fromEntries(
          [...placeholders].map((p) => [p, { type: p === 'count' ? 'int' : 'String' }]),
        ),
      };
    }
  }
  return arb;
}

fs.mkdirSync(outDir, { recursive: true });
for (const lang of LANGUAGES) {
  const arb = buildArb(lang);
  const file = path.join(outDir, `app_${lang}.arb`);
  fs.writeFileSync(file, JSON.stringify(arb, null, 2) + '\n', 'utf8');
  const count = Object.keys(arb).filter((k) => !k.startsWith('@')).length;
  console.log(`wrote ${path.relative(root, file)} (${count} messages)`);
}
