// Copies the website's structured content (services, training programs, solutions, industries, and
// insights articles) into assets/content/site.json, so the app shows the same text as thenovatrix.com.
//
//   node tool/sync_site_content.js            # from https://thenovatrix.com
//   node tool/sync_site_content.js <site-url>
//
// The website keeps this content as data in its JavaScript bundle. Each list is found by the slug of
// its first entry (the bundle's variable names change on every build), and only its literal data is
// evaluated, in an empty sandbox; references to other values are resolved the same way. If the site
// reorders or renames a list, the script stops and says which one, rather than writing partial data.
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const site = (process.argv[2] || 'https://thenovatrix.com').replace(/\/+$/, '');
const out = path.join(__dirname, '..', 'assets', 'content', 'site.json');

// Each list, by the slug its first entry has on the website.
const lists = {
  offerings: 'software-development',
  programs: 'corporate-training',
  solutions: 'web-and-mobile-platforms',
  industries: 'education',
  insights: 'preparing-for-a-system-implementation',
};

function literalAt(code, start) {
  let depth = 0;
  let quote = null;
  for (let k = start; k < code.length; k++) {
    const c = code[k];
    if (quote) {
      if (c === '\\') k++;
      else if (c === quote) quote = null;
      continue;
    }
    if (c === '"' || c === "'" || c === '`') quote = c;
    else if (c === '[' || c === '{') depth++;
    else if (c === ']' || c === '}') {
      depth--;
      if (depth === 0) return code.slice(start, k + 1);
    }
  }
  return null;
}

function extract(code) {
  const byName = (name) => {
    const m = new RegExp('[,;{ (]' + name.replace(/\$/g, '\\$') + '=([\\[{])').exec(code);
    return m ? literalAt(code, m.index + m[0].length - 1) : null;
  };
  const ctx = vm.createContext({});
  const cache = {};
  const nothing = new Proxy({}, { get: () => null });
  ctx.__scope = new Proxy({}, {
    has: (_, k) => typeof k === 'string' && k !== '__scope',
    get: (_, k) => {
      if (typeof k !== 'string') return undefined;
      if (!(k in cache)) {
        cache[k] = nothing;
        const lit = byName(k);
        if (lit) {
          try { cache[k] = evaluate(lit); } catch (_) { /* not plain data: leave it empty */ }
        }
      }
      return cache[k];
    },
  });
  const evaluate = (lit) => vm.runInContext('with (__scope) { (' + lit + ') }', ctx, { timeout: 2000 });

  const result = {};
  for (const [key, firstSlug] of Object.entries(lists)) {
    const m = new RegExp('=\\[\\{slug:"' + firstSlug + '",').exec(code);
    if (!m) throw new Error(`Couldn't find the "${key}" list (first slug "${firstSlug}") on the website.`);
    const data = evaluate(literalAt(code, m.index + 1));
    if (!Array.isArray(data) || data.length === 0) throw new Error(`The "${key}" list is empty.`);
    result[key] = data;
  }
  return result;
}

async function main() {
  const html = await (await fetch(site + '/')).text();
  const bundle = /src="(\/assets\/index-[^"]+\.js)"/.exec(html);
  if (!bundle) throw new Error("Couldn't find the website's script bundle.");
  const code = await (await fetch(site + bundle[1])).text();
  const content = { source: site, syncedAt: new Date().toISOString().slice(0, 10), ...extract(code) };
  fs.mkdirSync(path.dirname(out), { recursive: true });
  fs.writeFileSync(out, JSON.stringify(content, null, 1) + '\n');
  for (const key of Object.keys(lists)) console.log(`${key}: ${content[key].length}`);
  console.log(`Wrote ${path.relative(process.cwd(), out)}`);
}

main().catch((e) => {
  console.error(e.message);
  process.exit(1);
});
