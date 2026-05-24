<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Drivly — Rent any car, anywhere. Drive smarter.</title>
    <meta name="description" content="Drivly is the peer-to-peer car rental marketplace. Discover thousands of cars near you, book in 60 seconds, unlock with your phone.">
    <meta property="og:title" content="Drivly — Drive smarter.">
    <meta property="og:description" content="Peer-to-peer car rental, reimagined. Book in 60 seconds.">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&family=Space+Grotesk:wght@500;600;700&family=JetBrains+Mono:wght@500;600&display=swap" rel="stylesheet">
    <style>
        :root {
            --bg: #0B0D14;
            --surface: #14171F;
            --surface2: #1B1F2A;
            --border: #262A36;
            --fg: #F4F5F7;
            --muted: #8A8F9C;
            --primary: #CBF24A;
            --primary-glow: #E4FF7A;
            --primary-fg: #0B0D14;
            --accent: #7C5CFF;
            --display: 'Space Grotesk', system-ui, sans-serif;
            --body: 'Inter', system-ui, sans-serif;
            --mono: 'JetBrains Mono', ui-monospace, monospace;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        html { scroll-behavior: smooth; }
        body {
            background: var(--bg);
            color: var(--fg);
            font-family: var(--body);
            line-height: 1.5;
            -webkit-font-smoothing: antialiased;
            overflow-x: hidden;
        }
        a { color: inherit; text-decoration: none; }
        .display { font-family: var(--display); font-weight: 700; letter-spacing: -0.02em; }
        .mono { font-family: var(--mono); }
        .wrap { max-width: 1200px; margin: 0 auto; padding: 0 24px; }
        .muted { color: var(--muted); }
        .accent { color: var(--primary); }
        .eyebrow { font-family: var(--mono); font-size: 12px; letter-spacing: 0.18em; text-transform: uppercase; color: var(--primary); margin-bottom: 12px; }
        .btn {
            display: inline-flex; align-items: center; gap: 8px; cursor: pointer;
            border: none; border-radius: 999px; font-weight: 600; font-family: var(--body);
            font-size: 15px; padding: 14px 28px; transition: transform .2s ease, box-shadow .2s ease, background .2s ease;
        }
        .btn-primary { background: var(--primary); color: var(--primary-fg); box-shadow: 0 12px 40px rgba(203,242,74,.25); }
        .btn-primary:hover { transform: translateY(-2px); box-shadow: 0 0 50px rgba(203,242,74,.5); }
        .btn-ghost { background: rgba(27,31,42,.6); color: var(--fg); border: 1px solid var(--border); }
        .btn-ghost:hover { background: var(--surface2); }
        svg.ico { width: 20px; height: 20px; stroke: currentColor; fill: none; stroke-width: 1.8; stroke-linecap: round; stroke-linejoin: round; }

        /* NAV */
        header.nav { position: fixed; top: 0; left: 0; right: 0; z-index: 50; transition: background .3s, border-color .3s; border-bottom: 1px solid transparent; }
        header.nav.scrolled { background: rgba(11,13,20,.8); backdrop-filter: blur(18px); border-bottom-color: var(--border); }
        .nav-inner { height: 68px; display: flex; align-items: center; justify-content: space-between; }
        .brand { font-family: var(--display); font-weight: 700; font-size: 22px; background: none; border: none; color: var(--fg); cursor: pointer; }
        .brand .dot { color: var(--primary); }
        .nav-links { display: flex; gap: 32px; align-items: center; }
        .nav-links a { font-size: 14px; color: var(--muted); transition: color .2s; }
        .nav-links a:hover { color: var(--fg); }
        .nav-cta { display: flex; gap: 12px; align-items: center; }
        .menu-btn { display: none; background: none; border: none; color: var(--fg); cursor: pointer; padding: 8px; }
        #mobileMenu { display: none; background: rgba(11,13,20,.97); backdrop-filter: blur(18px); border-bottom: 1px solid var(--border); padding: 16px 24px 24px; }
        #mobileMenu a { display: block; padding: 12px 0; color: var(--fg); font-size: 16px; }

        /* HERO */
        .hero { position: relative; min-height: 100vh; padding: 150px 0 80px; overflow: hidden;
            background: linear-gradient(135deg, #16213B 0%, var(--bg) 55%, #0E1A14 100%); }
        .blob { position: absolute; border-radius: 50%; filter: blur(80px); pointer-events: none; }
        .blob1 { top: 80px; left: -160px; width: 500px; height: 500px; background: rgba(203,242,74,.22); animation: pulse 6s ease-in-out infinite; }
        .blob2 { bottom: 0; right: -80px; width: 600px; height: 600px; background: rgba(124,92,255,.18); }
        @keyframes pulse { 0%,100% { opacity: .8; } 50% { opacity: .4; } }
        .grid-overlay { position: absolute; inset: 0; opacity: .06; pointer-events: none;
            background-image: linear-gradient(var(--fg) 1px, transparent 1px), linear-gradient(90deg, var(--fg) 1px, transparent 1px);
            background-size: 60px 60px; }
        .hero-inner { position: relative; }
        .badge { display: inline-flex; align-items: center; gap: 8px; padding: 6px 14px; border-radius: 999px;
            background: rgba(20,23,31,.6); border: 1px solid var(--border); font-family: var(--mono); font-size: 12px; color: var(--muted); margin-bottom: 24px; }
        .badge .ping { width: 7px; height: 7px; border-radius: 50%; background: var(--primary); animation: pulse 1.6s infinite; }
        h1.hero-title { font-size: clamp(48px, 9vw, 104px); line-height: .92; max-width: 920px; }
        h1.hero-title .u { position: relative; color: var(--primary); }
        h1.hero-title .u::after { content: ''; position: absolute; left: 0; right: 0; bottom: -6px; height: 4px; background: var(--primary); border-radius: 999px; }
        .hero p.lede { color: var(--muted); font-size: clamp(16px, 2.2vw, 20px); margin-top: 28px; max-width: 560px; }
        .hero-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 36px; }
        .hero-visual { margin-top: 64px; position: relative; }
        .hero-visual .glow { position: absolute; left: 0; right: 0; bottom: -32px; height: 160px; background: rgba(203,242,74,.28); filter: blur(80px); border-radius: 50%; }
        .hero-card { position: relative; max-width: 960px; margin: 0 auto; border-radius: 28px; border: 1px solid var(--border);
            box-shadow: 0 30px 80px rgba(0,0,0,.5); overflow: hidden; }
        .hero-card img { display: block; width: 100%; height: auto; }
        .hero-car-svg { width: 56%; opacity: .85; }
        .stats { margin-top: 80px; display: grid; grid-template-columns: repeat(4, 1fr); gap: 32px; max-width: 820px; margin-left: auto; margin-right: auto; }
        .stat .v { font-family: var(--display); font-weight: 700; font-size: clamp(32px, 5vw, 48px); color: var(--primary); text-align: center; }
        .stat .l { font-size: 12px; text-transform: uppercase; letter-spacing: .16em; color: var(--muted); text-align: center; margin-top: 8px; }

        /* MARQUEE */
        .marquee { padding: 48px 0; border-top: 1px solid var(--border); border-bottom: 1px solid var(--border); background: rgba(20,23,31,.3); overflow: hidden; }
        .marquee p { text-align: center; font-size: 12px; text-transform: uppercase; letter-spacing: .18em; color: var(--muted); margin-bottom: 24px; }
        .marquee-track { display: flex; gap: 64px; white-space: nowrap; width: max-content; animation: scroll 30s linear infinite; }
        .marquee-track span { font-family: var(--display); font-weight: 700; font-size: 28px; color: rgba(138,143,156,.4); }
        @keyframes scroll { from { transform: translateX(0); } to { transform: translateX(-50%); } }

        /* SECTIONS */
        section.block { padding: 112px 0; }
        h2.section-title { font-size: clamp(32px, 5.5vw, 60px); line-height: 1.02; max-width: 760px; }
        .section-sub { color: var(--muted); font-size: 18px; margin-top: 20px; max-width: 620px; }
        .grid3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-top: 56px; }
        .grid4 { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; margin-top: 56px; }
        .card { background: var(--surface); border: 1px solid var(--border); border-radius: 24px; padding: 28px; transition: transform .25s, border-color .25s; height: 100%; }
        .card:hover { transform: translateY(-8px); border-color: rgba(203,242,74,.4); }
        .card .ic { width: 48px; height: 48px; border-radius: 16px; background: rgba(203,242,74,.1); border: 1px solid rgba(203,242,74,.3);
            display: flex; align-items: center; justify-content: center; color: var(--primary); margin-bottom: 20px; }
        .card h3 { font-family: var(--display); font-weight: 700; font-size: 20px; margin-bottom: 8px; }
        .card p { font-size: 14px; color: var(--muted); }
        .step .n { font-family: var(--mono); font-size: 12px; color: var(--muted); }

        /* FLEET */
        .fleet-card { background: var(--surface); border: 1px solid var(--border); border-radius: 24px; overflow: hidden; transition: transform .25s; height: 100%; }
        .fleet-card:hover { transform: translateY(-10px); }
        .fleet-img { aspect-ratio: 4/3; background: linear-gradient(135deg, var(--surface2), var(--bg)); display: flex; align-items: center; justify-content: center; position: relative; }
        .fleet-img svg { width: 84px; height: 84px; color: rgba(203,242,74,.6); }
        .tag { position: absolute; top: 12px; left: 12px; padding: 4px 10px; border-radius: 999px; background: rgba(11,13,20,.7); backdrop-filter: blur(6px); font-family: var(--mono); font-size: 10px; text-transform: uppercase; letter-spacing: .08em; }
        .rate { position: absolute; top: 12px; right: 12px; padding: 4px 10px; border-radius: 999px; background: var(--primary); color: var(--primary-fg); font-size: 11px; font-weight: 700; display: inline-flex; gap: 4px; align-items: center; }
        .fleet-body { padding: 20px; }
        .fleet-body h3 { font-family: var(--display); font-weight: 700; font-size: 18px; }
        .price { font-family: var(--display); font-weight: 700; font-size: 24px; color: var(--primary); }

        /* HOSTS */
        .hosts-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 64px; align-items: center; }
        .check-list { margin-top: 32px; display: flex; flex-direction: column; gap: 16px; }
        .check-list li { display: flex; gap: 12px; align-items: flex-start; list-style: none; }
        .check { width: 24px; height: 24px; border-radius: 50%; background: var(--primary); color: var(--primary-fg); display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
        .earn-card { background: var(--surface); border: 1px solid var(--border); border-radius: 24px; padding: 28px; box-shadow: 0 24px 60px rgba(0,0,0,.4); animation: float 6s ease-in-out infinite; }
        @keyframes float { 0%,100% { transform: translateY(0); } 50% { transform: translateY(-12px); } }
        .bars { height: 128px; display: flex; align-items: flex-end; gap: 8px; margin-top: 8px; }
        .bars div { flex: 1; border-radius: 6px 6px 0 0; background: linear-gradient(to top, rgba(203,242,74,.4), var(--primary)); }
        .earn-foot { margin-top: 20px; padding-top: 20px; border-top: 1px solid var(--border); display: grid; grid-template-columns: repeat(3,1fr); text-align: center; gap: 16px; }
        .earn-foot .x { font-family: var(--display); font-weight: 700; font-size: 20px; }

        /* PRICING */
        .pricing { display: grid; grid-template-columns: repeat(3, 1fr); gap: 20px; margin-top: 56px; }
        .plan { position: relative; padding: 32px; border-radius: 24px; border: 1px solid var(--border); background: var(--surface); height: 100%; }
        .plan.featured { background: linear-gradient(to bottom, rgba(203,242,74,.1), var(--surface)); border-color: rgba(203,242,74,.5); box-shadow: 0 12px 40px rgba(203,242,74,.18); }
        .plan .pop { position: absolute; top: -12px; left: 32px; padding: 4px 12px; border-radius: 999px; background: var(--primary); color: var(--primary-fg); font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .08em; }
        .plan h3 { font-family: var(--display); font-weight: 700; font-size: 22px; }
        .plan .amt { font-family: var(--display); font-weight: 700; font-size: 44px; margin: 24px 0 0; }
        .plan ul { margin: 28px 0; display: flex; flex-direction: column; gap: 12px; }
        .plan li { display: flex; gap: 8px; align-items: flex-start; font-size: 14px; list-style: none; }
        .plan li svg { color: var(--primary); flex-shrink: 0; margin-top: 2px; }
        .plan .btn { width: 100%; justify-content: center; }
        .plan-btn-ghost { background: var(--surface2); border: 1px solid var(--border); color: var(--fg); }

        /* FAQ */
        .faq { max-width: 800px; margin: 48px auto 0; display: flex; flex-direction: column; gap: 12px; }
        .faq-item { background: var(--surface); border: 1px solid var(--border); border-radius: 16px; overflow: hidden; }
        .faq-q { width: 100%; background: none; border: none; color: var(--fg); cursor: pointer; padding: 20px 24px; display: flex; justify-content: space-between; align-items: center; gap: 16px; font-size: 16px; font-weight: 600; text-align: left; font-family: var(--body); }
        .faq-q svg { color: var(--primary); transition: transform .3s; flex-shrink: 0; }
        .faq-item.open .faq-q svg { transform: rotate(180deg); }
        .faq-a { max-height: 0; overflow: hidden; transition: max-height .3s ease; }
        .faq-a p { padding: 0 24px 20px; color: var(--muted); }

        /* CTA */
        .cta-box { position: relative; max-width: 1000px; margin: 0 auto; border-radius: 28px; overflow: hidden; border: 1px solid var(--border);
            background: linear-gradient(135deg, #16213B, var(--bg) 55%, #0E1A14); padding: 80px 40px; text-align: center; }
        .cta-box .glow { position: absolute; top: 0; left: 50%; transform: translateX(-50%); width: 600px; height: 600px; background: rgba(203,242,74,.28); filter: blur(90px); border-radius: 50%; pointer-events: none; }
        .cta-box h2 { position: relative; font-size: clamp(36px, 6vw, 72px); line-height: 1.02; }

        /* FOOTER */
        footer { border-top: 1px solid var(--border); padding: 64px 0 40px; background: rgba(20,23,31,.3); }
        .foot-grid { display: grid; grid-template-columns: 2fr repeat(4, 1fr); gap: 40px; }
        .foot-grid h4 { font-size: 14px; margin-bottom: 16px; }
        .foot-grid ul { list-style: none; display: flex; flex-direction: column; gap: 12px; }
        .foot-grid a { font-size: 14px; color: var(--muted); }
        .foot-grid a:hover { color: var(--fg); }
        .socials { display: flex; gap: 12px; margin-top: 24px; }
        .socials a { width: 40px; height: 40px; border-radius: 50%; background: var(--surface2); border: 1px solid var(--border); display: flex; align-items: center; justify-content: center; transition: background .2s, color .2s; }
        .socials a:hover { background: var(--primary); color: var(--primary-fg); }
        .foot-bottom { margin-top: 56px; padding-top: 24px; border-top: 1px solid var(--border); display: flex; justify-content: space-between; flex-wrap: wrap; gap: 12px; font-family: var(--mono); font-size: 12px; color: var(--muted); }

        .reveal { opacity: 0; transform: translateY(30px); transition: opacity .7s cubic-bezier(.22,1,.36,1), transform .7s cubic-bezier(.22,1,.36,1); }
        .reveal.in { opacity: 1; transform: none; }

        @media (max-width: 900px) {
            .nav-links, .nav-cta { display: none; }
            .menu-btn { display: block; }
            .stats { grid-template-columns: repeat(2, 1fr); gap: 24px; }
            .grid3, .grid4, .pricing { grid-template-columns: 1fr; }
            .hosts-grid, .foot-grid { grid-template-columns: 1fr; }
        }
    </style>
</head>
<body>
    @php
        $chevron = '<svg class="ico" viewBox="0 0 24 24"><polyline points="6 9 12 15 18 9"/></svg>';
        $arrow = '<svg class="ico" viewBox="0 0 24 24"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>';
        $checkSvg = '<svg class="ico" viewBox="0 0 24 24" style="width:14px;height:14px;stroke-width:3"><polyline points="20 6 9 17 4 12"/></svg>';
        $carSvg = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1" stroke-linecap="round" stroke-linejoin="round"><path d="M19 17h2c.6 0 1-.4 1-1v-3c0-.9-.7-1.7-1.5-1.9C18.7 10.6 16 10 16 10s-1.3-1.4-2.2-2.3c-.5-.4-1.1-.7-1.8-.7H5c-.6 0-1.1.4-1.4.9l-1.4 2.9A3.7 3.7 0 0 0 2 12v4c0 .6.4 1 1 1h2"/><circle cx="7" cy="17" r="2"/><path d="M9 17h6"/><circle cx="17" cy="17" r="2"/></svg>';
        $star = '<svg viewBox="0 0 24 24" fill="currentColor" width="11" height="11"><polygon points="12 2 15 9 22 9.3 17 14 18.5 21 12 17.3 5.5 21 7 14 2 9.3 9 9"/></svg>';
        $features = [
            ['Smart search', 'Filter by make, price, transmission, instant book. Find your car in seconds.', '<svg class="ico" viewBox="0 0 24 24"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>'],
            ['Live map', 'See every car around you in real time with price pins and availability.', '<svg class="ico" viewBox="0 0 24 24"><path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"/><circle cx="12" cy="10" r="3"/></svg>'],
            ['Keyless unlock', 'Tap to unlock supported cars right from the app. No key swap required.', '<svg class="ico" viewBox="0 0 24 24"><circle cx="8" cy="15" r="4"/><path d="M10.8 12.2 19 4"/><path d="m16 6 2 2"/><path d="m18 4 2 2"/></svg>'],
            ['Full insurance', 'Every trip is protected with $1M liability and 24/7 roadside.', '<svg class="ico" viewBox="0 0 24 24"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/></svg>'],
            ['Wallet & rewards', 'Earn Drivly credits on every trip. Withdraw to bank in 1 tap.', '<svg class="ico" viewBox="0 0 24 24"><path d="M20 12V8H6a2 2 0 0 1 0-4h12v4"/><path d="M4 6v12a2 2 0 0 0 2 2h14v-4"/><path d="M18 12a2 2 0 0 0 0 4h4v-4z"/></svg>'],
            ['In-app chat', 'Message hosts before, during and after the trip with photo proof.', '<svg class="ico" viewBox="0 0 24 24"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/></svg>'],
        ];
        $steps = [
            ['01', 'Find your car', 'Search by location, date, or vibe. Filter to your perfect match.'],
            ['02', 'Book in 60 seconds', 'Tap, confirm, pay. Get instant confirmation from the host.'],
            ['03', 'Unlock & drive', 'Walk up, tap unlock, hit the road. We handle the rest.'],
            ['04', 'Drop off & rate', 'Park, lock, leave a rating. Your wallet updates automatically.'],
        ];
        $cars = [
            ['Tesla Model 3', 'Electric', 89, '4.9'],
            ['BMW M4 Competition', 'Sport', 220, '5.0'],
            ['Porsche 911 Carrera', 'Luxury', 380, '4.95'],
            ['Range Rover Sport', 'SUV', 165, '4.8'],
        ];
        $testimonials = [
            ['Sarah K.', 'Host · LA', 'Made $9,400 in 4 months renting my Tesla. The app does literally everything for me.'],
            ['James M.', 'Driver · NYC', 'Booked a Porsche for my anniversary in 45 seconds. Unlocked with my phone. Pure magic.'],
            ['Priya R.', 'Host · Austin', 'The smart pricing and calendar sync made hosting feel passive. I check the app once a week.'],
            ['Alex T.', 'Driver · Miami', "I haven't owned a car in two years. Drivly is cheaper, easier and never the same car twice."],
        ];
        $faqs = [
            ['How does insurance work?', 'Every Drivly trip includes $1M liability coverage and 24/7 roadside assistance — for both drivers and hosts. No paperwork required.'],
            ['Do I need to meet the host?', "Most cars support contactless keyless unlock right from the app. For older vehicles, you'll do a quick 60-second handoff with the host."],
            ['What does it cost to list my car?', 'Listing is free. Drivly takes a 25% service fee per booking which covers insurance, support and platform costs.'],
            ['How fast do hosts get paid?', 'Hosts receive weekly payouts every Monday. You can also withdraw on-demand for a $1 fee.'],
            ['Can I cancel a booking?', 'Yes — free cancellation up to 24 hours before pickup. After that, a partial fee applies based on host policy.'],
            ['What cities are you live in?', '30+ cities with new launches every month. Check the app for your area.'],
        ];
    @endphp

    <header class="nav" id="nav">
        <div class="wrap nav-inner">
            <button class="brand" onclick="window.scrollTo({top:0,behavior:'smooth'})">drivly<span class="dot">.</span></button>
            <nav class="nav-links">
                <a href="#features">Features</a>
                <a href="#how">How it works</a>
                <a href="#fleet">Fleet</a>
                <a href="#hosts">Hosts</a>
                <a href="#pricing">Pricing</a>
                <a href="#faq">FAQ</a>
            </nav>
            <div class="nav-cta">
                <a href="/admin" class="muted" style="font-size:14px">Admin</a>
                <a href="#cta" class="btn btn-primary" style="padding:10px 20px;font-size:14px">Get the app</a>
            </div>
            <button class="menu-btn" onclick="document.getElementById('mobileMenu').style.display = (document.getElementById('mobileMenu').style.display==='block'?'none':'block')" aria-label="Menu">
                <svg class="ico" viewBox="0 0 24 24"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
            </button>
        </div>
        <div id="mobileMenu">
            <a href="#features">Features</a>
            <a href="#how">How it works</a>
            <a href="#fleet">Fleet</a>
            <a href="#hosts">Hosts</a>
            <a href="#pricing">Pricing</a>
            <a href="#faq">FAQ</a>
            <a href="#cta" class="btn btn-primary" style="margin-top:12px">Get the app</a>
        </div>
    </header>

    <!-- HERO -->
    <section class="hero">
        <div class="blob blob1"></div>
        <div class="blob blob2"></div>
        <div class="grid-overlay"></div>
        <div class="wrap hero-inner">
            <span class="badge"><span class="ping"></span> Now live in 30+ cities</span>
            <h1 class="display hero-title">Rent any car,<br>anywhere. <span class="u">Drive smarter.</span></h1>
            <p class="lede">Drivly is the peer-to-peer car marketplace. Browse thousands of cars near you, book in 60 seconds, unlock with your phone. No counters. No queues.</p>
            <div class="hero-actions">
                <a href="#cta" class="btn btn-primary">Get the app {!! $arrow !!}</a>
                <a href="#how" class="btn btn-ghost">How it works</a>
            </div>
            <div class="hero-visual reveal">
                <div class="glow"></div>
                <div class="hero-card"><img src="/assets/hero-car.jpg" alt="Drivly hero car" width="1920" height="1080" loading="eager"></div>
            </div>
            <div class="stats">
                <div class="stat reveal"><div class="v">120K+</div><div class="l">Active drivers</div></div>
                <div class="stat reveal"><div class="v">8K+</div><div class="l">Cars listed</div></div>
                <div class="stat reveal"><div class="v">4.9★</div><div class="l">Avg. rating</div></div>
                <div class="stat reveal"><div class="v">30+</div><div class="l">Cities</div></div>
            </div>
        </div>
    </section>

    <!-- MARQUEE -->
    <section class="marquee">
        <p>Trusted by drivers of</p>
        <div class="marquee-track">
            @foreach (['TESLA','BMW','PORSCHE','AUDI','MERCEDES','FERRARI','LAMBORGHINI','RANGE ROVER','MCLAREN','TOYOTA','TESLA','BMW','PORSCHE','AUDI','MERCEDES','FERRARI','LAMBORGHINI','RANGE ROVER','MCLAREN','TOYOTA'] as $b)
                <span>{{ $b }}</span>
            @endforeach
        </div>
    </section>

    <!-- FEATURES -->
    <section class="block" id="features">
        <div class="wrap">
            <div class="reveal">
                <p class="eyebrow">01 · What you get</p>
                <h2 class="display section-title">Built for drivers who hate friction.</h2>
                <p class="section-sub">Every feature designed to remove a step. From discovery to drop-off, Drivly feels like one fluid motion.</p>
            </div>
            <div class="grid3">
                @foreach ($features as $f)
                    <div class="card reveal"><div class="ic">{!! $f[2] !!}</div><h3>{{ $f[0] }}</h3><p>{{ $f[1] }}</p></div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- HOW -->
    <section class="block" id="how" style="position:relative;border-top:1px solid var(--border);border-bottom:1px solid var(--border);overflow:hidden">
        <div style="position:absolute;inset:0;background:url('/assets/map-bg.jpg') center/cover;opacity:.18;pointer-events:none"></div>
        <div style="position:absolute;inset:0;background:linear-gradient(to bottom, var(--bg), rgba(11,13,20,.6) 50%, var(--bg));pointer-events:none"></div>
        <div class="wrap" style="position:relative">
            <div class="reveal">
                <p class="eyebrow">02 · How it works</p>
                <h2 class="display section-title">Four taps from idea to ignition.</h2>
            </div>
            <div class="grid4">
                @foreach ($steps as $s)
                    <div class="card step reveal"><div class="n">{{ $s[0] }}</div><h3 style="margin-top:24px">{{ $s[1] }}</h3><p>{{ $s[2] }}</p></div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- FLEET -->
    <section class="block" id="fleet">
        <div class="wrap">
            <div class="reveal" style="display:flex;justify-content:space-between;align-items:flex-end;flex-wrap:wrap;gap:16px">
                <div>
                    <p class="eyebrow">03 · The fleet</p>
                    <h2 class="display section-title">From daily drivers to dream cars.</h2>
                </div>
                <a href="#cta" class="accent" style="font-weight:600;display:inline-flex;gap:8px;align-items:center">Browse all cars {!! $arrow !!}</a>
            </div>
            <div class="grid4">
                @foreach ($cars as $c)
                    <div class="fleet-card reveal">
                        <div class="fleet-img">
                            {!! $carSvg !!}
                            <span class="tag mono">{{ $c[1] }}</span>
                            <span class="rate">{!! $star !!} {{ $c[3] }}</span>
                        </div>
                        <div class="fleet-body">
                            <h3>{{ $c[0] }}</h3>
                            <p class="muted" style="font-size:12px;margin:4px 0 16px">Instant book</p>
                            <div style="display:flex;justify-content:space-between;align-items:flex-end">
                                <div><span class="price">${{ $c[2] }}</span><span class="muted" style="font-size:12px"> / day</span></div>
                                <a href="#cta" class="btn" style="background:var(--surface2);border:1px solid var(--border);color:var(--fg);padding:8px 16px;font-size:13px">Book</a>
                            </div>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- HOSTS -->
    <section class="block" id="hosts" style="background:rgba(20,23,31,.3);border-top:1px solid var(--border);border-bottom:1px solid var(--border)">
        <div class="wrap hosts-grid">
            <div class="reveal">
                <p class="eyebrow">04 · For hosts</p>
                <h2 class="display section-title">Your car. Your terms. Your <span class="accent">payout.</span></h2>
                <p class="section-sub">Turn your parked car into a side business. Hosts earn an average of $750/month with zero upfront cost.</p>
                <ul class="check-list">
                    @foreach (['Free listing, no monthly fees','$1M liability insurance per trip','Smart pricing optimized by AI','Weekly payouts straight to your bank'] as $t)
                        <li><span class="check">{!! $checkSvg !!}</span><span>{{ $t }}</span></li>
                    @endforeach
                </ul>
                <a href="#cta" class="btn btn-primary" style="margin-top:36px">Become a host {!! $arrow !!}</a>
            </div>
            <div class="reveal">
                <div class="earn-card">
                    <div style="display:flex;justify-content:space-between;align-items:flex-start;margin-bottom:20px">
                        <div>
                            <p class="muted" style="font-size:12px;text-transform:uppercase;letter-spacing:.16em">This month</p>
                            <p class="display" style="font-size:40px;margin-top:4px">$2,847<span class="muted" style="font-size:16px">.20</span></p>
                        </div>
                        <span style="padding:6px 12px;border-radius:999px;background:rgba(203,242,74,.1);border:1px solid rgba(203,242,74,.3);color:var(--primary);font-size:12px;font-weight:600">+24% MoM</span>
                    </div>
                    <div class="bars">
                        @foreach ([40,65,35,80,55,95,70,100,60,85,75,90] as $h)
                            <div style="height:{{ $h }}%"></div>
                        @endforeach
                    </div>
                    <div class="earn-foot">
                        <div><div class="x">23</div><div class="muted" style="font-size:12px">Trips</div></div>
                        <div><div class="x">4.96</div><div class="muted" style="font-size:12px">Rating</div></div>
                        <div><div class="x">98%</div><div class="muted" style="font-size:12px">Accept</div></div>
                    </div>
                </div>
            </div>
        </div>
    </section>

    <!-- TESTIMONIALS -->
    <section class="block">
        <div class="wrap">
            <div class="reveal">
                <p class="eyebrow">05 · Loved by both sides</p>
                <h2 class="display section-title">120,000+ drivers and hosts agree.</h2>
            </div>
            <div class="grid4">
                @foreach ($testimonials as $t)
                    <div class="card reveal">
                        <div style="display:flex;gap:2px;margin-bottom:16px;color:var(--primary)">{!! str_repeat($star, 5) !!}</div>
                        <p style="font-size:14px;margin-bottom:20px">"{{ $t[2] }}"</p>
                        <div style="padding-top:16px;border-top:1px solid var(--border)">
                            <p style="font-weight:600;font-size:14px">{{ $t[0] }}</p>
                            <p class="muted" style="font-size:12px">{{ $t[1] }}</p>
                        </div>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- PRICING -->
    <section class="block" id="pricing" style="background:rgba(20,23,31,.3);border-top:1px solid var(--border);border-bottom:1px solid var(--border)">
        <div class="wrap">
            <div class="reveal">
                <p class="eyebrow">06 · Pricing</p>
                <h2 class="display section-title">Honest pricing. Zero surprises.</h2>
            </div>
            <div class="pricing">
                <div class="plan reveal">
                    <h3>Driver</h3><p class="muted" style="font-size:14px;margin-top:4px">For everyone who rents.</p>
                    <p class="amt">Free</p>
                    <ul>
                        @foreach (['Unlimited bookings','$1M insurance included','Live chat support','Wallet & rewards'] as $f)<li>{!! $checkSvg !!} {{ $f }}</li>@endforeach
                    </ul>
                    <a href="#cta" class="btn plan-btn-ghost">Download app</a>
                </div>
                <div class="plan featured reveal">
                    <span class="pop">Most popular</span>
                    <h3>Host</h3><p class="muted" style="font-size:14px;margin-top:4px">List your car. Get paid.</p>
                    <p class="amt">0%<span class="muted" style="font-size:14px"> setup</span></p>
                    <ul>
                        @foreach (['Free listing','Smart pricing AI','Calendar sync','Weekly payouts','Pro analytics'] as $f)<li>{!! $checkSvg !!} {{ $f }}</li>@endforeach
                    </ul>
                    <a href="#cta" class="btn btn-primary">Start hosting</a>
                </div>
                <div class="plan reveal">
                    <h3>Fleet</h3><p class="muted" style="font-size:14px;margin-top:4px">10+ vehicles? Talk to sales.</p>
                    <p class="amt">Custom</p>
                    <ul>
                        @foreach (['Dedicated manager','API access','Bulk uploads','Custom contracts','Priority support'] as $f)<li>{!! $checkSvg !!} {{ $f }}</li>@endforeach
                    </ul>
                    <a href="#cta" class="btn plan-btn-ghost">Contact sales</a>
                </div>
            </div>
        </div>
    </section>

    <!-- FAQ -->
    <section class="block" id="faq">
        <div class="wrap">
            <div class="reveal">
                <p class="eyebrow">07 · FAQ</p>
                <h2 class="display section-title">Questions? Answered.</h2>
            </div>
            <div class="faq">
                @foreach ($faqs as $i => $f)
                    <div class="faq-item {{ $i === 0 ? 'open' : '' }} reveal">
                        <button class="faq-q" onclick="toggleFaq(this)">{{ $f[0] }} {!! $chevron !!}</button>
                        <div class="faq-a" @if($i === 0) style="max-height:200px" @endif><p>{{ $f[1] }}</p></div>
                    </div>
                @endforeach
            </div>
        </div>
    </section>

    <!-- CTA -->
    <section class="block" id="cta">
        <div class="wrap">
            <div class="cta-box reveal">
                <div class="glow"></div>
                <p class="eyebrow" style="position:relative">Ready to drive?</p>
                <h2 class="display">Your next car<br>is one tap away.</h2>
                <p class="muted" style="font-size:18px;margin-top:24px;position:relative">Download Drivly free. Get $25 in credit on your first ride.</p>
                <div style="display:flex;flex-wrap:wrap;justify-content:center;gap:12px;margin-top:36px;position:relative">
                    <a href="#" class="btn btn-primary">Download iOS</a>
                    <a href="#" class="btn btn-ghost">Get on Android</a>
                </div>
            </div>
        </div>
    </section>

    <!-- FOOTER -->
    <footer>
        <div class="wrap">
            <div class="foot-grid">
                <div>
                    <p class="display" style="font-size:24px">drivly<span class="accent">.</span></p>
                    <p class="muted" style="font-size:14px;margin-top:12px;max-width:280px">The peer-to-peer car rental marketplace. Drive smarter — anywhere, anytime.</p>
                </div>
                <div><h4>Product</h4><ul><li><a href="#features">Features</a></li><li><a href="#how">How it works</a></li><li><a href="#fleet">Fleet</a></li><li><a href="#pricing">Pricing</a></li></ul></div>
                <div><h4>Company</h4><ul><li><a href="#">About</a></li><li><a href="#">Careers</a></li><li><a href="#">Press</a></li><li><a href="#">Blog</a></li></ul></div>
                <div><h4>Support</h4><ul><li><a href="#">Help center</a></li><li><a href="#">Safety</a></li><li><a href="#">Insurance</a></li><li><a href="#">Cities</a></li></ul></div>
                <div><h4>Legal</h4><ul><li><a href="#">Terms</a></li><li><a href="#">Privacy</a></li><li><a href="#">Cookies</a></li><li><a href="#">Licenses</a></li></ul></div>
            </div>
            <div class="foot-bottom">
                <span>© {{ date('Y') }} Drivly Inc. All rights reserved.</span>
                <span>Made with ⚡ for drivers everywhere.</span>
            </div>
        </div>
    </footer>

    <script>
        // Sticky nav background
        const nav = document.getElementById('nav');
        const onScroll = () => nav.classList.toggle('scrolled', window.scrollY > 20);
        onScroll();
        window.addEventListener('scroll', onScroll, { passive: true });

        // FAQ accordion
        function toggleFaq(btn) {
            const item = btn.closest('.faq-item');
            const ans = item.querySelector('.faq-a');
            const isOpen = item.classList.contains('open');
            document.querySelectorAll('.faq-item').forEach(i => {
                i.classList.remove('open');
                i.querySelector('.faq-a').style.maxHeight = null;
            });
            if (!isOpen) {
                item.classList.add('open');
                ans.style.maxHeight = ans.scrollHeight + 'px';
            }
        }

        // Reveal on scroll
        const io = new IntersectionObserver((entries) => {
            entries.forEach(e => { if (e.isIntersecting) { e.target.classList.add('in'); io.unobserve(e.target); } });
        }, { threshold: 0.12, rootMargin: '-40px' });
        document.querySelectorAll('.reveal').forEach(el => io.observe(el));

        // Close mobile menu on link tap
        document.querySelectorAll('#mobileMenu a').forEach(a =>
            a.addEventListener('click', () => document.getElementById('mobileMenu').style.display = 'none'));
    </script>
</body>
</html>
