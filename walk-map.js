/* <walk-map> — Leaflet + OpenStreetMap, graded to the Classical paper palette.
   Attributes (also settable as properties):
     points   JSON [[lat,lng],…]  the active route
     pins     JSON [{lat,lng,label,id}]  discover markers
     mode     discover | detail | track | build
     progress 0..1 walker position along `points`
   Events (bubble to document):
     walk-route-select {id}      pin tapped
     walk-point-added  {count,km} build-mode tap
*/
(function () {
  const ACCENT = '#b68235', INK = '#201f1d';
  const GRADES = {
    Paper: 'sepia(0.34) saturate(0.48) contrast(0.9) brightness(1.07)',
    Neutral: 'saturate(0.12) contrast(0.94) brightness(1.05)',
    Ink: 'grayscale(1) contrast(1.12) brightness(0.92) invert(0.9)',
  };

  function whenLeaflet(cb) {
    if (window.L) return cb();
    const t = setInterval(() => { if (window.L) { clearInterval(t); cb(); } }, 60);
    setTimeout(() => clearInterval(t), 15000);
  }

  class WalkMap extends HTMLElement {
    static get observedAttributes() { return ['points', 'pins', 'mode', 'progress', 'grade']; }

    connectedCallback() {
      if (this._built) return;
      this._built = true;
      Object.assign(this.style, { position: 'absolute', inset: '0', display: 'block', overflow: 'hidden' });
      this._host = document.createElement('div');
      Object.assign(this._host.style, { position: 'absolute', inset: '0', background: '#e7e3dc' });
      this.appendChild(this._host);
      whenLeaflet(() => requestAnimationFrame(() => this._init()));
    }

    disconnectedCallback() { if (this._map) { this._map.remove(); this._map = null; } }

    attributeChangedCallback(n) {
      if (!this._map) return;
      if (n === 'grade') return this._grade();
      this._draw();
    }

    _grade() {
      const pane = this._host.querySelector('.leaflet-tile-pane');
      if (pane) pane.style.filter = GRADES[this.getAttribute('grade')] || GRADES.Paper;
    }

    set points(v) { this.setAttribute('points', typeof v === 'string' ? v : JSON.stringify(v)); }
    set pins(v) { this.setAttribute('pins', typeof v === 'string' ? v : JSON.stringify(v)); }

    _json(name) {
      try { return JSON.parse(this.getAttribute(name) || 'null'); } catch (e) { return null; }
    }

    _init() {
      const L = window.L;
      this._map = L.map(this._host, {
        center: [31.2232, 121.4680], zoom: 13,
        zoomControl: false, attributionControl: true,
        zoomSnap: 0.25, preferCanvas: false,
      });
      L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
        attribution: '© OpenStreetMap contributors', maxZoom: 19,
      }).addTo(this._map);

      this._grade();
      const attr = this._host.querySelector('.leaflet-control-attribution');
      if (attr) Object.assign(attr.style, {
        background: 'rgba(243,242,242,0.72)', font: '9px Lora, serif',
        color: 'rgba(32,31,29,0.55)', padding: '1px 5px',
      });

      this._layer = L.layerGroup().addTo(this._map);
      this._draft = [];
      this._map.on('click', (e) => {
        if (this.getAttribute('mode') !== 'build') return;
        this._draft.push([e.latlng.lat, e.latlng.lng]);
        this._drawDraft();
        this.dispatchEvent(new CustomEvent('walk-point-added', {
          bubbles: true, composed: true,
          detail: { count: this._draft.length, km: this._km(this._draft) },
        }));
      });
      setTimeout(() => this._map && this._map.invalidateSize(), 60);
      this._draw();
    }

    _km(pts) {
      const L = window.L; let d = 0;
      for (let i = 1; i < pts.length; i++) d += L.latLng(pts[i - 1]).distanceTo(L.latLng(pts[i]));
      return Math.round(d / 100) / 10;
    }

    _dot(cls, size, fill, stroke, ring) {
      const px = size;
      return window.L.divIcon({
        className: '', iconSize: [px, px], iconAnchor: [px / 2, px / 2],
        html: `<div style="width:${px}px;height:${px}px;border-radius:50%;background:${fill};
          box-sizing:border-box;border:${stroke};${ring ? 'box-shadow:0 0 0 6px rgba(182,130,53,0.18);' : ''}"></div>`,
      });
    }

    _drawDraft() {
      const L = window.L;
      if (this._draftLine) this._layer.removeLayer(this._draftLine);
      if (this._draftDots) this._draftDots.forEach(d => this._layer.removeLayer(d));
      this._draftDots = [];
      if (this._draft.length > 1) {
        this._draftLine = L.polyline(this._draft, {
          color: ACCENT, weight: 2.5, opacity: 0.95, dashArray: '1 7', lineCap: 'round',
        }).addTo(this._layer);
      }
      this._draft.forEach((p, i) => {
        const m = L.marker(p, { icon: this._dot('', 11, i === 0 ? ACCENT : '#f3f2f2', `1.5px solid ${ACCENT}`) })
          .addTo(this._layer);
        this._draftDots.push(m);
      });
    }

    _draw() {
      const L = window.L, map = this._map;
      if (!map) return;
      this._layer.clearLayers();
      this._draftLine = null; this._draftDots = [];
      const mode = this.getAttribute('mode') || 'discover';
      const pins = this._json('pins') || [];
      const points = this._json('points') || [];
      const bounds = [];

      if (mode === 'discover' && pins.length) {
        pins.forEach((p) => {
          if (p.points) {
            L.polyline(p.points, { color: INK, weight: 5, opacity: 0.07, lineCap: 'round' }).addTo(this._layer);
            L.polyline(p.points, { color: ACCENT, weight: 1.6, opacity: 0.8, lineCap: 'round' }).addTo(this._layer);
            p.points.forEach(pt => bounds.push(pt));
          }
        });
        pins.forEach((p) => {
          const icon = L.divIcon({
            className: '', iconSize: [30, 30], iconAnchor: [15, 15],
            html: `<div style="width:30px;height:30px;border-radius:50%;background:#f3f2f2;
              border:1px solid ${ACCENT};box-shadow:0 1px 3px rgba(45,43,43,0.22);
              display:flex;align-items:center;justify-content:center;
              font:600 14px 'Cormorant Garamond',serif;font-feature-settings:'tnum';
              color:${ACCENT};">${p.label || ''}</div>`,
          });
          const m = L.marker([p.lat, p.lng], { icon }).addTo(this._layer);
          m.on('click', () => this.dispatchEvent(new CustomEvent('walk-route-select', {
            bubbles: true, composed: true, detail: { id: p.id },
          })));
          bounds.push([p.lat, p.lng]);
        });
      }

      if (points.length > 1) {
        L.polyline(points, { color: INK, weight: 7, opacity: 0.08, lineCap: 'round' }).addTo(this._layer);
        L.polyline(points, {
          color: ACCENT, weight: mode === 'track' ? 2 : 2.6, opacity: mode === 'track' ? 0.4 : 0.95,
          lineCap: 'round', dashArray: mode === 'track' ? '2 6' : null,
        }).addTo(this._layer);
        points.forEach(p => bounds.push(p));
        L.marker(points[0], { icon: this._dot('', 12, ACCENT, '1.5px solid #f3f2f2') }).addTo(this._layer);
        L.marker(points[points.length - 1], { icon: this._dot('', 12, '#f3f2f2', `2px solid ${ACCENT}`) }).addTo(this._layer);
      }

      if (mode === 'track' && points.length > 1) {
        const prog = parseFloat(this.getAttribute('progress') || '0');
        const segs = [];
        let total = 0;
        for (let i = 1; i < points.length; i++) {
          const d = L.latLng(points[i - 1]).distanceTo(L.latLng(points[i]));
          segs.push(d); total += d;
        }
        let want = total * Math.max(0, Math.min(1, prog)), at = points[0], acc = 0;
        for (let i = 0; i < segs.length; i++) {
          if (acc + segs[i] >= want) {
            const t = segs[i] ? (want - acc) / segs[i] : 0;
            at = [points[i][0] + (points[i + 1][0] - points[i][0]) * t,
                  points[i][1] + (points[i + 1][1] - points[i][1]) * t];
            const walked = points.slice(0, i + 1).concat([at]);
            L.polyline(walked, { color: ACCENT, weight: 3.4, opacity: 1, lineCap: 'round' }).addTo(this._layer);
            break;
          }
          acc += segs[i];
        }
        L.marker(at, { icon: this._dot('', 14, ACCENT, '2px solid #f3f2f2', true) }).addTo(this._layer);
        map.setView(at, 16, { animate: true });
        return;
      }

      if (bounds.length) {
        map.fitBounds(bounds, { padding: mode === 'detail' ? [46, 46] : [40, 120], maxZoom: 16 });
      }
      if (mode === 'build') this._drawDraft();
    }
  }
  if (!customElements.get('walk-map')) customElements.define('walk-map', WalkMap);
})();
