let socket;
let relayStates = Array(8).fill(false);
let macros = Array.from({ length: 5 }, () => ({ name: "Empty", color: "white", active: false, relays: [], wake_pc: false, ac_on: false }));
let activeView = 'home';
let editingMacroIndex = -1;

let monthlyData = Array(31).fill(0.0);
let hourlyData = Array(24).fill(0.0);
let elecPrice = 3000.0;
let energyChart = null;
let dayChart = null;

function initCharts() {
    const ctxMonth = document.getElementById('energy-chart');
    if (ctxMonth && !energyChart) {
        energyChart = new Chart(ctxMonth, {
            type: 'bar',
            data: {
                labels: Array.from({length: 31}, (_, i) => i + 1),
                datasets: [{
                    label: 'kWh',
                    data: monthlyData,
                    backgroundColor: 'rgba(52, 211, 153, 0.5)',
                    borderColor: 'rgba(52, 211, 153, 1)',
                    borderWidth: 1,
                    borderRadius: 4
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.1)' }, ticks: { color: '#9ca3af' } },
                    x: { grid: { display: false }, ticks: { color: '#9ca3af', maxTicksLimit: 15 } }
                },
                plugins: { legend: { display: false } }
            }
        });
    }

    const ctxDay = document.getElementById('day-chart');
    if (ctxDay && !dayChart) {
        dayChart = new Chart(ctxDay, {
            type: 'line',
            data: {
                labels: Array.from({length: 24}, (_, i) => `${i}h`),
                datasets: [{
                    label: 'kWh',
                    data: hourlyData,
                    backgroundColor: 'rgba(96, 165, 250, 0.2)',
                    borderColor: 'rgba(96, 165, 250, 1)',
                    borderWidth: 2,
                    fill: true,
                    tension: 0.4,
                    pointRadius: (ctx) => {
                        // Draw a 4px dot only on the most recent valid data point
                        const idx = ctx.dataIndex;
                        const data = ctx.dataset.data;
                        return (data[idx] !== null && (idx === 23 || data[idx + 1] === null)) ? 4 : 0;
                    },
                    pointBackgroundColor: '#ffffff'
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                scales: {
                    y: { beginAtZero: true, grid: { color: 'rgba(255,255,255,0.1)' }, ticks: { color: '#9ca3af' } },
                    x: { grid: { display: false }, ticks: { color: '#9ca3af', maxTicksLimit: 12 } }
                },
                plugins: { legend: { display: false } }
            }
        });
    }
}

let tierPrices = [1984, 2380, 2998, 3571, 3967];
let tierLimits = [100, 200, 400, 700];

function calculateTieredCost(kwh) {
    let total = 0;
    let remaining = kwh;
    let prevLimit = 0;
    for (let i = 0; i < tierLimits.length; i++) {
        let tierUsage = Math.min(remaining, tierLimits[i] - prevLimit);
        if (tierUsage <= 0) break;
        total += tierUsage * tierPrices[i];
        remaining -= tierUsage;
        prevLimit = tierLimits[i];
    }
    if (remaining > 0) total += remaining * tierPrices[4];
    return total * 1.10; // 10% VAT
}

function updateGraphs() {
    if (energyChart) {
        energyChart.data.datasets[0].data = monthlyData;
        energyChart.update('none');
    }
    if (dayChart) {
        dayChart.data.datasets[0].data = hourlyData;
        dayChart.update('none');
    }
    
    let total = monthlyData.reduce((a, b) => a + b, 0);
    if(document.getElementById('graph-total-kwh')) document.getElementById('graph-total-kwh').innerText = total.toFixed(2);
    if(document.getElementById('graph-total-cost')) document.getElementById('graph-total-cost').innerText = Math.round(calculateTieredCost(total)).toLocaleString('vi-VN');
}

function initWebSocket() {
    const gateway = `ws://${window.location.host}/ws`;
    socket = new WebSocket(gateway);
    socket.onopen = () => {
        const status = document.getElementById('connection-status');
        if (status) status.classList.replace('bg-red-500', 'bg-green-500');
    };
    socket.onclose = () => {
        const status = document.getElementById('connection-status');
        if (status) status.classList.replace('bg-green-500', 'bg-red-500');
        setTimeout(initWebSocket, 2000);
    };
    socket.onmessage = (event) => {
        const data = JSON.parse(event.data);
        if (data.type === 'sync') handleSync(data);
    };
}

function handleSync(data) {
    if (data.pzem) {
        if(document.getElementById('pzem-voltage')) document.getElementById('pzem-voltage').innerText = data.pzem.v.toFixed(1) + 'V';
        if(document.getElementById('pzem-current')) document.getElementById('pzem-current').innerText = data.pzem.a.toFixed(2) + 'A';
        if(document.getElementById('pzem-power')) document.getElementById('pzem-power').innerText = data.pzem.w.toFixed(1) + 'W';
        if(document.getElementById('pzem-energy')) document.getElementById('pzem-energy').innerText = data.pzem.e.toFixed(2) + 'kWh';
        if(document.getElementById('pzem-frequency')) document.getElementById('pzem-frequency').innerText = data.pzem.hz.toFixed(1) + 'Hz';
        if(document.getElementById('pzem-pf')) document.getElementById('pzem-pf').innerText = data.pzem.pf.toFixed(2);
    }
    if (data.relays) {
        relayStates = data.relays;
        renderRelays();
    }
    if (data.ac) updateACUI(data.ac);
    if (data.macros) {
        macros = data.macros;
        renderMacros();
    }
    if (data.elecPrice !== undefined) elecPrice = data.elecPrice;
    if (data.tierPrices) tierPrices = data.tierPrices;
    if (data.monthly) {
        monthlyData = data.monthly;
        if(activeView === 'graph') updateGraphs();
    }
    if (data.hourly) {
        hourlyData = data.hourly;
        if(activeView === 'graph') updateGraphs();
    }
    if (data.pcOnline !== undefined) {
        const pcStatus = document.getElementById('pc-status');
        const pcIcon = document.getElementById('pc-icon-container');
        if (pcStatus && pcIcon) {
            if (data.pcOnline) {
                pcStatus.innerText = "Online";
                pcStatus.className = "absolute -bottom-2 bg-blue-600 px-4 py-1 rounded-full text-[10px] font-black uppercase";
                pcIcon.className = "w-32 h-32 bg-blue-900/30 rounded-full flex items-center justify-center mb-6 border-4 border-blue-500/20 relative transition-all";
            } else {
                pcStatus.innerText = "Offline";
                pcStatus.className = "absolute -bottom-2 bg-red-600 px-4 py-1 rounded-full text-[10px] font-black uppercase";
                pcIcon.className = "w-32 h-32 bg-blue-900/30 rounded-full flex items-center justify-center mb-6 border-4 border-red-500/20 relative transition-all";
            }
        }
    }
}

function showView(viewId) {
    document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
    const target = document.getElementById(`view-${viewId}`);
    if (target) target.classList.remove('hidden');
    document.querySelectorAll('.nav-btn').forEach(btn => {
        const isActive = btn.dataset.view === viewId;
        btn.classList.toggle('text-blue-500', isActive);
        btn.classList.toggle('text-gray-500', !isActive);
    });
    activeView = viewId;
    if(viewId === 'graph') {
        initCharts();
        updateGraphs();
    }
}

function renderRelays() {
    const grid = document.getElementById('relays-grid');
    if (!grid) return;
    grid.innerHTML = '';
    relayStates.forEach((state, i) => {
        const card = document.createElement('div');
        card.className = `bg-gray-800 p-6 rounded-3xl flex flex-col items-center justify-between shadow-xl border border-gray-700 transition-all ${state ? 'border-green-500/30 bg-green-900/10' : ''}`;
        card.innerHTML = `
            <span class="text-gray-500 font-bold mb-4 uppercase text-[10px] tracking-widest">Relay ${i + 1}</span>
            <label class="relative inline-flex items-center cursor-pointer">
                <input type="checkbox" class="sr-only peer" ${state ? 'checked' : ''} onchange="toggleRelay(${i})">
                <div class="w-14 h-7 bg-gray-700 peer-focus:outline-none rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-6 after:w-6 after:transition-all peer-checked:bg-green-600"></div>
            </label>
            <span class="mt-4 text-[10px] font-black uppercase ${state ? 'text-green-400' : 'text-gray-600'}">${state ? 'Active' : 'Standby'}</span>
        `;
        grid.appendChild(card);
    });
}

function toggleRelay(index) {
    socket.send(JSON.stringify({ type: 'relay_toggle', index: index }));
}

function toggleAllRelays(state) {
    socket.send(JSON.stringify({ type: 'relay_all', state: state }));
}

function updateACUI(ac) {
    const tempEl = document.getElementById('ac-status-temp');
    const modeEl = document.getElementById('ac-status-mode');
    const fanEl = document.getElementById('ac-status-fan');
    if (tempEl) tempEl.innerText = ac.temp + '°C';
    const modeMap = { 0: 'Auto', 2: 'Dry', 3: 'Cool', 4: 'Heat', 6: 'Fan' };
    const modeName = modeMap[ac.mode] || 'Unknown';
    if (modeEl) modeEl.innerText = modeName;
    const fanMap = { 0xA: 'Auto', 0xB: 'Silent', 1: '1', 2: '2', 3: '3', 4: '4', 5: '5' };
    const fanName = fanMap[ac.fan] || ac.fan;
    if (fanEl) fanEl.innerText = fanName;

    document.querySelectorAll('[onclick^="sendAC(\'mode_"]').forEach(btn => {
        const m = btn.getAttribute('onclick').split('_')[1].split('\'')[0];
        const isActive = (m === modeName.toLowerCase());
        btn.classList.toggle('bg-blue-600', isActive);
        btn.classList.toggle('bg-gray-700', !isActive);
    });
    document.querySelectorAll('[onclick^="sendAC(\'fan_"]').forEach(btn => {
        const f = btn.getAttribute('onclick').split('_')[1].split('\'')[0];
        const isActive = (f === fanName.toLowerCase());
        btn.classList.toggle('bg-yellow-600', isActive);
        btn.classList.toggle('bg-gray-700', !isActive);
    });

    const toggleBtn = (id, active) => {
        const btn = document.getElementById(id);
        if (btn) {
            btn.classList.toggle('bg-indigo-600', active);
            btn.classList.toggle('bg-gray-700', !active);
        }
    };
    toggleBtn('btn-swingv', ac.swingV);
    toggleBtn('btn-swingh', ac.swingH);
    toggleBtn('btn-powerful', ac.powerful);
    toggleBtn('btn-econo', ac.econo);
    toggleBtn('btn-quiet', ac.quiet);
    toggleBtn('btn-comfort', ac.comfort);

    const timerDisp = document.getElementById('timer-display');
    if (timerDisp) {
        if (ac.timer > 0) {
            const mins = Math.floor(ac.timer / 60);
            const secs = ac.timer % 60;
            timerDisp.innerText = `OFF in ${mins}:${secs.toString().padStart(2, '0')}`;
            timerDisp.classList.add('text-green-400');
        } else {
            timerDisp.innerText = "No active timer";
            timerDisp.classList.remove('text-green-400');
        }
    }

    const pwrBtn = document.querySelector('[onclick="sendAC(\'power_toggle\')"]');
    if (pwrBtn) {
        pwrBtn.classList.toggle('bg-green-600', ac.power);
        pwrBtn.classList.toggle('bg-red-600', !ac.power);
    }
}

function sendAC(cmd) {
    socket.send(JSON.stringify({ type: 'ac_cmd', cmd: cmd }));
}

function setTimer(mins) {
    socket.send(JSON.stringify({ type: 'ac_timer', minutes: parseInt(mins) }));
}

function saveACPreset() { socket.send(JSON.stringify({ type: 'ac_save_preset' })); }
function loadACPreset() { socket.send(JSON.stringify({ type: 'ac_load_preset' })); }

function controlPC(action) { socket.send(JSON.stringify({ type: 'pc_cmd', action: action })); }

function renderMacros() {
    const container = document.getElementById('macros-container');
    if (!container) return;
    container.innerHTML = '';
    macros.forEach((m, i) => {
        const btn = document.createElement('div');
        const colorClass = `bg-macro-${m.color || 'white'}`;
        btn.className = `macro-btn flex items-center justify-between p-6 rounded-3xl shadow-xl border-b-4 border-black/30 transition-all mb-4 ${colorClass} ${m.active ? 'ring-4 ring-white/50' : ''}`;
        btn.innerHTML = `
            <div class="flex-1 cursor-pointer" onclick="socket.send(JSON.stringify({ type: 'macro_toggle', index: ${i} }))">
                <div class="flex flex-col">
                    <span class="font-black text-xl text-gray-900">${m.name || 'Empty'}</span>
                    <span class="text-[9px] font-black uppercase text-gray-800 opacity-50">${m.active ? 'Running' : 'Ready'}</span>
                </div>
            </div>
            <button onclick="event.stopPropagation(); openMacroModal(${i})" class="bg-black/10 hover:bg-black/20 p-4 rounded-2xl text-[10px] font-black text-gray-900 tracking-widest ml-4 transition-all active:scale-90">
                EDIT
            </button>
        `;
        container.appendChild(btn);
    });
}

function openMacroModal(index) {
    const m = macros[index];
    editingMacroIndex = index;
    const nameInput = document.getElementById('macro-name-input');
    const colorInput = document.getElementById('macro-color-input');
    const wakePc = document.getElementById('macro-wake-pc');
    const acOn = document.getElementById('macro-ac-on');
    
    if (nameInput) nameInput.value = m.name || "";
    if (colorInput) colorInput.value = m.color || "white";
    if (wakePc) wakePc.checked = m.wake_pc || false;
    if (acOn) acOn.checked = m.ac_on || false;
    
    const relayList = document.getElementById('macro-relays-list');
    if (relayList) {
        relayList.innerHTML = '';
        for(let i=0; i<8; i++) {
            const checked = (m.relays && m.relays.includes(i)) ? 'checked' : '';
            relayList.innerHTML += `
                <label class="flex flex-col items-center p-3 bg-gray-900 rounded-2xl border border-gray-700 cursor-pointer transition-all active:scale-95">
                    <span class="text-[9px] font-bold mb-2">R${i+1}</span>
                    <input type="checkbox" class="macro-relay-check w-4 h-4 rounded peer" data-index="${i}" ${checked}>
                </label>
            `;
        }
    }

    const colors = ['white', 'red', 'blue', 'green', 'yellow', 'purple'];
    const colorPicker = document.getElementById('color-picker');
    if (colorPicker) {
        colorPicker.innerHTML = '';
        colors.forEach(c => {
            const div = document.createElement('div');
            div.className = `w-8 h-8 rounded-full cursor-pointer bg-macro-${c} border-2 ${m.color === c ? 'border-white' : 'border-transparent'} transition-all hover:scale-110`;
            div.onclick = () => {
                if (colorInput) colorInput.value = c;
                document.querySelectorAll('#color-picker div').forEach(d => d.classList.replace('border-white', 'border-transparent'));
                div.classList.replace('border-transparent', 'border-white');
            };
            colorPicker.appendChild(div);
        });
    }
    
    const modal = document.getElementById('macro-modal');
    if (modal) modal.classList.replace('hidden', 'flex');
}

function closeMacroModal() {
    const modal = document.getElementById('macro-modal');
    if (modal) modal.classList.replace('flex', 'hidden');
}

function saveMacroConfig() {
    const relays = [];
    document.querySelectorAll('.macro-relay-check').forEach(cb => { if(cb.checked) relays.push(parseInt(cb.dataset.index)); });
    socket.send(JSON.stringify({
        type: 'macro_config',
        index: editingMacroIndex,
        name: document.getElementById('macro-name-input').value,
        color: document.getElementById('macro-color-input').value,
        relays: relays,
        wake_pc: document.getElementById('macro-wake-pc').checked,
        ac_on: document.getElementById('macro-ac-on').checked
    }));
    closeMacroModal();
}

window.onload = () => { initWebSocket(); showView('home'); };
