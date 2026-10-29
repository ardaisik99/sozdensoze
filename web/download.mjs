// Range requests keep a slow connection from restarting the entire engine.
// The compressed transport also avoids intermediary gzip decoding timeouts.
export function createWasmFetch({
  wasmURL, rawSize, originalFetch = globalThis.fetch.bind(globalThis),
  chunkSize = 256 * 1024, concurrency = 3, attempts = 3,
  timeoutMs = 120000, onError = () => {},
}) {
  const gzipURL = wasmURL + '.gz';
  class Unsupported extends Error {}
  async function chunk(start, end, etag) {
    for (let attempt = 0; attempt < attempts; attempt++) {
      const abort = new AbortController();
      const timer = setTimeout(() => abort.abort(), timeoutMs);
      try {
        const headers = { Range: `bytes=${start}-${end}` };
        if (etag) headers['If-Range'] = etag;
        const response = await originalFetch(gzipURL, { headers, signal: abort.signal });
        if (start === 0 && [200, 404].includes(response.status)) {
          await response.body?.cancel();
          throw new Unsupported();
        }
        const match = /^bytes (\d+)-(\d+)\/(\d+)$/.exec(response.headers.get('content-range') || '');
        if (response.status !== 206 || !match || Number(match[1]) !== start) {
          await response.body?.cancel();
          throw new Error('Motor parçası alınamadı.');
        }
        const data = new Uint8Array(await response.arrayBuffer());
        if (data.length !== Number(match[2]) - start + 1 || data.length !== Math.min(end + 1, Number(match[3])) - start) {
          throw new Error('Motor parçası eksik indi.');
        }
        return { data, total: Number(match[3]), etag: response.headers.get('etag') };
      } catch (error) {
        if (error instanceof Unsupported || attempt + 1 === attempts) throw error;
        await new Promise(resolve => setTimeout(resolve, 350 * (attempt + 1)));
      } finally {
        clearTimeout(timer);
      }
    }
  }
  async function compressed() {
    const first = await chunk(0, chunkSize - 1);
    const compressedStream = new ReadableStream({
      async start(controller) {
        try {
          controller.enqueue(first.data);
          for (let offset = first.data.length; offset < first.total; offset += chunkSize * concurrency) {
            const requests = [];
            for (let i = 0; i < concurrency && offset + i * chunkSize < first.total; i++) {
              const start = offset + i * chunkSize;
              requests.push(chunk(start, Math.min(start + chunkSize, first.total) - 1, first.etag));
            }
            for (const part of await Promise.all(requests)) controller.enqueue(part.data);
          }
          controller.close();
        } catch (error) {
          controller.error(error);
        }
      },
    });
    const reader = compressedStream.pipeThrough(new DecompressionStream('gzip')).getReader();
    let received = 0;
    // Explicitly notify the UI on mid-stream errors. Some Godot web loaders
    // otherwise leave their wasm-instantiation promise pending indefinitely.
    const guarded = new ReadableStream({
      async pull(controller) {
        try {
          const next = await reader.read();
          if (next.done) {
            if (received !== rawSize) throw new Error('Motor dosyası eksik indi.');
            controller.close();
          } else {
            received += next.value.byteLength;
            controller.enqueue(next.value);
          }
        } catch (error) {
          onError(error);
          controller.error(error);
        }
      },
      cancel(reason) { return reader.cancel(reason); },
    });
    return new Response(guarded, { headers: {
      'Content-Type': 'application/wasm', 'Content-Length': String(rawSize),
    } });
  }
  return async function(input, init) {
    const url = typeof input === 'string' ? input : input.url || String(input);
    if (url !== wasmURL && new URL(url, wasmURL).href !== wasmURL) return originalFetch(input, init);
    if (typeof DecompressionStream !== 'function') return originalFetch(input, init);
    try {
      return await compressed();
    } catch (error) {
      if (error instanceof Unsupported) return originalFetch(input, init);
      onError(error);
      throw error;
    }
  };
}
