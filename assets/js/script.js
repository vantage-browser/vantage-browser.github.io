const navToggle=document.querySelector('.nav-toggle');const siteNav=document.querySelector('#site-nav');if(navToggle&&siteNav){const setOpen=open=>{if(open){const scrollbarWidth=window.innerWidth-document.documentElement.clientWidth;document.body.style.paddingRight=scrollbarWidth>0?`${scrollbarWidth}px`:''}navToggle.setAttribute('aria-expanded',String(open));navToggle.setAttribute('aria-label',open?'Close navigation':'Open navigation');siteNav.classList.toggle('open',open);document.body.classList.toggle('nav-open',open);if(!open)document.body.style.removeProperty('padding-right')};navToggle.addEventListener('click',()=>setOpen(navToggle.getAttribute('aria-expanded')!=='true'));siteNav.addEventListener('click',event=>{if(event.target.closest('a'))setOpen(false)});document.addEventListener('keydown',event=>{if(event.key==='Escape'){setOpen(false);navToggle.focus()}})}
document.querySelectorAll('pre code').forEach(code=>{const raw=code.textContent;const shell=document.createElement('div');shell.className='code-shell';code.parentElement.before(shell);shell.append(code.parentElement);const button=document.createElement('button');button.type='button';button.className='copy-code';button.setAttribute('aria-label','Copy command');button.textContent='Copy';button.addEventListener('click',async()=>{await navigator.clipboard.writeText(raw);button.textContent='Copied';setTimeout(()=>button.textContent='Copy',1200)});shell.append(button)});
const docsNav=document.querySelector('.docs-nav');const docsToggle=document.querySelector('.docs-nav-toggle');if(docsNav){const current=location.pathname.replace(/\/$/,'')||'/';docsNav.querySelectorAll('a').forEach(link=>{const path=new URL(link.href,location.href).pathname.replace(/\/$/,'')||'/';if(path===current){link.classList.add('current');link.setAttribute('aria-current','page');const section=link.closest('details');if(section)section.open=true}})}if(docsNav&&docsToggle){const setDocsOpen=open=>{docsNav.classList.toggle('mobile-open',open);docsToggle.setAttribute('aria-expanded',String(open));docsToggle.textContent=open?'Close documentation':'Browse documentation';document.body.classList.toggle('docs-open',open)};docsToggle.addEventListener('click',()=>setDocsOpen(docsToggle.getAttribute('aria-expanded')!=='true'));docsNav.addEventListener('click',event=>{if(event.target.closest('a'))setDocsOpen(false)});document.addEventListener('keydown',event=>{if(event.key==='Escape'&&document.body.classList.contains('docs-open')){setDocsOpen(false);docsToggle.focus()}})}

const hlEsc=s=>s.replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));
document.querySelectorAll('pre code[class*="language-"]').forEach(code=>{
 const lang=[...code.classList].find(x=>x.startsWith('language-'))?.slice(9), raw=code.textContent;
 const span=(cls,text)=>`<span class="${cls}">${hlEsc(text)}</span>`;
 if(lang==='ini'){
   code.innerHTML=raw.split('\n').map(line=>{
     if(/^\s*[#;]/.test(line))return span('tok-comment',line);
     if(/^\s*\[.*\]\s*$/.test(line))return span('tok-section',line);
     const m=line.match(/^([A-Za-z][A-Za-z0-9_-]*)(=)(.*)$/);
     return m?span('tok-key',m[1])+m[2]+hlEsc(m[3]):hlEsc(line);
   }).join('\n'); return;
 }
 const re=lang==='json'
   ? /"(?:\\.|[^"\\])*"(?=\s*:)|"(?:\\.|[^"\\])*"|\b(?:true|false|null)\b|-?\b\d+(?:\.\d+)?\b/g
   : /#[^\n]*|'[^'\n]*'|"(?:\\.|[^"\\])*"|--?[A-Za-z][\w-]*|\b(?:vant|sudo|install|mkdir|update-desktop-database|gtk-update-icon-cache|desktop-file-validate|command|pkg-config|make)\b/g;
 let out='',last=0;
 for(const m of raw.matchAll(re)){out+=hlEsc(raw.slice(last,m.index));const t=m[0];let cls='tok-keyword';
   if(lang==='json')cls=t.startsWith('"')?(raw.slice(m.index+m[0].length).match(/^\s*:/)?'tok-key':'tok-string'):(/^-?\d/.test(t)?'tok-number':'tok-keyword');
   else cls=t.startsWith('#')?'tok-comment':(t.startsWith("'")||t.startsWith('"'))?'tok-string':t.startsWith('-')?'tok-option':'tok-keyword';
   out+=span(cls,t);last=m.index+t.length;
 }
 code.innerHTML=out+hlEsc(raw.slice(last));
});
