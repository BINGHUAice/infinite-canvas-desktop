const [debugPort, servicePort] = process.argv.slice(2);
const origin = `http://127.0.0.1:${servicePort}`;
const deadline = Date.now() + 15000;
const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function evaluate(url) {
    const socket = new WebSocket(url);
    try {
        return await new Promise((resolve, reject) => {
            const guard = setTimeout(() => reject(new Error('Renderer response timed out')), 1500);
            const finish = (result, error) => { clearTimeout(guard); if (error) reject(error); else resolve(result); };
            socket.addEventListener('open', () => socket.send(JSON.stringify({ id: 1, method: 'Runtime.evaluate', params: { expression: '({title: document.title, ready: document.readyState, rendered: Boolean(document.querySelector("#root")?.childElementCount)})', returnByValue: true } })));
            socket.addEventListener('error', () => finish(undefined, new Error('Renderer socket error')));
            socket.addEventListener('message', ({ data }) => {
                const packet = JSON.parse(data);
                if (packet.id === 1) finish(packet.result?.result?.value, packet.error);
            });
        });
    } finally { socket.close(); }
}
(async () => {
    let observed;
    while (Date.now() < deadline) {
        try {
            const targets = await fetch(`http://127.0.0.1:${debugPort}/json/list`, { signal: AbortSignal.timeout(1000) }).then((res) => res.json());
            const target = targets.find((item) => item.type === 'page' && item.url.startsWith(`${origin}/`));
            if (target) {
                observed = await evaluate(target.webSocketDebuggerUrl);
                if (observed?.ready === 'complete' && observed?.rendered) {
                    const health = await fetch(`${origin}/health`, { signal: AbortSignal.timeout(1000) });
                    if (health.ok) { console.log(JSON.stringify({ health: health.status, ...observed })); return; }
                }
            }
        } catch { }
        await pause(250);
    }
    throw new Error(`Renderer did not mount. Last result: ${JSON.stringify(observed)}`);
})().catch((err) => { console.error(err.message); process.exitCode = 1; });