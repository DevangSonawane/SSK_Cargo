<!DOCTYPE html>

<html class="light" lang="en"><head>
<meta charset="utf-8"/>
<meta content="width=device-width, initial-scale=1.0" name="viewport"/>
<title>Driver Tracking | BrokerPortal</title>
<script src="https://cdn.tailwindcss.com?plugins=forms,container-queries"></script>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;display=swap" rel="stylesheet"/>
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
        body { font-family: 'Inter', sans-serif; }
        .material-symbols-outlined {
            font-variation-settings: 'FILL' 0, 'wght' 400, 'GRAD' 0, 'opsz' 24;
        }
        .load-card-shadow { box-shadow: 0px 4px 12px rgba(26, 54, 93, 0.08); }
        .action-orange { background-color: #ffb55c; color: #744600; }
        .deep-logistics-blue { background-color: #002045; color: #ffffff; }
    </style>
<style>
    body {
      min-height: max(884px, 100dvh);
    }
  </style>
  </head>
<body class="bg-background text-on-surface min-h-screen pb-24">
<!-- TopAppBar -->
<header class="bg-surface border-b border-outline-variant shadow-sm docked full-width top-0 sticky z-50">
<div class="flex justify-between items-center w-full px-container-margin h-12 max-w-7xl mx-auto">
<div class="flex items-center gap-2">
<span class="material-symbols-outlined text-primary" data-icon="local_shipping">local_shipping</span>
<h1 class="text-headline-md font-headline-md font-bold text-primary">BrokerPortal</h1>
</div>
<div class="flex items-center gap-4">
<button class="hover:bg-surface-container-low transition-colors p-2 rounded-full active:scale-95 duration-100">
<span class="material-symbols-outlined text-on-surface-variant" data-icon="search">search</span>
</button>
<button class="hover:bg-surface-container-low transition-colors p-2 rounded-full active:scale-95 duration-100">
<span class="material-symbols-outlined text-primary" data-icon="account_circle">account_circle</span>
</button>
</div>
</div>
</header>
<main class="max-w-7xl mx-auto px-container-margin pt-6">
<!-- Page Header & Actions -->
<div class="flex flex-col md:flex-row md:items-center justify-between mb-8 gap-4">
<div>
<h2 class="text-headline-lg font-headline-lg text-primary">Driver Fleet Tracking</h2>
<p class="text-body-md font-body-md text-on-surface-variant">Real-time status and operational monitoring of your active carriers.</p>
</div>
<div class="flex items-center gap-3">
<button class="bg-primary text-on-primary px-4 py-3 rounded-lg font-label-lg flex items-center gap-2 hover:opacity-90 transition-opacity active:scale-95 duration-150">
<span class="material-symbols-outlined" data-icon="person_add">person_add</span>
<span>Add Driver</span>
</button>
</div>
</div>
<!-- Driver Stats Bento Grid -->
<div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-8">
<div class="bg-surface-container border border-outline-variant p-4 rounded-xl flex flex-col justify-center">
<span class="text-label-sm font-label-sm text-on-surface-variant uppercase tracking-wider">Total Fleet</span>
<span class="text-headline-lg font-headline-lg text-primary">42</span>
</div>
<div class="bg-primary-container p-4 rounded-xl flex flex-col justify-center">
<span class="text-label-sm font-label-sm text-on-primary-container uppercase tracking-wider">Active Jobs</span>
<span class="text-headline-lg font-headline-lg text-on-primary">28</span>
</div>
<div class="bg-surface border border-outline-variant p-4 rounded-xl flex flex-col justify-center">
<span class="text-label-sm font-label-sm text-on-surface-variant uppercase tracking-wider">Idle Drivers</span>
<span class="text-headline-lg font-headline-lg text-secondary">10</span>
</div>
<div class="bg-surface-container-low border border-outline-variant p-4 rounded-xl flex flex-col justify-center">
<span class="text-label-sm font-label-sm text-on-surface-variant uppercase tracking-wider">Fleet Efficiency</span>
<span class="text-headline-lg font-headline-lg text-primary">94%</span>
</div>
</div>
<!-- Drivers List -->
<div class="space-y-4">
<!-- Driver Card: Active -->
<div class="bg-surface border border-outline-variant rounded-xl p-4 load-card-shadow flex flex-col md:flex-row md:items-center justify-between gap-4 group hover:border-primary transition-colors">
<div class="flex items-center gap-4">
<div class="relative">
<img class="w-14 h-14 rounded-full object-cover border-2 border-primary-container" data-alt="A professional headshot of a middle-aged male truck driver wearing a clean navy blue polo shirt. He has a friendly and confident expression, set against a blurred background of a modern logistics warehouse with soft, natural morning light. The visual style is crisp, high-resolution corporate photography with a warm, trustworthy tone." src="https://lh3.googleusercontent.com/aida-public/AB6AXuC6_1xTROU3eC9YL693jsU2Mv29G0zZjRhqDlYLnS1lgOPqHutUsr8mO3IomKtUvxVOwUvkzOpCmGyNz9Zx9HgWjjkzHDa9QR1zqM4qHVx92gPL9ZF3yGhJ6YZO0ebY970DIm7LNcuv7SjyEYT1rI1VwjJK0GKEpBji3XKV-Sdg-neT1BZ9_4Yh-flrOC-EUifj98Co0eWYnuXGLuxhuhE7Ep9me5XsWkzuTMppHF-PXn-5lcCnfdjxJGFXBJ1bPwQVw2MZohRZM6K3"/>
<div class="absolute bottom-0 right-0 w-4 h-4 bg-emerald-500 border-2 border-surface rounded-full" title="Online"></div>
</div>
<div>
<div class="flex items-center gap-2">
<h3 class="text-label-lg font-label-lg text-on-surface">Marcus Rodriguez</h3>
<span class="bg-surface-variant text-on-primary-container text-label-sm px-2 py-0.5 rounded-full">ID: DR-9921</span>
</div>
<div class="flex items-center gap-2 mt-1 text-primary">
<span class="material-symbols-outlined text-[18px]" data-icon="check_circle" style="font-variation-settings: 'FILL' 1;">check_circle</span>
<span class="text-body-md font-body-md font-semibold">Active on Booking #4492</span>
</div>
<div class="flex items-center gap-1 mt-1 text-on-surface-variant">
<span class="material-symbols-outlined text-[16px]" data-icon="location_on">location_on</span>
<span class="text-body-sm font-body-sm">I-80 near Des Moines, IA</span>
</div>
</div>
</div>
<div class="flex items-center gap-4 border-t md:border-t-0 pt-4 md:pt-0 border-outline-variant">
<div class="text-right hidden md:block">
<span class="text-label-sm font-label-sm text-on-surface-variant block">Last Seen</span>
<span class="text-body-md font-body-md text-on-surface">2 mins ago</span>
</div>
<div class="flex gap-2">
<button class="bg-surface-container-high text-primary hover:bg-primary hover:text-on-primary p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="edit">edit</span>
</button>
<button class="bg-surface-container-high text-on-surface-variant hover:bg-error-container hover:text-on-error-container p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="delete">delete</span>
</button>
<button class="bg-primary text-on-primary px-4 py-2 rounded-lg font-label-md hover:bg-opacity-90 active:scale-95 transition-all">
                            View Map
                        </button>
</div>
</div>
</div>
<!-- Driver Card: Idle -->
<div class="bg-surface border border-outline-variant rounded-xl p-4 load-card-shadow flex flex-col md:flex-row md:items-center justify-between gap-4 group hover:border-secondary transition-colors">
<div class="flex items-center gap-4">
<div class="relative">
<img class="w-14 h-14 rounded-full object-cover border-2 border-secondary-fixed" data-alt="A professional headshot of a young woman with her hair pulled back, wearing a professional grey fleece jacket. She has a neutral, professional expression, photographed in a bright, modern studio with soft key lighting that emphasizes her reliable and systematic persona. The aesthetic is corporate and modern, matching a logistics brand." src="https://lh3.googleusercontent.com/aida-public/AB6AXuCOp8kyeTfLHVU7fsHRVWPEb9ZpjQ6ybNYOXJVUYY1bwNbbyHbitC-ly14syXMON2GKZpNC7d8vb2Ja4TcG3fBF1epMjPv2lUvpz2lxJ2BeilsqfQosaxC6Y_bQ2dnErV98qXd1w0HOevjFCZwzh_8J9pSD5nQV4zTOfOL1QfUGbW-HJ5ut0_iRGQnqddVBkpfsCzotiZMh7X5APOfdV8kXGngtiYV9ZytxAZRFK805XY-efYqOPzv_sQXbdnM0KPdTXwHDo5oBFGjc"/>
<div class="absolute bottom-0 right-0 w-4 h-4 bg-amber-500 border-2 border-surface rounded-full" title="Idle"></div>
</div>
<div>
<div class="flex items-center gap-2">
<h3 class="text-label-lg font-label-lg text-on-surface">Sarah Chen</h3>
<span class="bg-surface-variant text-on-primary-container text-label-sm px-2 py-0.5 rounded-full">ID: DR-1042</span>
</div>
<div class="flex items-center gap-2 mt-1 text-secondary">
<span class="material-symbols-outlined text-[18px]" data-icon="schedule">schedule</span>
<span class="text-body-md font-body-md font-semibold">Idle - Awaiting Assignment</span>
</div>
<div class="flex items-center gap-1 mt-1 text-on-surface-variant">
<span class="material-symbols-outlined text-[16px]" data-icon="location_on">location_on</span>
<span class="text-body-sm font-body-sm">Chicago Logistics Hub, IL</span>
</div>
</div>
</div>
<div class="flex items-center gap-4 border-t md:border-t-0 pt-4 md:pt-0 border-outline-variant">
<div class="text-right hidden md:block">
<span class="text-label-sm font-label-sm text-on-surface-variant block">Last Seen</span>
<span class="text-body-md font-body-md text-on-surface">14 mins ago</span>
</div>
<div class="flex gap-2">
<button class="bg-surface-container-high text-primary hover:bg-primary hover:text-on-primary p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="edit">edit</span>
</button>
<button class="bg-surface-container-high text-on-surface-variant hover:bg-error-container hover:text-on-error-container p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="delete">delete</span>
</button>
<button class="bg-secondary text-on-secondary px-4 py-2 rounded-lg font-label-md hover:bg-opacity-90 active:scale-95 transition-all">
                            Assign Load
                        </button>
</div>
</div>
</div>
<!-- Driver Card: Offline -->
<div class="bg-surface-container-low opacity-80 border border-outline-variant rounded-xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-4 group">
<div class="flex items-center gap-4">
<div class="relative grayscale">
<img class="w-14 h-14 rounded-full object-cover border-2 border-outline" data-alt="A portrait of an older male driver with graying hair and a kind expression, wearing a sturdy denim work shirt. The lighting is low and moody, suggesting evening hours. He is positioned against a background of a quiet, darkened rest stop with distant glowing streetlights. The aesthetic is professional, systematic, and resilient." src="https://lh3.googleusercontent.com/aida-public/AB6AXuB7_VyMjb3aGnv-kMaNIJgi7FEnGxF-zXjSKbeE-M1p2Gz0jh7PGsOzRdfulAQoCG2kSCQI5RcsrUas6jdOEeE2iSIfQVq7P3gTnOa7-GNCRpWvSoSmkE9GbXv2mpwbFQ9HiYmH7KUYCY2HDoB8LhXSZkG3S_LEFwqBIowYBHRfFd5WJcMJDSD6bRhD5EMOJfLWFgC5TSgXTNOYF5b_ezxs6rr3JfpeNA5SQNxVjbJb89SePMnbqkX6Ab-WqgSzurKAUSXULj02imYv"/>
<div class="absolute bottom-0 right-0 w-4 h-4 bg-outline border-2 border-surface rounded-full" title="Offline"></div>
</div>
<div>
<div class="flex items-center gap-2">
<h3 class="text-label-lg font-label-lg text-on-surface">James Wilson</h3>
<span class="bg-surface-variant text-on-primary-container text-label-sm px-2 py-0.5 rounded-full">ID: DR-8820</span>
</div>
<div class="flex items-center gap-2 mt-1 text-on-surface-variant">
<span class="material-symbols-outlined text-[18px]" data-icon="bed">bed</span>
<span class="text-body-md font-body-md font-semibold">Offline - Off Duty</span>
</div>
<div class="flex items-center gap-1 mt-1 text-on-surface-variant">
<span class="material-symbols-outlined text-[16px]" data-icon="location_on">location_on</span>
<span class="text-body-sm font-body-sm">Denver South Terminal, CO</span>
</div>
</div>
</div>
<div class="flex items-center gap-4 border-t md:border-t-0 pt-4 md:pt-0 border-outline-variant">
<div class="text-right hidden md:block">
<span class="text-label-sm font-label-sm text-on-surface-variant block">Last Seen</span>
<span class="text-body-md font-body-md text-on-surface">6 hours ago</span>
</div>
<div class="flex gap-2">
<button class="bg-surface-container-high text-primary hover:bg-primary hover:text-on-primary p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="edit">edit</span>
</button>
<button class="bg-surface-container-high text-on-surface-variant hover:bg-error-container hover:text-on-error-container p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="delete">delete</span>
</button>
<button class="bg-surface-container-highest text-on-surface-variant px-4 py-2 rounded-lg font-label-md cursor-not-allowed">
                            Contact
                        </button>
</div>
</div>
</div>
<!-- Driver Card: Active 2 -->
<div class="bg-surface border border-outline-variant rounded-xl p-4 load-card-shadow flex flex-col md:flex-row md:items-center justify-between gap-4 group hover:border-primary transition-colors">
<div class="flex items-center gap-4">
<div class="relative">
<img class="w-14 h-14 rounded-full object-cover border-2 border-primary-container" data-alt="A professional close-up of a diverse female driver wearing a high-visibility safety vest over a black long-sleeved shirt. She is smiling confidently at the camera. The background shows the side of a large commercial semi-truck under bright, clear daylight. The mood is professional, systematic, and reflects high-stakes logistics precision." src="https://lh3.googleusercontent.com/aida-public/AB6AXuAhVhG7HGDGEjOwAXuf96RZg4q5xQ2_3RvNyj1aVcOIo2KjASHoWDzB2ENJsf0jeQ145oYhG-mkTG7dqQMEL_ihKV42ipGjtPqPb59mj9EsmuXRC-TdBGSuEHeLbF2ce8Oa3DPCfiKJtraz9GvjbEl9uIHq4OEN12LHBKEH3JbLzKyokE8_Q9leHxFLC-Jca5I207cFl0M1RKiQVzErFVlpKirUg3kgxeNRQlC7zn2rXJBFI6ZHAtCmQ5kctmiKjw3NPXb94FLJ1iiX"/>
<div class="absolute bottom-0 right-0 w-4 h-4 bg-emerald-500 border-2 border-surface rounded-full" title="Online"></div>
</div>
<div>
<div class="flex items-center gap-2">
<h3 class="text-label-lg font-label-lg text-on-surface">Elena Kozlov</h3>
<span class="bg-surface-variant text-on-primary-container text-label-sm px-2 py-0.5 rounded-full">ID: DR-5512</span>
</div>
<div class="flex items-center gap-2 mt-1 text-primary">
<span class="material-symbols-outlined text-[18px]" data-icon="check_circle" style="font-variation-settings: 'FILL' 1;">check_circle</span>
<span class="text-body-md font-body-md font-semibold">Active on Booking #4498</span>
</div>
<div class="flex items-center gap-1 mt-1 text-on-surface-variant">
<span class="material-symbols-outlined text-[16px]" data-icon="location_on">location_on</span>
<span class="text-body-sm font-body-sm">Atlanta Bypass, GA</span>
</div>
</div>
</div>
<div class="flex items-center gap-4 border-t md:border-t-0 pt-4 md:pt-0 border-outline-variant">
<div class="text-right hidden md:block">
<span class="text-label-sm font-label-sm text-on-surface-variant block">Last Seen</span>
<span class="text-body-md font-body-md text-on-surface">Just now</span>
</div>
<div class="flex gap-2">
<button class="bg-surface-container-high text-primary hover:bg-primary hover:text-on-primary p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="edit">edit</span>
</button>
<button class="bg-surface-container-high text-on-surface-variant hover:bg-error-container hover:text-on-error-container p-2.5 rounded-lg transition-all active:scale-95">
<span class="material-symbols-outlined" data-icon="delete">delete</span>
</button>
<button class="bg-primary text-on-primary px-4 py-2 rounded-lg font-label-md hover:bg-opacity-90 active:scale-95 transition-all">
                            View Map
                        </button>
</div>
</div>
</div>
</div>
<!-- Empty State Illustration (Hidden by default) -->
<div class="hidden flex flex-col items-center justify-center py-20 text-center" id="no-drivers">
<span class="material-symbols-outlined text-6xl text-outline-variant mb-4" data-icon="group_off">group_off</span>
<h3 class="text-headline-sm font-headline-sm text-on-surface">No drivers found</h3>
<p class="text-body-md font-body-md text-on-surface-variant mt-2">Try adjusting your search or add a new driver to the fleet.</p>
</div>
</main>
<!-- Map View Preview (Floating) -->
<div class="fixed bottom-24 right-4 md:right-8 z-40">
<div class="bg-surface border border-outline-variant rounded-2xl shadow-xl p-2 w-48 h-48 overflow-hidden group cursor-pointer active:scale-95 transition-transform">
<div class="relative w-full h-full rounded-xl overflow-hidden">
<div class="w-full h-full bg-cover bg-center" data-location="Chicago" style="background-image: url('https://lh3.googleusercontent.com/aida-public/AB6AXuAREGOIF5v6duTVW0kecalAPjsvVABhqFmLvaGKACEmwQtiSASOyxDLLZWn8UjlvTe2784xb8Hgp-7mPUJQqkgYMNqs_ibGtbwrxQKOn-8c0dF34J-gYGuuS9hpk0B-O6ZQSZXMDUsKm-54jGjpjtqPAA_jdCaaS-hsmPgZ_SHKWJSwvBCIHjGU0xtyXYdf6kBdDA2ILNAaqxLZwOTJS78YMZcLVVFQquVPSYldafsWlMVXd8zh0dVAs5e1fU18yoL3HN6fezZ9frAQ')"></div>
<div class="absolute inset-0 bg-primary/20 flex items-center justify-center">
<div class="bg-primary text-on-primary text-label-sm px-3 py-1 rounded-full flex items-center gap-1">
<span class="material-symbols-outlined text-[14px]" data-icon="map">map</span>
<span>Open Fleet Map</span>
</div>
</div>
</div>
</div>
</div>
<!-- BottomNavBar -->
<nav class="fixed bottom-0 left-0 w-full z-50 flex justify-around items-center px-2 py-3 pb-safe bg-surface-container-low shadow-[0_-4px_12px_rgba(26,54,93,0.08)] rounded-t-xl">
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-colors px-4 py-1 rounded-full" href="#">
<span class="material-symbols-outlined" data-icon="assignment">assignment</span>
<span class="text-label-sm font-label-sm mt-1">New Bookings</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-colors px-4 py-1 rounded-full" href="#">
<span class="material-symbols-outlined" data-icon="local_shipping">local_shipping</span>
<span class="text-label-sm font-label-sm mt-1">Vehicles</span>
</a>
<a class="flex flex-col items-center justify-center bg-secondary-container text-on-secondary-container rounded-full px-4 py-1 active:scale-90 transition-transform duration-150" href="#">
<span class="material-symbols-outlined" data-icon="person" style="font-variation-settings: 'FILL' 1;">person</span>
<span class="text-label-sm font-label-sm mt-1">Drivers</span>
</a>
<a class="flex flex-col items-center justify-center text-on-surface-variant hover:bg-surface-container-high transition-colors px-4 py-1 rounded-full" href="#">
<span class="material-symbols-outlined" data-icon="history">history</span>
<span class="text-label-sm font-label-sm mt-1">History</span>
</a>
</nav>
<script>
        // Simple interactive feedback
        document.querySelectorAll('button').forEach(button => {
            button.addEventListener('click', function() {
                const icon = this.querySelector('.material-symbols-outlined');
                if (icon) {
                    icon.style.transform = 'scale(1.2)';
                    setTimeout(() => {
                        icon.style.transform = 'scale(1)';
                    }, 200);
                }
            });
        });
    </script>
</body></html>