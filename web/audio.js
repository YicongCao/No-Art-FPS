// Use cached mono samples for local gunshots; Godot still owns the rest of the mix.
(() => {
  window.noArtInstallAudio = () => {
    const Audio = window.AudioContext || window.webkitAudioContext;
    if (!Audio || window.noArtAudio) return;
    const pcm = new Map(), buffers = new Map(), voices = new Set();
    let context, pageActive = true, focused = true, failed = false;
    let lastShot = -Infinity;
    let started = 0, dropped = 0, fallback = 0, clears = 0;
    const foreground = () => pageActive && focused && !document.hidden;
    function release(voice) {
      voices.delete(voice);
      voice.source.disconnect();
      voice.gain.disconnect();
    }
    function stop() {
      for (const voice of voices) {
        voice.source.onended = null;
        try { voice.source.stop(); } catch {}
        release(voice);
      }
      lastShot = -Infinity;
    }
    function invalidate() {
      stop();
      clears++;
    }
    function decode(key) {
      const { base64, rate } = pcm.get(key);
      const bytes = atob(base64);
      const buffer = context.createBuffer(1, bytes.length / 2, rate);
      const samples = buffer.getChannelData(0);
      for (let i = 0; i < samples.length; i++) {
        const value = bytes.charCodeAt(i * 2) | (bytes.charCodeAt(i * 2 + 1) << 8);
        samples[i] = (value < 32768 ? value : value - 65536) / 32768;
      }
      buffers.set(key, buffer);
      pcm.delete(key);
      return buffer;
    }
    function resume(trusted = false) {
      if (!foreground() || failed) return;
      try {
        if (!context && trusted) {
          context = new Audio({ latencyHint: 'interactive' });
          context.addEventListener('statechange', () => {
            if (context.state !== 'running') invalidate();
          });
          for (const key of pcm.keys()) decode(key);
        }
        if (context && context.state !== 'running' && context.state !== 'closed') {
          // A Safari resume promise can stay pending until a later gesture. Do
          // not let it prevent that gesture from trying inside its own handler.
          context.resume().catch(() => {});
        }
      } catch {
        failed = true;
        stop();
        context?.close()?.catch(() => {});
      }
    }
    function gesture(event) {
      if (event.isTrusted) resume(true);
    }
    // Touch activation is granted at release on iOS, not at touch pointerdown.
    window.addEventListener('pointerdown', event => { if (event.pointerType === 'mouse') gesture(event); }, true);
    window.addEventListener('pointerup', gesture, true);
    window.addEventListener('touchend', gesture, true);
    window.addEventListener('keydown', gesture, true);
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) invalidate(); else resume();
    });
    window.addEventListener('blur', () => { focused = false; invalidate(); });
    window.addEventListener('focus', () => { focused = true; resume(); });
    window.addEventListener('pagehide', () => { pageActive = false; invalidate(); });
    window.addEventListener('pageshow', () => { pageActive = true; resume(); });
    function useGodot() { fallback++; return false; }
    window.noArtAudio = {
      register(key, base64, rate) {
        pcm.set(key, { base64, rate });
        if (context && !failed) {
          try { decode(key); } catch { pcm.delete(key); }
        }
      },
      stop,
      shot(key, gain, pitch) {
        if (!foreground()) { dropped++; return true; }
        if (!context || failed || context.state === 'closed' || (!buffers.has(key) && !pcm.has(key))) return useGodot();
        const now = performance.now();
        // A platform interruption can suspend Godot as well. Do not reroute
        // these shots into its queue or replay them after resuming.
        if (context.state !== 'running' || now - lastShot < 40 || voices.size >= 4) {
          dropped++;
          return true;
        }
        let voice;
        try {
          voice = { source: context.createBufferSource(), gain: context.createGain() };
          voice.source.buffer = buffers.get(key) || decode(key);
          voice.source.playbackRate.value = pitch;
          voice.gain.gain.value = gain;
          voice.source.connect(voice.gain).connect(context.destination);
          voice.source.onended = () => release(voice);
          voice.source.start(0);
          voices.add(voice);
          lastShot = now;
          started++;
          return true;
        } catch {
          if (voice) release(voice);
          return useGodot();
        }
      },
      snapshot() {
        const timestamp = context?.getOutputTimestamp?.();
        return { state: context?.state ?? 'not-created', started, dropped, fallback, clears, active: voices.size,
          baseLatencyMs: context?.baseLatency == null ? null : context.baseLatency * 1000,
          outputLatencyMs: context?.outputLatency == null ? null : context.outputLatency * 1000,
          clockGapMs: timestamp?.contextTime > 0 ? Math.round((context.currentTime - timestamp.contextTime) * 1000) : null };
      },
    };
  };
})();
