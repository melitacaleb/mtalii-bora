let csrf = '', user = null;
const $ = s => document.querySelector(s), app = $('#app');
const h = s => String(s ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
async function api(path, data) {
  const o = data === undefined ? {} : { method: 'POST', headers: { 'Content-Type': 'application/json', 'X-CSRF': csrf }, body: JSON.stringify(data) };
  const r = await fetch('/api' + path, o), j = await r.json();
  if (!r.ok) throw new Error(j.error || 'Error'); return j;
}
const form = f => Object.fromEntries(new FormData(f));
const on = (id, fn) => $(id).addEventListener('submit', async e => { e.preventDefault(); try { await fn(form(e.target)); } catch (x) { $(id + ' .err, #err').textContent = x.message; } });
const stars = r => r ? '★ ' + r : 'No reviews';
const badge = p => p.verified ? '<span class="badge ok">✔ Verified</span>' : '<span class="badge">Unverified</span>';

function nav() {
  $('#nav').innerHTML = '<a href="#/">Discover</a><a href="#/destinations">Destinations</a>' + (user
    ? `<a href="#/trips">My trips</a>${user.role === 'admin' ? '<a href="#/admin">Admin</a>' : ''}${/guide|driver/.test(user.role) ? '<a href="#/profile">My profile</a>' : ''}<a href="#" id="out">Logout (${h(user.name)})</a>`
    : '<a href="#/login">Login / Register</a>');
  $('#out')?.addEventListener('click', async e => { e.preventDefault(); await api('/logout', {}); await boot(); location.hash = '#/'; });
}
const views = {
  async home() {
    app.innerHTML = `<h2>Find a verified guide or safari driver</h2><form id="f" class="row"><input name="q" placeholder="Name, location, language">
      <select name="type"><option value="">Guides & drivers</option><option value="guide">Guides</option><option value="driver">Drivers</option></select>
      <label><input type="checkbox" name="verified" value="1"> Verified only</label><button>Search</button></form><div id="list" class="grid"></div>`;
    const load = async () => {
      const p = new URLSearchParams([...new FormData($('#f'))].filter(x => x[1])), r = await api('/providers?' + p);
      $('#list').innerHTML = r.map(p => `<div class="card"><b>${h(p.name)}</b> ${badge(p)}<div class="m">${p.type} · ${h(p.location)} · $${p.rate}/day</div>
        <div>${stars(p.rating)} (${p.reviews})</div><p>${h(p.bio)}</p><a href="#/provider/${p.id}">View profile →</a></div>`).join('') || '<p>No results.</p>';
    };
    $('#f').addEventListener('submit', e => { e.preventDefault(); load(); }); load();
  },
  async destinations() {
    const d = await api('/destinations');
    app.innerHTML = '<h2>Destinations</h2><div class="grid">' + d.map(x => `<div class="card"><b>${h(x.name)}</b> <span class="m">${h(x.region)}</span><p>${h(x.description)}</p><small>${h(x.activities)}</small></div>`).join('') + '</div>';
  },
  async provider(id) {
    const p = await api('/providers/' + id), d = new Date().toISOString().slice(0, 10);
    app.innerHTML = `<div class="card"><h2>${h(p.name)} ${badge(p)}</h2><div class="m">${p.type} · ${h(p.location)} · ${h(p.languages)} · $${p.rate}/day</div>
      <p>${h(p.bio)}</p>${p.vehicle ? `<p>Vehicle: ${h(p.vehicle)}</p>` : ''}</div>
      ${user?.role === 'traveler' ? `<form id="bk" class="card"><h3>Request booking</h3><div class="row"><label>From <input type="date" name="start_date" min="${d}" required></label>
        <label>To <input type="date" name="end_date" min="${d}" required></label></div><textarea name="note" placeholder="Tell them about your trip" rows="3" style="width:100%"></textarea>
        <p class="err" id="err"></p><button>Send request</button></form>` : '<p class="m">Login as a traveler to book.</p>'}
      <h3>Reviews</h3>${p.reviews.map(r => `<div class="card">★ ${r.rating} — ${h(r.name)}<br>${h(r.comment)}</div>`).join('') || '<p class="m">No reviews yet.</p>'}`;
    $('#bk') && on('#bk', async f => { const r = await api('/bookings', { ...f, provider_id: +id }); location.hash = '#/trip/' + r.id; });
  },
  async login() {
    app.innerHTML = `<div class="grid"><form id="lg" class="card"><h3>Login</h3><label>Email <input name="email" type="email" required></label>
      <label>Password <input name="password" type="password" required></label><p class="err" id="err"></p><button>Login</button>
      <p class="m">Demo: traveler@mtalii.test / Password123!</p></form>
      <form id="rg" class="card"><h3>Register</h3><label>Name <input name="name" required></label><label>Email <input name="email" type="email" required></label>
      <label>Password (8+) <input name="password" type="password" minlength="8" required></label>
      <label>I am a <select name="role"><option value="traveler">Traveler</option><option value="guide">Tour guide</option><option value="driver">Safari driver</option></select></label>
      <p class="err" id="err2"></p><button>Create account</button></form></div>`;
    const done = r => { csrf = r.csrf; user = r.user; nav(); location.hash = '#/'; };
    $('#lg').addEventListener('submit', async e => { e.preventDefault(); try { done(await api('/login', form(e.target))); } catch (x) { $('#err').textContent = x.message; } });
    $('#rg').addEventListener('submit', async e => { e.preventDefault(); try { done(await api('/register', form(e.target))); } catch (x) { $('#err2').textContent = x.message; } });
  },
  async trips() {
    if (!user) return location.hash = '#/login';
    const b = await api('/bookings');
    app.innerHTML = '<h2>My trips</h2>' + (b.map(x => `<a href="#/trip/${x.id}" class="card" style="display:block;color:inherit;text-decoration:none">
      <b>${h(user.role === 'traveler' ? x.provider : x.traveler)}</b> <span class="badge">${x.status}</span><div class="m">${x.start_date} → ${x.end_date}</div></a>`).join('') || '<p>No bookings yet.</p>');
  },
  async trip(id) {
    if (!user) return location.hash = '#/login';
    const [b, dest] = await Promise.all([api('/bookings/' + id), api('/destinations')]), mine = user.id === b.provider_user;
    const act = (s, l, alt) => `<button class="${alt ? 'alt' : ''}" data-s="${s}">${l}</button>`;
    app.innerHTML = `<div class="card"><h2>Booking #${b.id} <span class="badge">${b.status}</span></h2><div class="m">${b.start_date} → ${b.end_date}</div><p>${h(b.note)}</p>
      <div class="row">${mine && b.status === 'pending' ? act('accepted', 'Accept') + act('rejected', 'Reject', 1) : ''}${mine && b.status === 'accepted' ? act('completed', 'Mark completed') : ''}
      ${!mine && /pending|accepted/.test(b.status) ? act('cancelled', 'Cancel booking', 1) : ''}</div></div>
      <div class="card"><h3>Itinerary</h3>${b.items.map(i => `<div class="row"><span>Day ${i.day} ${h(i.time)}</span><b>${h(i.title)}</b><span class="m">${h(i.destination || '')} ${h(i.notes)}</span><button class="alt" data-del="${i.id}">✕</button></div>`).join('') || '<p class="m">Nothing planned yet.</p>'}
      <form id="it" class="row"><input name="day" type="number" min="1" value="1" style="width:70px"><input name="time" type="time"><input name="title" placeholder="Activity" required>
      <select name="destination_id"><option value="">Destination</option>${dest.map(d => `<option value="${d.id}">${h(d.name)}</option>`).join('')}</select><input name="notes" placeholder="Notes"><button>Add</button></form><p class="err" id="err"></p></div>
      <div class="card"><h3>Messages</h3>${b.messages.map(m => `<div class="msg"><b>${h(m.name)}</b>: ${h(m.body)}</div>`).join('')}
      <form id="ms" class="row"><input name="body" placeholder="Write a message" style="flex:1" required><button>Send</button></form></div>
      ${b.status === 'completed' && !mine ? (b.review ? `<div class="card">Your review: ★ ${b.review.rating} ${h(b.review.comment)}</div>` :
        `<form id="rv" class="card"><h3>Leave a review</h3><select name="rating">${[5, 4, 3, 2, 1].map(n => `<option>${n}</option>`).join('')}</select><input name="comment" placeholder="Comment"><button>Submit</button></form>`) : ''}`;
    const reload = () => views.trip(id), run = fn => async (...a) => { try { await fn(...a); reload(); } catch (x) { $('#err').textContent = x.message; } };
    app.querySelectorAll('[data-s]').forEach(el => el.onclick = run(() => api(`/bookings/${id}/status`, { status: el.dataset.s })));
    app.querySelectorAll('[data-del]').forEach(el => el.onclick = run(() => api(`/items/${el.dataset.del}/delete`, {})));
    [['#it', 'items'], ['#ms', 'messages'], ['#rv', 'review']].forEach(([s, p]) => $(s)?.addEventListener('submit', e => { e.preventDefault(); run(() => api(`/bookings/${id}/${p}`, form(e.target)))(); }));
  },
  async profile() {
    const p = await api('/provider/profile');
    app.innerHTML = `<h2>My provider profile ${badge(p)}</h2><form id="pf" class="card"><label>Bio <textarea name="bio" rows="3" style="width:100%">${h(p.bio)}</textarea></label>
      <label>Location <input name="location" value="${h(p.location)}"></label><label>Languages <input name="languages" value="${h(p.languages)}"></label>
      <label>Daily rate (USD) <input name="rate" type="number" value="${p.rate}"></label>${p.type === 'driver' ? `<label>Vehicle <input name="vehicle" value="${h(p.vehicle)}"></label>` : ''}
      <label>Licence / certificate no. (changing it resets verification) <input name="license_no" value="${h(p.license_no)}"></label><p class="err" id="err"></p><button>Save</button></form>`;
    on('#pf', async f => { await api('/provider/profile', f); $('#err').textContent = 'Saved. An admin will review your verification.'; });
  },
  async admin() {
    if (user?.role !== 'admin') return location.hash = '#/';
    const [ps, log] = await Promise.all([api('/providers'), api('/admin/audit')]);
    app.innerHTML = `<h2>Provider verification</h2>${ps.map(p => `<div class="card row"><b>${h(p.name)}</b><span class="m">${p.type} · licence: ${h(p.license_no) || '—'}</span>${badge(p)}
      <button data-v="${p.id}" data-on="${p.verified ? 0 : 1}">${p.verified ? 'Revoke' : 'Verify'}</button></div>`).join('')}
      <h2>Audit log</h2><div class="card" style="overflow:auto"><table width="100%">${log.map(l => `<tr><td>${l.created}</td><td>${h(l.email || '-')}</td><td>${h(l.action)}</td><td>${h(l.detail)}</td><td>${h(l.ip)}</td></tr>`).join('')}</table></div>`;
    app.querySelectorAll('[data-v]').forEach(b => b.onclick = async () => { await api(`/admin/providers/${b.dataset.v}/verify`, { verified: +b.dataset.on }); views.admin(); });
  }
};
async function route() {
  const [, name, arg] = location.hash.replace('#', '').split('/');
  try { await (views[name || 'home'] || views.home)(arg); } catch (e) { app.innerHTML = `<p class="err">${h(e.message)}</p>`; }
}
async function boot() { const r = await api('/me'); user = r.user; csrf = r.csrf; nav(); }
window.addEventListener('hashchange', route);
boot().then(route);
