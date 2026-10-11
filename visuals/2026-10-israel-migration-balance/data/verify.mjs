import fs from 'node:fs/promises';
import path from 'node:path';
import assert from 'node:assert/strict';
import { createRequire } from 'node:module';
const root=path.resolve(process.cwd());
const project=path.join(root,'visuals/2026-10-israel-migration-balance');
const require=createRequire(path.join(root,'website/package.json'));
const matter=require('gray-matter');
const runtime='C:/Users/marko/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules';
const sharp=require(path.join(runtime,'sharp'));
const {chromium}=require(path.join(runtime,'playwright'));
const source=await fs.readFile(path.join(project,'story.md'),'utf8');
const story=matter(source);
const post=await fs.readFile(path.join(project,'post.md'),'utf8');
assert.equal(story.data.status,'draft'); assert.equal(story.data.charts.length,3);
const keys=story.data.charts.map(c=>path.basename(c.file,'.png'));
const output=path.join(project,'data/qa');
await fs.mkdir(output,{recursive:true});
const results={status:'draft',alt_lengths:[],exports:[],pages:[],thread_lengths:[]};
for(const chart of story.data.charts){
 assert(chart.alt.length<=1000); assert(post.includes(chart.alt));
 results.alt_lengths.push({file:chart.file,characters:chart.alt.length,synchronized:true});
}
for(const line of post.split('\n').filter(x=>/^\d\//.test(x))){
 assert(line.length<=280, 'Post exceeds 280 characters: '+line.length);
 results.thread_lengths.push(line.length);
}
const actual=(await fs.readdir(path.join(project,'plots'))).filter(f=>/\.(png|svg)$/.test(f));
assert.equal(actual.length,6);
let browser;
try { browser=await chromium.launch({headless:true}); }
catch(e) { browser=await chromium.launch({headless:true,channel:'chrome'}); }
const page=await browser.newPage({viewport:{width:2112,height:2112},deviceScaleFactor:1});
for(const key of keys){
 const png=path.join(project,'plots',key+'.png');
 const svg=await fs.readFile(path.join(project,'plots',key+'.svg'),'utf8');
 const meta=await sharp(png).metadata();
 assert.equal(meta.width,2112); assert.equal(meta.height,2112);
 assert(/viewBox='0 0 633.60 633.60'/.test(svg));
 assert(svg.includes('font-weight: 900')); assert(svg.includes('font-weight: bold'));
 assert.equal((svg.match(/@font-face/g)||[]).length,4);
 await sharp(png).resize(1080,1080).toFile(path.join(output,key+'-social.png'));
 await page.setContent('<html><head><style>html,body{margin:0;background:white}svg{width:2112px;height:2112px;display:block}</style></head><body>'+
   svg.replace(/<\?xml[^>]*>/,'')+'</body></html>');
 await page.evaluate(()=>document.fonts.ready);
 const fonts=await page.evaluate(()=>Array.from(document.fonts).map(f=>({family:f.family,weight:f.weight,status:f.status})));
 assert(fonts.every(f=>f.status==='loaded'));
 const svgRender=path.join(output,key+'-svg-browser.png');
 await page.screenshot({path:svgRender});
 await sharp(svgRender).resize(1080,1080).toFile(path.join(output,key+'-svg-social.png'));
 const a=await sharp(png).removeAlpha().raw().toBuffer();
 const b=await sharp(svgRender).removeAlpha().raw().toBuffer();
 assert.equal(a.length,b.length);
 let total=0;for(let i=0;i<a.length;i++)total+=Math.abs(a[i]-b[i]);
 results.exports.push({key,png_pixels:[meta.width,meta.height],svg_points:[633.6,633.6],
   embedded_fonts:fonts,mean_absolute_rgb_difference:total/a.length});
}
const base='http://127.0.0.1:4322/the-data-decoded-visualizations/';
for(const width of [1280,390]){
 await page.setViewportSize({width,height:900});
 const response=await page.goto(base+'draft/israel-migration-balance/',{waitUntil:'networkidle'});
 assert.equal(response.status(),200);
 const state=await page.evaluate(()=>{
 const images=[...document.querySelectorAll('section.charts img')];
 const article=document.querySelector('article');
 return {width:innerWidth,scrollWidth:document.documentElement.scrollWidth,
   imageCount:images.length,images:images.map(i=>({alt:i.alt,loaded:i.complete&&i.naturalWidth>0,src:i.getAttribute('src')})),
   sections:[...article.querySelectorAll(':scope > section')].map(s=>s.className),
   links:document.querySelectorAll('section.charts a').length,
   draftLabel:document.body.innerText.includes('not published')};
 });
 assert.equal(state.imageCount,3); assert.equal(state.links,3);
 assert(state.images.every(i=>i.loaded));assert(state.draftLabel);
 assert(state.scrollWidth<=width);
 assert.deepEqual(state.sections,['story introduction','charts','story interpretation','story sources']);
 assert.deepEqual(state.images.map(i=>i.alt),story.data.charts.map(c=>c.alt));
 await page.screenshot({path:path.join(output,'draft-'+width+'.png'),fullPage:true});
 results.pages.push(state);
}
const gallery=await page.goto(base,{waitUntil:'networkidle'});
assert.equal(gallery.status(),200);
assert.equal(await page.locator('a[href*="/projects/israel-migration-balance/"]').count(),0);
results.gallery_exclusion=true;
await browser.close();
await fs.writeFile(path.join(output,'verification.json'),JSON.stringify(results,null,2)+'\n');
console.log(JSON.stringify(results,null,2));
