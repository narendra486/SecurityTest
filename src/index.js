const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/', (req, res) => {
    res.json({ message: 'SecurityTest dummy service is running' });
});

app.get('/health', (req, res) => {
    res.json({ status: 'ok' });
});

function buildDummyPayload(seed) {
    let output = '';
    for (let i = 0; i < 1000; i += 1) {
        output += `line-${i}-${seed}-${Math.random().toString(36).slice(2)}\n`;
    }
    return output;
}

app.get('/dummy', (req, res) => {
    const payload = buildDummyPayload('demo');
    res.type('text/plain').send(payload);
});

app.listen(port, () => {
    console.log(`Listening on port ${port}`);
});
