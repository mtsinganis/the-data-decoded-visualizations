// Optional export QA. Run with the bundled Node runtime and NODE_PATH pointing
// to its node_modules (playwright); the chart itself only requires R.
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');
(async () => {
  const project = path.resolve('visuals/2026-10-economic-complexity-rankings');
  const chartName = process.env.TDD_CHART_BASENAME || 'chart_final';
  const comparison = chartName==='chart_asian_comparison';
  const expectedPoints = comparison ? 3 : 2;
  const browser = await chromium.launch({ headless: true, channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 1000, height: 1000 } });
  await page.goto('file:///' + path.join(project, `plots/${chartName}.svg`).replaceAll('\\', '/'));
  await page.evaluate(() => document.fonts.ready);
  const dimensions = await page.evaluate(async () => {
    for (const weight of [400,700,900]) await document.fonts.load(`${weight} 16px "Lato"`);
    const svg = document.querySelector('svg');
    const height = Math.round(1000*svg.viewBox.baseVal.height/svg.viewBox.baseVal.width);
    svg.style.width = '1000px'; svg.style.height = `${height}px`;
    if(document.body) document.body.style.margin = '0';
    return {width:1000,height};
  });
  await page.setViewportSize(dimensions);
  const result = await page.evaluate(() => ({
    fonts: [...document.fonts].map(f => ({family:f.family,weight:f.weight,status:f.status})),
    editable_text_elements: document.querySelectorAll('text').length,
    raster_images: document.querySelectorAll('image').length,
    highlighted_points: document.querySelectorAll('circle').length,
    point_radii: [...new Set([...document.querySelectorAll('circle')].map(p=>p.getAttribute('r')))],
    country_line_counts: (()=> {
      const strokes=[...document.querySelectorAll('polyline')].map(p=>getComputedStyle(p).stroke);
      return {grey:strokes.filter(s=>s==='rgb(233, 233, 233)').length,
        blue:strokes.filter(s=>s==='rgb(36, 85, 255)').length,
        green:strokes.filter(s=>s==='rgb(22, 135, 101)').length,
        purple:strokes.filter(s=>s==='rgb(128, 86, 179)').length,
        orange:strokes.filter(s=>s==='rgb(208, 138, 40)').length};
    })(),
    endpoint_label_collisions: (()=> {
      const texts=[...document.querySelectorAll('text')];
      const boxes=[['China',10],['Philippines',38],['Vietnam',44],['Australia',73]].filter(([name])=>texts.some(t=>t.textContent===name&&/font-weight:\s*(700|bold)/.test(t.getAttribute('style')||''))).map(([name,rank])=> {
        const a=texts.find(t=>t.textContent===name&&/font-weight:\s*(700|bold)/.test(t.getAttribute('style')||'')).getBBox();
        const b=texts.find(t=>t.textContent.startsWith(`#${rank} `)).getBBox();
        return {name,x:Math.min(a.x,b.x),y:Math.min(a.y,b.y),right:Math.max(a.x+a.width,b.x+b.width),bottom:Math.max(a.y+a.height,b.y+b.height)};
      });
      return boxes.flatMap((a,i)=>boxes.slice(i+1).filter(b=>a.x<b.right&&a.right>b.x&&a.y<b.bottom&&a.bottom>b.y).map(b=>[a.name,b.name]));
    })(),
    notes_divider_gap_inches: (()=> {
      const last=[...document.querySelectorAll('text')].find(t=>t.textContent.startsWith('performance. Rankings cover'));
      const b=last.getBBox(); const height=document.querySelector('svg').viewBox.baseVal.height;
      return (height-.43*72-b.y-b.height)/72;
    })(),
    colored_title_words: [...document.querySelectorAll('text')].filter(t=>
      /font-weight:\s*900/.test(t.getAttribute('style')||'') && /^(Vietnam|China|Australia|Philippines)$/.test(t.textContent))
      .map(t=>({word:t.textContent,color:getComputedStyle(t).fill})),
    annotation_highlight_collisions: (()=> {
      const fragments=['Rapid diversification into','electronics and machinery',
        'Expansion into increasingly','sophisticated manufacturing',
        'Exports remain concentrated','in minerals and energy',
        'Growing specialization in electronics','and semiconductor exports'];
      const boxes=[...document.querySelectorAll('text')].filter(t=>fragments.includes(t.textContent.trim()))
        .map(t=>({text:t.textContent,b:t.getBBox()}));
      const lines=[...document.querySelectorAll('polyline')].filter(p=>
        ['rgb(36, 85, 255)','rgb(22, 135, 101)','rgb(128, 86, 179)','rgb(208, 138, 40)'].includes(getComputedStyle(p).stroke));
      return boxes.filter(({b})=>lines.some(p=>[...p.points].some(pt=>
        pt.x>=b.x-2 && pt.x<=b.x+b.width+2 && pt.y>=b.y-2 && pt.y<=b.y+b.height+2)))
        .map(b=>b.text);
    })(),
    clipped_text: [...document.querySelectorAll('text')].filter(t => {
      const b=t.getBBox(); const bounds=document.querySelector('svg').viewBox.baseVal;
      return b.x<0 || b.y<0 || b.x+b.width>bounds.width || b.y+b.height>bounds.height;
    }).map(t=>t.textContent),
    title_bounds: [...document.querySelectorAll('text')].slice(0,4).map(t=>{
      const b=t.getBBox();return {text:t.textContent,x:b.x,y:b.y,width:b.width,height:b.height};
    })
  }));
  if(result.fonts.some(f=>f.status!=='loaded') || result.clipped_text.length || result.editable_text_elements<30 ||
      result.highlighted_points!==expectedPoints || result.point_radii.length!==(expectedPoints ? 1 : 0) ||
      result.colored_title_words.length!==expectedPoints ||
      (!comparison && !result.colored_title_words.some(t=>t.word==='China'&&t.color==='rgb(22, 135, 101)')) ||
      !result.colored_title_words.some(t=>t.word==='Australia'&&t.color==='rgb(36, 85, 255)') || result.annotation_highlight_collisions.length ||
      result.notes_divider_gap_inches<.10 || result.endpoint_label_collisions.length ||
      result.country_line_counts.grey!==(145-expectedPoints) || result.country_line_counts.blue!==1 ||
      result.country_line_counts.green!==(comparison ? 0 : 1) || result.country_line_counts.purple!==(comparison ? 1 : 0) || result.country_line_counts.orange!==(comparison ? 1 : 0))
    throw Error(JSON.stringify(result));
  // Optional visual QA screenshot goes outside the project exports.
  if (process.env.TDD_QA_SCREENSHOT) await page.screenshot({path:process.env.TDD_QA_SCREENSHOT});
  fs.writeFileSync(path.join(project,`data/${chartName==='chart_final' ? 'svg_qa' : 'svg_comparison_qa'}.json`),JSON.stringify(result,null,2));
  console.log(JSON.stringify(result));
  await browser.close();
})().catch(e=>{console.error(e);process.exitCode=1;});
