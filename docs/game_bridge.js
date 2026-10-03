(() => {
  const memory = new Map(); let context, suspend;
  const stop = () => { if(suspend) suspend(); if(context) context.suspend().catch(()=>{}); };
  addEventListener('blur', stop);
  document.addEventListener('visibilitychange', () => { if(document.hidden) stop(); });
  window.frequency = {
    watch(callback) { suspend=callback; }, unwatch() { suspend=null; },
    read(key) { try { return localStorage.getItem(key); } catch (_) { return memory.get(key) ?? null; } },
    write(key, value) { memory.set(key, value); try { localStorage.setItem(key, value); return true; } catch (_) { return false; } },
    navigate(path) { if (/^\/XJY\.[A-Za-z0-9_.]+\/$/.test(path)) location.assign(new URL(path, location.origin)); },
    tone(kind) { try { if(document.hidden)return; context ??= new (window.AudioContext || window.webkitAudioContext)(); context.resume().catch(()=>{}); const o=context.createOscillator(), g=context.createGain(); o.connect(g);g.connect(context.destination); o.frequency.value=[420,660,220][kind] ?? 420; g.gain.setValueAtTime(.04,context.currentTime);g.gain.exponentialRampToValueAtTime(.0001,context.currentTime+.12);o.start();o.stop(context.currentTime+.13); } catch (_) {} },
  };
})();
