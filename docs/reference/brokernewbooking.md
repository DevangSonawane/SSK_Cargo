<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0, viewport-fit=cover" name="viewport"/>
<title>New Bookings | BrokerPortal</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<link href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&amp;display=swap" rel="stylesheet"/>
<script id="tailwind-config">
      tailwind.config = {
        darkMode: "class",
        theme: {
          extend: {
            "colors": {
                    "tertiary-container": "#30363c",
                    "outline-variant": "#c4c6cf",
                    "surface-container-highest": "#d3e4fe",
                    "primary-fixed": "#d6e3ff",
                    "primary": "#002045",
                    "secondary-container": "#ffb55c",
                    "on-tertiary": "#ffffff",
                    "secondary": "#875200",
                    "on-primary": "#ffffff",
                    "inverse-primary": "#adc7f7",
                    "surface-bright": "#f8f9ff",
                    "on-error": "#ffffff",
                    "surface-container-lowest": "#ffffff",
                    "surface-container": "#e5eeff",
                    "error": "#ba1a1a",
                    "on-secondary-fixed-variant": "#673d00",
                    "surface": "#f8f9ff",
                    "surface-dim": "#cbdbf5",
                    "on-primary-fixed-variant": "#2d476f",
                    "on-background": "#0b1c30",
                    "on-error-container": "#93000a",
                    "inverse-on-surface": "#eaf1ff",
                    "primary-fixed-dim": "#adc7f7",
                    "tertiary-fixed-dim": "#c1c7cf",
                    "outline": "#74777f",
                    "on-surface-variant": "#43474e",
                    "on-primary-fixed": "#001b3c",
                    "tertiary": "#1b2127",
                    "surface-variant": "#d3e4fe",
                    "surface-tint": "#455f88",
                    "on-secondary": "#ffffff",
                    "on-surface": "#0b1c30",
                    "secondary-fixed-dim": "#ffb866",
                    "on-tertiary-fixed": "#161c22",
                    "on-tertiary-container": "#989fa6",
                    "on-secondary-container": "#744600",
                    "surface-container-low": "#eff4ff",
                    "secondary-fixed": "#ffddba",
                    "surface-container-high": "#dce9ff",
                    "on-tertiary-fixed-variant": "#41474e",
                    "error-container": "#ffdad6",
                    "on-secondary-fixed": "#2b1700",
                    "on-primary-container": "#86a0cd",
                    "inverse-surface": "#213145",
                    "tertiary-fixed": "#dde3eb",
                    "primary-container": "#1a365d",
                    "background": "#f8f9ff"
            },
            "borderRadius": {
                    "DEFAULT": "0.25rem",
                    "lg": "0.5rem",
                    "xl": "0.75rem",
                    "full": "9999px"
            },
            "spacing": {
                    "stack-gap": "0.75rem",
                    "inline-gap": "0.5rem",
                    "container-margin": "1rem",
                    "section-padding": "1.5rem",
                    "grid-gutter": "1rem"
            },
            "fontFamily": {
                    "label-md": ["Inter"],
                    "headline-sm": ["Inter"],
                    "headline-md": ["Inter"],
                    "body-lg": ["Inter"],
                    "label-lg": ["Inter"],
                    "headline-lg": ["Inter"],
                    "label-sm": ["Inter"],
                    "body-sm": ["Inter"],
                    "body-md": ["Inter"]
            },
            "fontSize": {
                    "label-md": ["12px", {"lineHeight": "16px", "fontWeight": "600"}],
                    "headline-sm": ["18px", {"lineHeight": "24px", "fontWeight": "600"}],
                    "headline-md": ["20px", {"lineHeight": "28px", "letterSpacing": "-0.01em", "fontWeight": "600"}],
                    "body-lg": ["16px", {"lineHeight": "24px", "fontWeight": "400"}],
                    "label-lg": ["14px", {"lineHeight": "20px", "letterSpacing": "0.01em", "fontWeight": "600"}],
                    "headline-lg": ["24px", {"lineHeight": "32px", "letterSpacing": "-0.02em", "fontWeight": "700"}],
                    "label-sm": ["11px", {"lineHeight": "14px", "fontWeight": "500"}],
                    "body-sm": ["12px", {"lineHeight": "16px", "fontWeight": "400"}],
                    "body-md": ["14px", {"lineHeight": "20px", "fontWeight": "400"}]
            }
          },
        },
      }
    </script>
<style>
        body { font-family: 'Inter', sans-serif; -webkit-tap-highlight-color: transparent; }
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
            vertical-align: middle;
        }
        .route-line {
            position: absolute;
            left: 11px;
            top: 24px;
            bottom: 24px;
            width: 2px;
            background-image: linear-gradient(to bottom, #74777f 50%, transparent 50%);
            background-size: 2px 8px;
        }
        .load-card-shadow {
            box-shadow: 0px 4px 12px rgba(26, 54, 93, 0.08);
        }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background text-on-surface min-h-screen pb-24">
<!-- TopAppBar -->
<header class="fixed top-0 z-50 w-full bg-surface border-b border-outline-variant shadow-sm flex justify-between items-center px-container-margin h-12">
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary text-[24px]">local_shipping</span>
<h1 class="text-headline-md font-headline-md font-bold text-primary">BrokerPortal</h1>
</div>
<button class="active:scale-95 duration-100 p-1 rounded-full hover:bg-surface-container-low transition-colors">
<span class="material-symbols-outlined text-primary text-[28px]">account_circle</span>
</button>
</header>
<!-- Main Content Canvas -->
<main class="mt-12 p-container-margin max-w-2xl mx-auto">
<!-- Welcome / Status Section -->
<section class="py-4">
<h2 class="font-headline-lg text-headline-lg text-primary tracking-tight">New Bookings</h2>
<p class="font-body-md text-body-md text-on-surface-variant mt-1">Review and manage incoming load requests.</p>
</section>
<!-- Booking List -->
<div class="space-y-stack-gap">
<!-- Load Card 1 -->
<div class="bg-white rounded-xl border border-outline-variant p-4 load-card-shadow transition-transform active:scale-[0.98] duration-150">
<div class="flex justify-between items-start mb-4">
<div>
<span class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider">Load ID: #BRK-9821</span>
<h3 class="font-headline-sm text-headline-sm text-primary">Apex Industrial Supply</h3>
</div>
<div class="bg-surface-container-high px-2 py-1 rounded-lg">
<span class="font-label-lg text-label-lg text-primary font-bold">$2,500</span>
</div>
</div>
<div class="relative pl-8 mb-4">
<div class="route-line"></div>
<div class="mb-4 relative">
<span class="material-symbols-outlined absolute -left-8 text-primary text-[20px]">location_on</span>
<p class="font-label-sm text-label-sm text-on-surface-variant">Pickup</p>
<p class="font-body-md text-body-md font-semibold">Gary, IN (Warehouse A)</p>
<p class="font-body-sm text-body-sm text-on-surface-variant">Oct 24, 08:00 AM</p>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute -left-8 text-secondary text-[20px]">near_me</span>
<p class="font-label-sm text-label-sm text-on-surface-variant">Drop-off</p>
<p class="font-body-md text-body-md font-semibold">Houston, TX (Port Terminal)</p>
<p class="font-body-sm text-body-sm text-on-surface-variant">Oct 26, 04:00 PM</p>
</div>
</div>
<div class="flex items-center gap-2 mb-6 bg-surface-container-low p-2 rounded-lg">
<span class="material-symbols-outlined text-on-surface-variant text-[20px]">inventory_2</span>
<span class="font-body-md text-body-md text-on-surface">Steel Pipes • 42,000 lbs • Flatbed</span>
</div>
<div class="grid grid-cols-2 gap-inline-gap">
<button class="bg-[#ba1a1a] text-white font-label-lg text-label-lg h-12 rounded-lg hover:opacity-90 active:scale-95 transition-all">Reject</button>
<button class="bg-[#ffb55c] text-on-secondary-container font-label-lg text-label-lg h-12 rounded-lg font-bold hover:opacity-90 active:scale-95 transition-all">Accept</button>
</div>
</div>
<!-- Load Card 2 -->
<div class="bg-white rounded-xl border border-outline-variant p-4 load-card-shadow transition-transform active:scale-[0.98] duration-150">
<div class="flex justify-between items-start mb-4">
<div>
<span class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider">Load ID: #BRK-9844</span>
<h3 class="font-headline-sm text-headline-sm text-primary">Global Logistics Corp</h3>
</div>
<div class="bg-surface-container-high px-2 py-1 rounded-lg">
<span class="font-label-lg text-label-lg text-primary font-bold">$1,850</span>
</div>
</div>
<div class="relative pl-8 mb-4">
<div class="route-line"></div>
<div class="mb-4 relative">
<span class="material-symbols-outlined absolute -left-8 text-primary text-[20px]">location_on</span>
<p class="font-label-sm text-label-sm text-on-surface-variant">Pickup</p>
<p class="font-body-md text-body-md font-semibold">Columbus, OH</p>
<p class="font-body-sm text-body-sm text-on-surface-variant">Oct 25, 10:00 AM</p>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute -left-8 text-secondary text-[20px]">near_me</span>
<p class="font-label-sm text-label-sm text-on-surface-variant">Drop-off</p>
<p class="font-body-md text-body-md font-semibold">Atlanta, GA</p>
<p class="font-body-sm text-body-sm text-on-surface-variant">Oct 25, 11:30 PM</p>
</div>
</div>
<div class="flex items-center gap-2 mb-6 bg-surface-container-low p-2 rounded-lg">
<span class="material-symbols-outlined text-on-surface-variant text-[20px]">kitchen</span>
<span class="font-body-md text-body-md text-on-surface">Frozen Goods • 38,000 lbs • Reefer</span>
</div>
<div class="grid grid-cols-2 gap-inline-gap">
<button class="bg-[#ba1a1a] text-white font-label-lg text-label-lg h-12 rounded-lg hover:opacity-90 active:scale-95 transition-all">Reject</button>
<button class="bg-[#ffb55c] text-on-secondary-container font-label-lg text-label-lg h-12 rounded-lg font-bold hover:opacity-90 active:scale-95 transition-all">Accept</button>
</div>
</div>
<!-- Load Card 3 -->
<div class="bg-white rounded-xl border border-outline-variant p-4 load-card-shadow transition-transform active:scale-[0.98] duration-150">
<div class="flex justify-between items-start mb-4">
<div>
<span class="font-label-sm text-label-sm text-on-surface-variant uppercase tracking-wider">Load ID: #BRK-9851</span>
<h3 class="font-headline-sm text-headline-sm text-primary">Tidal Wave Mfg</h3>
</div>
<div class="bg-surface-container-high px-2 py-1 rounded-lg">
<span class="font-label-lg text-label-lg text-primary font-bold">$3,100</span>
</div>
</div>
<div class="relative pl-8 mb-4">
<div class="route-line"></div>
<div class="mb-4 relative">
<span class="material-symbols-outlined absolute -left-8 text-primary text-[20px]">location_on</span>
<p class="font-label-sm text-label-sm text-on-surface-variant">Pickup</p>
<p class="font-body-md text-body-md font-semibold">Seattle, WA</p>
<p class="font-body-sm text-body-sm text-on-surface-variant">Oct 26, 06:00 AM</p>
</div>
<div class="relative">
<span class="material-symbols-outlined absolute -left-8 text-secondary text-[20px]">near_me</span>
<p class="font-label-sm text-label-sm text-on-surface-variant">Drop-off</p>
<p class="font-body-md text-body-md font-semibold">Denver, CO</p>
<p class="font-body-sm text-body-sm text-on-surface-variant">Oct 27, 02:00 PM</p>
</div>
</div>
<div class="flex items-center gap-2 mb-6 bg-surface-container-low p-2 rounded-lg">
<span class="material-symbols-outlined text-on-surface-variant text-[20px]">precision_manufacturing</span>
<span class="font-body-md text-body-md text-on-surface">Machinery Parts • 22,500 lbs • Dry Van</span>
</div>
<div class="grid grid-cols-2 gap-inline-gap">
<button class="bg-[#ba1a1a] text-white font-label-lg text-label-lg h-12 rounded-lg hover:opacity-90 active:scale-95 transition-all">Reject</button>
<button class="bg-[#ffb55c] text-on-secondary-container font-label-lg text-label-lg h-12 rounded-lg font-bold hover:opacity-90 active:scale-95 transition-all">Accept</button>
</div>
</div>
</div>
</main>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-2 py-3 pb-safe bg-surface-container-low shadow-[0_-4px_12px_rgba(26,54,93,0.08)] rounded-t-xl">
<!-- New Bookings (Active) -->
<a class="flex flex-col items-center justify-center bg-secondary-container text-on-secondary-container rounded-full px-4 py-1 active:scale-90 transition-transform duration-150" href="#">
<span class="material-symbols-outlined" style="font-variation-settings: 'FILL' 1;">assignment</span>
<span class="font-label-sm text-label-sm">New Bookings</span>
</a>
<!-- Vehicles -->
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-colors active:scale-90 duration-150 p-2 rounded-xl" href="#">
<span class="material-symbols-outlined">local_shipping</span>
<span class="font-label-sm text-label-sm">Vehicles</span>
</a>
<!-- Drivers -->
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-colors active:scale-90 duration-150 p-2 rounded-xl" href="#">
<span class="material-symbols-outlined">person</span>
<span class="font-label-sm text-label-sm">Drivers</span>
</a>
<!-- History -->
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-colors active:scale-90 duration-150 p-2 rounded-xl" href="#">
<span class="material-symbols-outlined">history</span>
<span class="font-label-sm text-label-sm">History</span>
</a>
</nav>
<script>
        // Simple micro-interaction for buttons
        document.querySelectorAll('button').forEach(btn => {
            btn.addEventListener('click', function(e) {
                // Prevent real action for demo
                e.preventDefault();
                
                const originalText = this.innerText;
                const isAccept = this.classList.contains('bg-[#ffb55c]');
                
                if (isAccept) {
                    this.innerHTML = '<span class="material-symbols-outlined animate-spin">sync</span>';
                    setTimeout(() => {
                        this.closest('.load-card-shadow').style.opacity = '0.5';
                        this.closest('.load-card-shadow').style.pointerEvents = 'none';
                        this.innerHTML = 'Accepted';
                    }, 800);
                } else if (this.classList.contains('bg-[#ba1a1a]')) {
                    this.closest('.load-card-shadow').style.transition = 'all 0.3s ease';
                    this.closest('.load-card-shadow').style.transform = 'translateX(20px)';
                    this.closest('.load-card-shadow').style.opacity = '0';
                    setTimeout(() => {
                        this.closest('.load-card-shadow').remove();
                    }, 300);
                }
            });
        });
    </script>
</body></html>