import { parseAuthHeader } from './auth';
import { getDeterministicCard, getWeightedRandomCard, getDeterministicReversed, getWeeklyDeterministicCard, getWeeklyDeterministicReversed } from './tarot';
import { getWetonInsight, getPranataMangsaId, getJamInsight } from './weton';

const CORS_HEADERS: Record<string, string> = {
	'Access-Control-Allow-Origin': '*',
	'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
	'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

function json(data: unknown, status = 200): Response {
	return new Response(JSON.stringify(data), {
		status,
		headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
	});
}

export async function handleRequest(request: Request): Promise<Response> {
	const url = new URL(request.url);
	const { pathname } = url;
	const method = request.method;

	// CORS preflight
	if (method === 'OPTIONS') {
		return new Response(null, { status: 204, headers: CORS_HEADERS });
	}

	// Routes
	if (method === 'GET' && pathname === '/api/health') {
		return json({ status: 'ok', version: '0.1.0' });
	}

	if (method === 'POST' && pathname === '/api/tarot/draw') {
		return handleTarotDraw(request);
	}

	if (method === 'POST' && pathname === '/api/weton/daily') {
		return handleWetonDaily(request);
	}

	if (method === 'POST' && pathname === '/api/calendar/month') {
		return handleCalendarMonth(request);
	}

	return json({ error: 'Not Found' }, 404);
}

// --- Tarot Draw Handler ---

interface TarotDrawBody {
	birthDate?: string;
	pangarasan?: string;
	wukuHariIni?: string;
	drawType?: 'birth' | 'weekly';
}

async function handleTarotDraw(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

	let body: TarotDrawBody;
	try {
		body = (await request.json()) as TarotDrawBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required' }, 400);
	}

	const drawType = body.drawType ?? (authToken.type === 'guest' ? 'birth' : 'weekly');

	if (authToken.type === 'guest' || drawType === 'birth') {
		const cardIndex = getDeterministicCard(body.birthDate, body.pangarasan);
		const isReversed = getDeterministicReversed(body.birthDate);
		return json({
			success: true,
			isDynamic: false,
			drawType: 'birth',
			cardIndex,
			isReversed,
			message: 'Kartu Jiwa (Soul Card) — penafsiran statis seumur hidup.',
		});
	}

	// Bearer (registered user) and drawType === 'weekly'
	const cardIndex = getWeeklyDeterministicCard(
		body.birthDate,
		body.wukuHariIni ?? '',
		body.pangarasan ?? '',
	);
	const isReversed = getWeeklyDeterministicReversed(
		body.birthDate,
		body.wukuHariIni ?? '',
	);
	return json({
		success: true,
		isDynamic: true,
		drawType: 'weekly',
		cardIndex,
		isReversed,
		message: 'Kartu Tarot Mingguan — dinamis berdasarkan siklus Wuku.',
	});
}

// --- Weton Daily Handler ---

interface WetonDailyBody {
	birthDate?: string;
	targetDate?: string;
}

async function handleWetonDaily(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

	let body: WetonDailyBody;
	try {
		body = (await request.json()) as WetonDailyBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate) {
		return json({ error: 'birthDate is required' }, 400);
	}

	const { birthDate, targetDate } = body;

	if (authToken.type === 'guest') {
		const data = getWetonInsight(birthDate, birthDate);
		return json({
			success: true,
			isDynamic: false,
			data,
		});
	}

	// Bearer (registered user)
	const target = targetDate || new Date().toISOString().split('T')[0];
	const data = getWetonInsight(birthDate, target);
	return json({
		success: true,
		isDynamic: true,
		data,
	});
}

// --- Calendar Month Handler ---

interface CalendarMonthBody {
	birthDate?: string;
	targetYear?: number;
	targetMonth?: number;
}

const MANGSA_THEMES: Record<number, { nama: string; candra: string; tema: string }> = {
	1: { nama: 'Kasa', candra: 'Sotya murca saking embanan', tema: 'Ego-Death & Decluttering' },
	2: { nama: 'Karo', candra: 'Bantala rengka', tema: 'Vulnerability & Resilience' },
	3: { nama: 'Katiga', candra: 'Suta manut ing bapa', tema: 'Mentorship & Disiplin' },
	4: { nama: 'Kapat', candra: 'Waspa kumembeng jroning kalbu', tema: 'Emotional Healing & Transisi' },
	5: { nama: 'Kalima', candra: 'Pancuran emas sumawur ing jagat', tema: 'Abundance & Peluang' },
	6: { nama: 'Kanem', candra: 'Rasa mulya kasucen', tema: 'Maturitas & Flow' },
	7: { nama: 'Kapitu', candra: 'Wisa kentar ing maruta', tema: 'Cozy Cocooning & Boundaries' },
	8: { nama: 'Kawolu', candra: 'Anjrah jroning kayun', tema: 'Passion & Kolaborasi' },
	9: { nama: 'Kasanga', candra: 'Wedharing wacana mulya', tema: 'Ekspresi Diri & Sharing' },
	10: { nama: 'Kasepuluh', candra: 'Gedhong mineb jroning kalbu', tema: 'Financial & Security' },
	11: { nama: 'Dhesta', candra: 'Sotya sinar angrengga wicara', tema: 'Apresiasi & Perlambatan' },
	12: { nama: 'Sada', candra: 'Tirta sah saking sasana', tema: 'Detachment & Refleksi' },
};

async function handleCalendarMonth(request: Request): Promise<Response> {
	const authToken = parseAuthHeader(request.headers.get('Authorization'));
	if (!authToken) {
		return json({ error: 'Authorization header required' }, 400);
	}

	let body: CalendarMonthBody;
	try {
		body = (await request.json()) as CalendarMonthBody;
	} catch {
		return json({ error: 'Invalid JSON body' }, 400);
	}

	if (!body.birthDate || !body.targetYear || !body.targetMonth) {
		return json({ error: 'birthDate, targetYear, and targetMonth are required' }, 400);
	}

	const { birthDate, targetYear, targetMonth } = body;

	// Calculate active Pranata Mangsa of the selected month (using 15th as midpoint representation)
	const midPranataId = getPranataMangsaId(targetYear, targetMonth, 15);
	const theme = MANGSA_THEMES[midPranataId];

	// Determine total days in target month
	const totalDays = new Date(targetYear, targetMonth, 0).getDate();

	const daysList = [];

	for (let d = 1; d <= totalDays; d++) {
		const dateStr = `${targetYear}-${targetMonth.toString().padStart(2, '0')}-${d.toString().padStart(2, '0')}`;

		const insight = getWetonInsight(birthDate, dateStr);

		const sisaBagiVal = insight.daily.sisaBagi;
		let vibeWarna = 'blue';
		let saranSingkat = '';
		let tingkatEnergi = 'Stabil';

		switch (sisaBagiVal) {
			case 1:
				vibeWarna = 'blue';
				tingkatEnergi = 'Tinggi';
				saranSingkat = 'Hari baik untuk bersosialisasi dan memperkuat branding diri.';
				break;
			case 2:
				vibeWarna = 'green';
				tingkatEnergi = 'Stabil';
				saranSingkat = 'Sangat bagus untuk transaksi bisnis, belajar, dan melatih fokus.';
				break;
			case 3:
				vibeWarna = 'gold';
				tingkatEnergi = 'Tinggi';
				saranSingkat = 'Ideal untuk memulai kebiasaan baru atau investasi jangka panjang.';
				break;
			case 4:
				vibeWarna = 'orange';
				tingkatEnergi = 'Waspada';
				saranSingkat = 'Energi tubuh menurun. Tidur cukup dan hindari kelelahan fisik.';
				break;
			case 0:
				vibeWarna = 'purple';
				tingkatEnergi = 'Waspada';
				saranSingkat = 'Momen refleksi batin. Tunda keputusan penting, hindari konfrontasi.';
				break;
		}

		// Map timetable from jamBaik & jamNaas
		const jamBaikParsed = insight.daily.jamBaik.map(item => {
			const match = item.match(/^([\d: -]+)\s*\(([^)]+)\)$/);
			const range = match ? match[1].trim() : '06:00 - 08:24';
			const label = match ? match[2].trim() : 'Jam Rahayu';
			
			let rekomendasi = 'Ikuti alur energi harian dengan penuh kesadaran.';
			if (label.includes('Rezeki')) {
				rekomendasi = 'Sangat baik untuk memulai negosiasi, mempromosikan ide, dan urusan finansial.';
			} else if (label.includes('Gedhong')) {
				rekomendasi = 'Sempurna untuk merencanakan investasi, menata ruang kerja, atau menandatangani kontrak.';
			}
			return { range, label, rekomendasi };
		});

		const jamNaasParsed = insight.daily.jamNaas.map(item => {
			const match = item.match(/^([\d: -]+)\s*\(([^)]+)\)$/);
			const range = match ? match[1].trim() : '08:24 - 10:48';
			const label = match ? match[2].trim() : 'Jam Waspada';
			
			let rekomendasi = 'Fase energi rawan. Hindari perdebatan dan tunda keputusan krusial.';
			if (label.includes('Loro')) {
				rekomendasi = 'Periode rentan stres. Kurangi intensitas kerja, lakukan meditasi atau istirahat sejenak.';
			} else if (label.includes('Pati')) {
				rekomendasi = 'Fase pelepasan ego. Fokus pada evaluasi diri mandiri, tunda peluncuran besar.';
			}
			return { range, label, rekomendasi };
		});

		daysList.push({
			date: dateStr,
			weton_hari_ini: `${insight.targetWeton.saptawara} ${insight.targetWeton.pancawara}`,
			wuku: insight.targetWeton.wuku,
			neptu: insight.targetWeton.totalNeptu,
			pancasuda: {
				sisa_bagi: sisaBagiVal,
				fase: insight.daily.fase,
				tingkat_energi: tingkatEnergi,
				vibe_warna: vibeWarna,
				saran_singkat: saranSingkat,
			},
			timetable: {
				jam_baik: jamBaikParsed,
				jam_naas: jamNaasParsed,
			}
		});
	}

	return json({
		target_year: targetYear,
		target_month: targetMonth,
		pranata_mangsa: {
			id: midPranataId,
			nama_mangsa: theme.nama,
			candra: theme.candra,
			tema_makro: theme.tema,
		},
		days: daysList,
	});
}
