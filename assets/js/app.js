const root = document.documentElement, btn = document.getElementById('themeBtn');
const paint = () => btn.innerHTML = root.dataset.bsTheme === 'dark' ? '<i class="bi bi-sun"></i> Light mode' : '<i class="bi bi-moon-stars"></i> Dark mode';
btn.onclick = () => { root.dataset.bsTheme = root.dataset.bsTheme === 'dark' ? 'light' : 'dark'; localStorage.setItem('theme', root.dataset.bsTheme); paint(); };
paint();
document.querySelectorAll('form[data-demo]').forEach(f => f.addEventListener('submit', e => { e.preventDefault(); bootstrap.Toast.getOrCreateInstance(document.getElementById('demoToast')).show(); }));
document.querySelectorAll('.wiz').forEach(w => {
  const s = [...w.querySelectorAll('.step')], p = [...w.querySelectorAll('.pill')], q = c => w.querySelector(c); let i = 0;
  const show = n => { i = n; s.forEach((e, k) => e.classList.toggle('d-none', k != i)); p.forEach((e, k) => e.classList.toggle('active', k <= i)); q('.prev').disabled = i == 0; q('.next').classList.toggle('d-none', i == s.length - 1); q('.done').classList.toggle('d-none', i != s.length - 1); };
  q('.next').onclick = () => { const bad = [...s[i].querySelectorAll('input,select,textarea')].find(x => !x.checkValidity()); if (bad) return bad.reportValidity(); show(i + 1); };
  q('.prev').onclick = () => show(i - 1); show(0);
});
