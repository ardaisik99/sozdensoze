import { test } from 'node:test';
import assert from 'node:assert/strict';
import { gzipSync } from 'node:zlib';
import { createWasmFetch } from '../web/download.mjs';

const wasmURL = 'https://example.test/game/index.wasm';
const raw = Uint8Array.from({length: 9000}, (_, i) => (i * 31 + (i >> 3)) % 256);
const gzip = gzipSync(raw);
function mockRange(data, seen = []) {
  return async (url, {headers} = {}) => {
    seen.push({url, headers});
    const [, a, b] = /bytes=(\d+)-(\d+)/.exec(headers.Range);
    const start = Number(a), end = Math.min(Number(b), data.length - 1);
    return new Response(data.slice(start, end+1), {status:206, headers:{
      'content-range':`bytes ${start}-${end}/${data.length}`, etag:'"engine-1"',
    }});
  };
}
test('streams all compressed ranges in order and validates decompressed size', async () => {
  const seen = [];
  const fetch = createWasmFetch({wasmURL,rawSize:raw.length,originalFetch:mockRange(gzip,seen),chunkSize:128,concurrency:3});
  const response = await fetch(wasmURL);
  assert.equal(response.headers.get('content-type'),'application/wasm');
  assert.deepEqual(new Uint8Array(await response.arrayBuffer()),raw);
  assert.ok(seen.length > 3);
  assert.ok(seen.slice(1).every(r => r.headers['If-Range'] === '"engine-1"'));
});
test('retries a failed range without restarting completed ranges', async () => {
  let failed = false, retries = 0, notifications = 0;
  const base = mockRange(gzip);
  const mock = async (url, init) => {
    if(init.headers.Range === 'bytes=128-255') {
      retries++;
      if(!failed) { failed=true; throw new TypeError('network error'); }
    }
    return base(url,init);
  };
  const fetch = createWasmFetch({wasmURL,rawSize:raw.length,originalFetch:mock,chunkSize:128,onError:()=>notifications++});
  assert.deepEqual(new Uint8Array(await (await fetch(wasmURL)).arrayBuffer()),raw);
  assert.equal(retries,2);
  assert.equal(notifications,0);
});
test('reports corrupt gzip to the loading UI instead of waiting forever', async () => {
  const corrupt = gzip.slice(); corrupt[corrupt.length-5] ^= 255;
  let notifications = 0;
  const fetch = createWasmFetch({wasmURL,rawSize:raw.length,originalFetch:mockRange(corrupt),chunkSize:128,onError:()=>notifications++});
  const response = await fetch(wasmURL);
  await assert.rejects(response.arrayBuffer());
  assert.equal(notifications,1);
});
test('reports a permanently failing range', async () => {
  let notifications=0;
  const fetch = createWasmFetch({wasmURL,rawSize:raw.length,attempts:1,originalFetch:async()=>{throw new TypeError('network error');},onError:()=>notifications++});
  await assert.rejects(fetch(wasmURL));
  assert.equal(notifications,1);
});
test('falls back to normal fetch when a server lacks range support', async () => {
  let normal=0;
  const fetch = createWasmFetch({wasmURL,rawSize:raw.length,originalFetch:async url=>{
    if(url.endsWith('.gz')) return new Response(null,{status:404});
    normal++; return new Response(raw);
  }});
  assert.deepEqual(new Uint8Array(await (await fetch(wasmURL)).arrayBuffer()),raw);
  assert.equal(normal,1);
});
test('does not intercept unrelated requests', async () => {
  let target;
  const fetch=createWasmFetch({wasmURL,rawSize:raw.length,originalFetch:async url=>{target=url;return new Response('ok');}});
  assert.equal(await (await fetch('https://example.test/game/index.pck')).text(),'ok');
  assert.equal(target,'https://example.test/game/index.pck');
});
