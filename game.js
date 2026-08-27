const fmt = new Intl.NumberFormat('pl-PL');

const RESOURCES = {
  mixed:   { name: 'Złom mieszany', color: '#77766d', icon: '⚙️' },
  steel:   { name: 'Stal', color: '#82909a', icon: '🔩' },
  copper:  { name: 'Miedź', color: '#c47445', icon: '🟠' },
  plastic: { name: 'Tworzywa', color: '#4e8c77', icon: '♻️' }
};

const BUILDINGS = {
  sorter: { name: 'Sortownia', icon: '🏗️', cost: 900, note: '+1 stanowisko pracy' },
  warehouse: { name: 'Magazyn', icon: '🏚️', cost: 750, note: '+50 t pojemności' },
  crusher: { name: 'Prasa', icon: '⚙️', cost: 1400, note: '+20% ceny stali' }
};

const game = {
  day: 1, minute: 7 * 60, cash: 2500, reputation: 0, workers: 1,
  paused: false, speed: 1, capacity: 80, selectedBuilding: null,
  inventory: { mixed: 0, steel: 0, copper: 0, plastic: 0 },
  prices: { steel: 145, copper: 520, plastic: 90 },
  previousPrices: { steel: 140, copper: 500, plastic: 95 },
  buildings: Array(20).fill(null), offers: [], processing: 0,
  contract: { resource: 'steel', target: 25, delivered: 0, reward: 1100 },
  soldTotal: 0
};

game.buildings[0] = 'office';
game.buildings[6] = 'sorter';
game.buildings[19] = 'locked';

const $ = id => document.getElementById(id);
const totalStock = () => Object.values(game.inventory).reduce((a, b) => a + b, 0);
const countBuilding = type => game.buildings.filter(b => b === type).length;
const money = n => `${fmt.format(Math.round(n))} zł`;

function createOffers() {
  const names = ['Stare AGD', 'Wrak dostawczaka', 'Rozbiórka warsztatu', 'Kontener z fabryki', 'Likwidacja magazynu'];
  game.offers = Array.from({ length: 3 }, () => {
    const tons = Math.floor(8 + Math.random() * 13);
    return {
      name: names[Math.floor(Math.random() * names.length)],
      tons,
      quality: Math.round(55 + Math.random() * 25),
      cost: Math.round(tons * (38 + Math.random() * 15)),
      bought: false
    };
  });
}

function render() {
  $('day').textContent = game.day;
  const hours = Math.floor(game.minute / 60);
  const mins = Math.floor(game.minute % 60);
  $('clock').textContent = `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}`;
  $('cash').textContent = money(game.cash);
  $('reputation').textContent = `${game.reputation} ★`;
  $('workerCount').textContent = `${game.workers} ${game.workers === 1 ? 'pracownik' : 'pracowników'}`;
  $('wages').textContent = `${game.workers * 80} zł / dzień`;
  $('hireBtn').disabled = game.cash < 300;
  $('capacity').textContent = `${totalStock().toFixed(1)} / ${game.capacity} t`;
  $('dayProgress').style.width = `${Math.max(0, Math.min(100, (game.minute - 420) / 7.8))}%`;
  renderOffers(); renderInventory(); renderMarket(); renderBuildings(); renderYard(); renderContract();
}

function renderOffers() {
  $('offers').innerHTML = game.offers.map((o, i) => `
    <div class="offer ${o.bought || game.cash < o.cost || totalStock() + o.tons > game.capacity ? 'disabled' : ''}" data-offer="${i}">
      <h3>${o.name}</h3><span class="offer-price">${money(o.cost)}</span>
      <p>${o.tons} ton • jakość ${o.quality}%</p>
    </div>`).join('');
  document.querySelectorAll('[data-offer]').forEach(el => el.onclick = () => buyOffer(+el.dataset.offer));
}

function renderInventory() {
  $('inventory').innerHTML = Object.entries(RESOURCES).map(([key, r]) => `
    <div class="inventory-row"><span class="resource-dot" style="background:${r.color}"></span><span>${r.name}</span><strong>${game.inventory[key].toFixed(1)} t</strong></div>`).join('');
}

function renderMarket() {
  $('market').innerHTML = ['steel','copper','plastic'].map(key => {
    const up = game.prices[key] >= game.previousPrices[key];
    return `<div class="market-row"><span class="resource-dot" style="background:${RESOURCES[key].color}"></span><span>${RESOURCES[key].name}<br><b>${money(game.prices[key])}</b></span><span class="trend ${up?'up':'down'}">${up?'▲':'▼'}</span><button class="sell" data-sell="${key}" ${game.inventory[key] < .1 ? 'disabled':''}>SPRZEDAJ 1 t</button></div>`;
  }).join('');
  document.querySelectorAll('[data-sell]').forEach(el => el.onclick = () => sell(el.dataset.sell));
}

function renderBuildings() {
  $('buildings').innerHTML = Object.entries(BUILDINGS).map(([key, b]) => `
    <div class="building-card ${game.selectedBuilding === key ? 'selected':''} ${game.cash < b.cost ? 'disabled':''}" data-building="${key}">
      <span class="building-icon">${b.icon}</span><div><strong>${b.name}</strong><small>${b.note}</small></div><b>${money(b.cost)}</b>
    </div>`).join('');
  document.querySelectorAll('[data-building]').forEach(el => el.onclick = () => selectBuilding(el.dataset.building));
}

function renderYard() {
  $('yard').innerHTML = game.buildings.map((type, i) => {
    if (!type) return `<div class="tile buildable" data-tile="${i}"><span class="tile-icon">＋</span><strong>Wolny plac</strong></div>`;
    if (type === 'locked') return `<div class="tile locked"><span class="tile-icon">🔒</span><strong>Teren sąsiada</strong><small>Wkrótce</small></div>`;
    if (type === 'office') return `<div class="tile office"><span class="tile-icon">🏢</span><strong>Biuro</strong><small>Poziom 1</small></div>`;
    const b = BUILDINGS[type];
    const progress = type === 'sorter' && game.inventory.mixed > 0 ? game.processing * 100 : 0;
    return `<div class="tile ${type}"><span class="tile-icon">${b.icon}</span><strong>${b.name}</strong><small>${type === 'sorter' ? 'Przerób: '+(game.workers*0.6).toFixed(1)+' t/h' : b.note}</small><span class="activity" style="width:${progress}%"></span></div>`;
  }).join('');
  document.querySelectorAll('[data-tile]').forEach(el => el.onclick = () => placeBuilding(+el.dataset.tile));
}

function renderContract() {
  const c = game.contract, pct = Math.min(100, c.delivered / c.target * 100);
  $('contract').innerHTML = `<strong>Huta „Iskra”</strong><p>Dostarcz ${c.target} t stali. Pozostało ${(c.target-c.delivered).toFixed(1)} t.<br>Nagroda: ${money(c.reward)} + 2 ★</p><div class="contract-progress"><span style="width:${pct}%"></span></div>`;
}

function buyOffer(i) {
  const o = game.offers[i];
  if (o.bought || game.cash < o.cost) return toast('Brakuje gotówki.');
  if (totalStock() + o.tons > game.capacity) return toast('Brakuje miejsca w magazynie.');
  game.cash -= o.cost; game.inventory.mixed += o.tons; o.bought = true;
  setStatus(`Przyjęto dostawę „${o.name}”. Sortownia rusza do pracy.`); toast(`Dostawa: +${o.tons} t złomu`); render();
}

function sell(key) {
  if (game.inventory[key] < .1) return;
  const amount = Math.min(1, game.inventory[key]);
  const bonus = key === 'steel' && countBuilding('crusher') ? 1.2 : 1;
  game.inventory[key] -= amount; game.cash += game.prices[key] * bonus * amount; game.soldTotal += amount;
  if (key === game.contract.resource) {
    game.contract.delivered += amount;
    if (game.contract.delivered >= game.contract.target) completeContract();
  }
  setStatus(`Sprzedano ${amount.toFixed(1)} t: ${RESOURCES[key].name}.`); render();
}

function completeContract() {
  game.cash += game.contract.reward; game.reputation += 2;
  toast(`Zlecenie ukończone! +${money(game.contract.reward)}`);
  const targets = [30, 40, 55]; const target = targets[Math.floor(Math.random()*targets.length)];
  game.contract = { resource: 'steel', target, delivered: 0, reward: target * 48 };
}

function selectBuilding(key) {
  const b = BUILDINGS[key];
  if (game.cash < b.cost) return toast('Brakuje gotówki na budowę.');
  game.selectedBuilding = game.selectedBuilding === key ? null : key;
  setStatus(game.selectedBuilding ? `Wybierz wolne pole dla: ${b.name}.` : 'Anulowano budowę.'); render();
}

function placeBuilding(i) {
  if (!game.selectedBuilding) return toast('Najpierw wybierz budynek z prawego panelu.');
  const type = game.selectedBuilding, b = BUILDINGS[type];
  if (game.cash < b.cost || game.buildings[i]) return;
  game.cash -= b.cost; game.buildings[i] = type; game.selectedBuilding = null;
  if (type === 'warehouse') game.capacity += 50;
  setStatus(`Budowa ukończona: ${b.name}.`); toast(`${b.name} gotowa do pracy!`); render();
}

function processScrap(deltaMinutes) {
  const sorters = countBuilding('sorter');
  if (!sorters || !game.workers || game.inventory.mixed <= 0) return;
  const amount = Math.min(game.inventory.mixed, sorters * game.workers * 0.6 * deltaMinutes / 60);
  game.inventory.mixed -= amount;
  game.inventory.steel += amount * .68;
  game.inventory.copper += amount * .09;
  game.inventory.plastic += amount * .18;
  game.processing = (game.processing + deltaMinutes / 25) % 1;
}

function nextDay() {
  game.day++; game.minute = 7 * 60;
  const wages = game.workers * 80;
  game.cash -= wages;
  game.previousPrices = {...game.prices};
  game.prices.steel = Math.round(115 + Math.random() * 70);
  game.prices.copper = Math.round(420 + Math.random() * 190);
  game.prices.plastic = Math.round(65 + Math.random() * 65);
  createOffers();
  setStatus(`Nowy dzień. Wypłacono pensje: ${money(wages)}. Rynek zmienił ceny.`);
  if (game.cash < 0) toast('Uwaga: konto jest na minusie!');
}

function setStatus(text) { $('statusText').textContent = text; }
let toastTimer;
function toast(text) { const el = $('toast'); el.textContent = text; el.classList.add('show'); clearTimeout(toastTimer); toastTimer = setTimeout(() => el.classList.remove('show'), 1800); }

$('hireBtn').onclick = () => {
  if (game.cash < 300) return;
  game.cash -= 300; game.workers++;
  setStatus('Nowy sortowacz dołączył do załogi.'); toast('Zatrudniono pracownika'); render();
};
$('pauseBtn').onclick = () => { game.paused = !game.paused; $('pauseBtn').textContent = game.paused ? '▶' : 'Ⅱ'; };
document.querySelectorAll('[data-speed]').forEach(btn => btn.onclick = () => {
  game.speed = +btn.dataset.speed; game.paused = false; $('pauseBtn').textContent = 'Ⅱ';
  document.querySelectorAll('[data-speed]').forEach(b => b.classList.toggle('active', b === btn));
});

createOffers(); render();
let last = performance.now();
let uiAccumulator = 0;
function loop(now) {
  const elapsed = Math.min(1000, now-last); last = now;
  if (!game.paused) {
    const deltaMinutes = elapsed / 1000 * game.speed * 3;
    game.minute += deltaMinutes; processScrap(deltaMinutes);
    if (game.minute >= 20 * 60) nextDay();
    uiAccumulator += elapsed;
    if (uiAccumulator >= 100) {
      uiAccumulator = 0;
      render();
    }
  }
  requestAnimationFrame(loop);
}
requestAnimationFrame(loop);
