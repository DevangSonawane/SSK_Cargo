<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" name="viewport"/>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
        tailwind.config = {
            darkMode: "class",
            theme: {
                extend: {
                    "colors": {
                        "on-tertiary-container": "#989fa6",
                        "primary-fixed-dim": "#adc7f7",
                        "on-surface-variant": "#43474e",
                        "on-surface": "#0b1c30",
                        "surface-variant": "#d3e4fe",
                        "outline-variant": "#c4c6cf",
                        "on-secondary-container": "#744600",
                        "surface-container-lowest": "#ffffff",
                        "on-secondary-fixed-variant": "#673d00",
                        "surface-container-low": "#eff4ff",
                        "surface-bright": "#f8f9ff",
                        "on-error-container": "#93000a",
                        "tertiary-container": "#30363c",
                        "surface": "#f8f9ff",
                        "surface-container": "#e5eeff",
                        "secondary": "#875200",
                        "tertiary": "#1b2127",
                        "on-primary-fixed-variant": "#2d476f",
                        "surface-container-highest": "#d3e4fe",
                        "inverse-on-surface": "#eaf1ff",
                        "on-tertiary-fixed": "#161c22",
                        "surface-dim": "#cbdbf5",
                        "tertiary-fixed-dim": "#c1c7cf",
                        "primary-fixed": "#d6e3ff",
                        "secondary-container": "#ffb55c",
                        "on-primary-container": "#86a0cd",
                        "on-tertiary": "#ffffff",
                        "secondary-fixed": "#ffddba",
                        "primary": "#002045",
                        "background": "#f8f9ff",
                        "on-tertiary-fixed-variant": "#41474e",
                        "on-secondary-fixed": "#2b1700",
                        "on-error": "#ffffff",
                        "on-primary": "#ffffff",
                        "surface-tint": "#455f88",
                        "outline": "#74777f",
                        "inverse-primary": "#adc7f7",
                        "error": "#ba1a1a",
                        "tertiary-fixed": "#dde3eb",
                        "surface-container-high": "#dce9ff",
                        "error-container": "#ffdad6",
                        "secondary-fixed-dim": "#ffb866",
                        "primary-container": "#1a365d",
                        "on-secondary": "#ffffff",
                        "on-primary-fixed": "#001b3c",
                        "inverse-surface": "#213145",
                        "on-background": "#0b1c30"
                    },
                    "borderRadius": {
                        "DEFAULT": "0.25rem",
                        "lg": "0.5rem",
                        "xl": "0.75rem",
                        "full": "9999px"
                    },
                    "spacing": {
                        "section-padding": "1.5rem",
                        "grid-gutter": "1rem",
                        "stack-gap": "0.75rem",
                        "container-margin": "1rem",
                        "inline-gap": "0.5rem"
                    },
                    "fontFamily": {
                        "label-lg": ["Inter"],
                        "headline-sm": ["Inter"],
                        "body-lg": ["Inter"],
                        "headline-md": ["Inter"],
                        "body-sm": ["Inter"],
                        "label-md": ["Inter"],
                        "body-md": ["Inter"],
                        "headline-lg": ["Inter"],
                        "label-sm": ["Inter"]
                    },
                    "fontSize": {
                        "label-lg": ["14px", {"lineHeight": "20px", "letterSpacing": "0.01em", "fontWeight": "600"}],
                        "headline-sm": ["18px", {"lineHeight": "24px", "fontWeight": "600"}],
                        "body-lg": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                        "headline-md": ["20px", {"lineHeight": "28px", "letterSpacing": "-0.01em", "fontWeight": "600"}],
                        "body-sm": ["12px", {"lineHeight": "16px", "fontWeight": "400"}],
                        "label-md": ["12px", {"lineHeight": "16px", "fontWeight": "600"}],
                        "body-md": ["14px", {"lineHeight": "20px", "fontWeight": "400"}],
                        "headline-lg": ["24px", {"lineHeight": "32px", "letterSpacing": "-0.02em", "fontWeight": "700"}],
                        "label-sm": ["11px", {"lineHeight": "14px", "fontWeight": "500"}]
                    }
                },
            },
        }
    </script>
<style>
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
            display: inline-block;
            line-height: 1;
            text-transform: none;
            letter-spacing: normal;
            word-wrap: normal;
            white-space: nowrap;
            direction: ltr;
        }
        .hide-scrollbar::-webkit-scrollbar { display: none; }
        .hide-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
        
        body {
            min-height: 100dvh;
        }

        .minimal-card {
            transition: transform 0.2s ease, box-shadow 0.2s ease;
        }
        .minimal-card:active {
            transform: scale(0.985);
        }
    </style>
</head>
<body class="bg-surface-container-low text-on-surface font-body-md min-h-screen flex flex-col">
<!-- TopAppBar -->
<header class="bg-surface dark:bg-surface-container-high border-b border-outline-variant dark:border-outline shadow-sm flex justify-between items-center w-full px-container-margin h-14 sticky top-0 z-50">
<div class="flex items-center gap-inline-gap">
<span class="material-symbols-outlined text-primary dark:text-inverse-primary" style="font-size: 24px;">local_shipping</span>
<h1 class="text-headline-md font-headline-md font-bold text-primary dark:text-inverse-primary">BrokerPortal</h1>
</div>
<div class="flex items-center gap-4">
<button class="material-symbols-outlined text-on-surface-variant hover:bg-surface-container-low p-2 rounded-full transition-colors active:scale-95 duration-100">search</button>
<button class="material-symbols-outlined text-primary dark:text-inverse-primary active:scale-95 duration-100" style="font-size: 32px;">account_circle</button>
</div>
</header>
<!-- Main Content Canvas -->
<main class="flex-1 pb-24 px-container-margin pt-8 max-w-5xl mx-auto w-full">
<!-- Welcome & Summary Section -->
<div class="mb-10 flex justify-between items-start">
<div>
<p class="font-label-md text-label-md text-on-surface-variant uppercase tracking-widest mb-1">Fleet Overview</p>
<h2 class="font-headline-lg text-headline-lg text-primary">Vehicles Fleet</h2>
</div>
<button class="bg-primary text-on-primary px-5 py-2.5 rounded-xl flex items-center gap-2 font-label-lg text-label-lg shadow-lg hover:bg-primary-container hover:text-on-primary-container transition-all active:scale-95">
<span class="material-symbols-outlined text-[20px]">add</span>
                Add Vehicle
            </button>
</div>
<!-- Filter Chips -->
<div class="flex gap-3 mb-8 overflow-x-auto hide-scrollbar">
<button class="bg-primary text-on-primary px-5 py-2 rounded-full font-label-md text-label-md whitespace-nowrap shadow-sm">All Vehicles (12)</button>
<button class="bg-surface-container-lowest text-on-surface-variant border border-outline-variant/30 px-5 py-2 rounded-full font-label-md text-label-md whitespace-nowrap hover:bg-white transition-colors">Available (8)</button>
<button class="bg-surface-container-lowest text-on-surface-variant border border-outline-variant/30 px-5 py-2 rounded-full font-label-md text-label-md whitespace-nowrap hover:bg-white transition-colors">On Trip (4)</button>
<button class="bg-surface-container-lowest text-on-surface-variant border border-outline-variant/30 px-5 py-2 rounded-full font-label-md text-label-md whitespace-nowrap hover:bg-white transition-colors">Maintenance</button>
</div>
<!-- Vehicle Grid -->
<div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
<!-- Vehicle Card 1 -->
<div class="minimal-card bg-surface-container-lowest border border-outline-variant/20 rounded-2xl p-6 shadow-sm hover:shadow-md hover:border-primary/20 cursor-pointer">
<div class="flex justify-between items-start mb-6">
<div class="flex items-center gap-4">
<div class="w-12 h-12 bg-surface-container-high rounded-xl flex items-center justify-center text-primary">
<span class="material-symbols-outlined text-[28px]">local_shipping</span>
</div>
<div>
<h3 class="font-headline-sm text-headline-sm text-primary tracking-tight">ABC-1234</h3>
<p class="text-body-md text-on-surface-variant">14ft Box Truck • 2022 Isuzu</p>
</div>
</div>
<span class="bg-green-100 text-green-800 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider">Available</span>
</div>
<div class="flex items-center gap-8 border-t border-outline-variant/10 pt-4">
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Capacity</p>
<p class="text-body-lg font-semibold text-on-surface">4,500 kg</p>
</div>
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Location</p>
<p class="text-body-lg font-semibold text-on-surface">Main Hub A</p>
</div>
</div>
</div>
<!-- Vehicle Card 2 -->
<div class="minimal-card bg-surface-container-lowest border border-outline-variant/20 rounded-2xl p-6 shadow-sm hover:shadow-md hover:border-primary/20 cursor-pointer">
<div class="flex justify-between items-start mb-6">
<div class="flex items-center gap-4">
<div class="w-12 h-12 bg-surface-container-high rounded-xl flex items-center justify-center text-primary">
<span class="material-symbols-outlined text-[28px]">rv_hookup</span>
</div>
<div>
<h3 class="font-headline-sm text-headline-sm text-primary tracking-tight">XYZ-9876</h3>
<p class="text-body-md text-on-surface-variant">Semi-Trailer • 2021 Freightliner</p>
</div>
</div>
<span class="bg-amber-100 text-amber-800 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider">On Trip</span>
</div>
<div class="flex items-center gap-8 border-t border-outline-variant/10 pt-4">
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Capacity</p>
<p class="text-body-lg font-semibold text-on-surface">22,000 kg</p>
</div>
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Heading To</p>
<p class="text-body-lg font-semibold text-on-surface">Detroit, MI</p>
</div>
</div>
</div>
<!-- Vehicle Card 3 -->
<div class="minimal-card bg-surface-container-lowest border border-outline-variant/20 rounded-2xl p-6 shadow-sm hover:shadow-md hover:border-primary/20 cursor-pointer">
<div class="flex justify-between items-start mb-6">
<div class="flex items-center gap-4">
<div class="w-12 h-12 bg-surface-container-high rounded-xl flex items-center justify-center text-primary">
<span class="material-symbols-outlined text-[28px]">local_shipping</span>
</div>
<div>
<h3 class="font-headline-sm text-headline-sm text-primary tracking-tight">TRK-5521</h3>
<p class="text-body-md text-on-surface-variant">24ft Reefer • 2023 Hino</p>
</div>
</div>
<span class="bg-green-100 text-green-800 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider">Available</span>
</div>
<div class="flex items-center gap-8 border-t border-outline-variant/10 pt-4">
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Capacity</p>
<p class="text-body-lg font-semibold text-on-surface">8,200 kg</p>
</div>
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Location</p>
<p class="text-body-lg font-semibold text-on-surface">Cold Storage Hub</p>
</div>
</div>
</div>
<!-- Vehicle Card 4 -->
<div class="minimal-card bg-surface-container-lowest border border-outline-variant/20 rounded-2xl p-6 shadow-sm hover:shadow-md hover:border-primary/20 cursor-pointer">
<div class="flex justify-between items-start mb-6">
<div class="flex items-center gap-4">
<div class="w-12 h-12 bg-error-container/30 rounded-xl flex items-center justify-center text-error">
<span class="material-symbols-outlined text-[28px]">airport_shuttle</span>
</div>
<div>
<h3 class="font-headline-sm text-headline-sm text-primary tracking-tight">VAN-0042</h3>
<p class="text-body-md text-on-surface-variant">Cargo Van • 2020 Ford Transit</p>
</div>
</div>
<span class="bg-red-100 text-red-800 px-3 py-1 rounded-full text-[11px] font-bold uppercase tracking-wider">Critical</span>
</div>
<div class="flex items-center gap-8 border-t border-outline-variant/10 pt-4">
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Capacity</p>
<p class="text-body-lg font-semibold text-on-surface">1,200 kg</p>
</div>
<div>
<p class="text-label-sm text-on-surface-variant uppercase mb-0.5">Last Known</p>
<p class="text-body-lg font-semibold text-error">Low Fuel Area</p>
</div>
</div>
</div>
<!-- Add New Ghost Card -->
<div class="border-2 border-dashed border-outline-variant/40 rounded-2xl p-6 flex flex-col items-center justify-center gap-3 hover:bg-surface-container hover:border-primary/40 transition-all cursor-pointer group h-full min-h-[160px]">
<div class="w-10 h-10 rounded-full bg-surface-container-high flex items-center justify-center text-on-surface-variant group-hover:bg-primary-container group-hover:text-on-primary-container transition-colors">
<span class="material-symbols-outlined">add</span>
</div>
<span class="font-label-lg text-label-lg text-on-surface-variant">Register New Vehicle</span>
</div>
</div>
</main>
<!-- FAB for mobile focus -->
<button class="fixed bottom-24 right-6 w-14 h-14 bg-primary text-on-primary rounded-full shadow-2xl flex items-center justify-center md:hidden active:scale-90 transition-transform z-40">
<span class="material-symbols-outlined text-[28px]">add</span>
</button>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-2 py-3 pb-safe bg-surface border-t border-outline-variant/20 shadow-[0_-4px_20px_rgba(0,0,0,0.05)]">
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:text-primary transition-colors px-4 py-1" href="#">
<span class="material-symbols-outlined">assignment</span>
<span class="font-label-sm text-label-sm mt-0.5">Bookings</span>
</a>
<a class="flex flex-col items-center justify-center text-primary bg-primary/5 rounded-2xl px-6 py-1" href="#">
<span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1;">local_shipping</span>
<span class="font-label-sm text-label-sm font-bold mt-0.5">Vehicles</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:text-primary transition-colors px-4 py-1" href="#">
<span class="material-symbols-outlined">person</span>
<span class="font-label-sm text-label-sm mt-0.5">Drivers</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:text-primary transition-colors px-4 py-1" href="#">
<span class="material-symbols-outlined">history</span>
<span class="font-label-sm text-label-sm mt-0.5">History</span>
</a>
</nav>
</body></html>