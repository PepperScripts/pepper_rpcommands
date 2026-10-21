// Pepper RP-Commands – NUI: zeichnet die Sprechblasen an den Bildschirmpositionen, die der Client jeden Frame schickt.
// Texte werden nur über textContent gesetzt – kein HTML aus Spielereingaben.
(() => {
    'use strict';

    const layer = document.getElementById('layer');
    const groups = new Map(); // Server-ID → { el, items: Map(id → el) }
    const LEAVE_MS = 200;

    const path = (d) => `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">${d}</svg>`;
    const ICONS = {
        me: path('<circle cx="12" cy="8" r="4"/><path d="M4 21c0-4 3.6-7 8-7s8 3 8 7"/>'),
        do: path('<path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z"/><circle cx="12" cy="12" r="3"/>'),
        try: path('<path d="M12 3l1.9 5.6L19.5 10l-5.6 1.9L12 17.5l-1.9-5.6L4.5 10l5.6-1.4z"/><path d="M19 17l.7 1.8 1.8.7-1.8.7L19 22l-.7-1.8-1.8-.7 1.8-.7z"/>'),
        dice: path('<rect x="3" y="3" width="18" height="18" rx="4"/><circle cx="8.5" cy="8.5" r="1.2" fill="currentColor"/><circle cx="15.5" cy="15.5" r="1.2" fill="currentColor"/><circle cx="12" cy="12" r="1.2" fill="currentColor"/>'),
        coin: path('<circle cx="12" cy="12" r="9"/><circle cx="12" cy="12" r="5.5"/>'),
        status: path('<path d="M20.6 13.4l-7.2 7.2a2 2 0 0 1-2.8 0L3 13V3h10l7.6 7.6a2 2 0 0 1 0 2.8z"/><circle cx="7.5" cy="7.5" r="1.3" fill="currentColor"/>'),
        ooc: path('<path d="M8 4C5 6.5 5 17.5 8 20"/><path d="M16 4c3 2.5 3 13.5 0 16"/>'),
        whisper: path('<path d="M21 12a8 8 0 0 1-11.6 7.1L4 20.5l1.4-4.6A8 8 0 1 1 21 12z" stroke-dasharray="3 3"/>'),
        shout: path('<path d="M3 10v4h3l6 4V6L6 10H3z"/><path d="M16 8.5a5 5 0 0 1 0 7"/><path d="M19 6a8.5 8.5 0 0 1 0 12"/>'),
        chat: path('<path d="M21 12a8 8 0 0 1-11.6 7.1L4 20.5l1.4-4.6A8 8 0 1 1 21 12z"/>'),
    };

    const rgb = (c) => Array.isArray(c) && c.length >= 3 ? `rgb(${+c[0] || 0}, ${+c[1] || 0}, ${+c[2] || 0})` : 'rgb(255, 255, 255)';

    function createBubble(item) {
        const el = document.createElement('div');
        el.className = 'bubble';
        const icon = document.createElement('span');
        icon.className = 'bubble-icon';
        const text = document.createElement('span');
        text.className = 'bubble-text';
        el.append(icon, text);
        updateBubble(el, item);
        return el;
    }

    function updateBubble(el, item) {
        const kind = String(item.kind || 'custom');
        const iconKey = Object.prototype.hasOwnProperty.call(ICONS, item.icon) ? item.icon : 'chat';
        const signature = `${kind}|${iconKey}|${item.text}|${item.color}`;
        if (el.dataset.sig === signature) return;
        el.dataset.sig = signature;
        el.className = `bubble kind-${kind.replace(/[^a-z]/g, '')}${item.status ? ' status' : ''}`;
        el.style.setProperty('--accent', rgb(item.color));
        el.firstChild.innerHTML = ICONS[iconKey]; // nur feste Symbole, nie Spielertext
        el.lastChild.textContent = String(item.text ?? '');
    }

    function leave(el, onDone) {
        if (el.classList.contains('leaving')) return;
        el.classList.add('leaving');
        setTimeout(() => { el.remove(); if (onDone) onDone(); }, LEAVE_MS);
    }

    function render(list) {
        const seen = new Set();
        for (const g of list) {
            const key = String(g.id);
            seen.add(key);
            let group = groups.get(key);
            if (!group) {
                const el = document.createElement('div');
                el.className = 'group';
                layer.appendChild(el);
                group = { el, items: new Map() };
                groups.set(key, group);
            }
            const x = (g.x * 100).toFixed(3);
            const y = (g.y * 100).toFixed(3);
            const s = Math.max(0.4, Math.min(1.6, Number(g.s) || 1));
            group.el.style.left = `${x}%`;
            group.el.style.top = `${y}%`;
            group.el.style.transform = `translate(-50%, -100%) scale(${s.toFixed(3)})`;

            const ids = new Set();
            for (const item of g.items || []) {
                const id = String(item.id);
                ids.add(id);
                let el = group.items.get(id);
                if (!el || el.classList.contains('leaving')) {
                    el = createBubble(item);
                    group.items.set(id, el);
                } else {
                    updateBubble(el, item);
                }
                group.el.appendChild(el); // hält die Reihenfolge: Status oben, neuester Text unten
            }
            for (const [id, el] of group.items) {
                if (!ids.has(id)) {
                    group.items.delete(id);
                    leave(el);
                }
            }
        }
        for (const [key, group] of groups) {
            if (seen.has(key)) continue;
            groups.delete(key);
            group.el.querySelectorAll('.bubble').forEach((el) => leave(el));
            setTimeout(() => group.el.remove(), LEAVE_MS);
        }
    }

    window.addEventListener('message', (event) => {
        const data = event.data;
        if (!data || data.action !== 'frame') return;
        const style = data.style === 'minimal' ? 'style-minimal' : 'style-modern';
        if (document.body.className !== style) document.body.className = style;
        render(Array.isArray(data.groups) ? data.groups : []);
    });
})();
