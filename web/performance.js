// Local diagnostics and browser refresh sampling. No network telemetry.
(()=>{
  const params=new URLSearchParams(location.search);
  const enabled=params.has('perf');
  const intervals=[];let last=0,frames=0;
  let target=60,refresh=60;
  window.noArtPerfEnabled=enabled;
  window.noArtTargetFPS=()=>target;
  window.noArtRefreshHz=()=>refresh;
  const diagnostics={browser:{},engine:[],longTasks:[]};
  const output=enabled?document.createElement('script'):null;
  let meter=null;
  if(output){
    output.type='application/json';output.id='frame-diagnostics';document.body.appendChild(output);
    meter=document.createElement('output');meter.id='frame-meter';meter.setAttribute('aria-label','性能诊断');
    meter.style.cssText='position:fixed;left:6px;top:6px;z-index:40;padding:5px 8px;background:#14242cdd;color:#f5efdb;font:11px/1.5 monospace;white-space:pre;pointer-events:none';
    document.body.appendChild(meter);
  }
  function publish(){if(output)output.textContent=JSON.stringify({...diagnostics,browser:{target,rafFrames:frames,dpr:devicePixelRatio,css:[innerWidth,innerHeight],canvas:[document.querySelector('#canvas')?.width,document.querySelector('#canvas')?.height]}});}
  function raf(now){
    if(!document.hidden&&last){const dt=now-last;if(dt>3&&dt<40){intervals.push(dt);if(intervals.length>120)intervals.shift();}}
    last=document.hidden?0:now;frames++;
    if(intervals.length>=45&&frames%30===0){const sorted=[...intervals].sort((a,b)=>a-b);const fast=sorted[Math.floor(sorted.length*.2)];refresh=Math.max(refresh,Math.round(1000/fast));target=refresh>=100?120:60;}
    requestAnimationFrame(raf);
  }
  requestAnimationFrame(raf);
  window.noArtFrameReport=sample=>{if(!enabled)return;const sum=sample.intervals?.reduce((a,b)=>a+b,0)||0;
    const fps=sum?Math.round(sample.intervals.length*1000/sum):sample.frames;
    if(meter)meter.textContent=`目标 ${target} / 实测 ${fps} FPS\nP95 ${sample.p95.toFixed(1)} ms\n3D ${sample.render_size||sample.viewport}`;
    diagnostics.engine.push(sample);if(diagnostics.engine.length>180)diagnostics.engine.shift();publish();};
  if(enabled&&window.PerformanceObserver){try{new PerformanceObserver(list=>{for(const entry of list.getEntries()){diagnostics.longTasks.push({at:entry.startTime,ms:entry.duration});if(diagnostics.longTasks.length>80)diagnostics.longTasks.shift();}}).observe({type:'longtask',buffered:true});}catch{}}
  // Reproduce a phone pixel density on a desktop GPU in local benchmark exports.
  window.noArtConfigurePerformance=config=>{
    if(enabled&&location.hostname==='127.0.0.1'&&params.has('bench_dpr')){
      config.canvasResizePolicy=0;
      const ratio=Math.min(3,Math.max(1,Number(params.get('bench_dpr'))||1));
      config.canvas.width=Math.round(innerWidth*ratio);config.canvas.height=Math.round(innerHeight*ratio);
    }
  };
})();
