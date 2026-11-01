<!DOCTYPE html>
<html lang="en" data-theme="dark">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>ShareLoop — Admin Operations & Intelligence Platform</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&family=Outfit:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/lucide-static@0.454.0/font/lucide.min.css">
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.6/dist/chart.umd.min.js"></script>

    <style>
        :root {
            --primary: #2E7D32;
            --primary-light: #4CAF50;
            --primary-accent: #81C784;
            --primary-rgb: 46, 125, 50;
            --primary-light-rgb: 76, 175, 80;
            --font-main: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
            --font-heading: 'Outfit', sans-serif;
            --radius-sm: 8px;
            --radius-md: 14px;
            --radius-lg: 20px;
            --radius-full: 9999px;
            --transition: all 0.22s cubic-bezier(0.16, 1, 0.3, 1);
        }

        [data-theme="dark"] {
            --bg-base: #0B110D;
            --bg-surface: #111A13;
            --bg-surface-elevated: #18241C;
            --bg-surface-subtle: #1F2F24;
            --border: #233529;
            --border-hover: #334D3C;
            --text-main: #ECF5EE;
            --text-muted: #8EA895;
            --text-dim: #5D7564;
            --card-shadow: 0 10px 30px rgba(0, 0, 0, 0.45);
            --header-bg: rgba(17, 26, 19, 0.85);
            --danger: #EF5350;
            --danger-bg: rgba(239, 83, 80, 0.14);
            --warning: #FFA726;
            --warning-bg: rgba(255, 167, 38, 0.14);
            --info: #42A5F5;
            --info-bg: rgba(66, 165, 245, 0.14);
            --success: #66BB6A;
            --success-bg: rgba(102, 187, 106, 0.14);
        }

        [data-theme="light"] {
            --bg-base: #F3F7F4;
            --bg-surface: #FFFFFF;
            --bg-surface-elevated: #F8FAF8;
            --bg-surface-subtle: #EBF2EC;
            --border: #D8E5DA;
            --border-hover: #BFD6C3;
            --text-main: #142418;
            --text-muted: #536E5A;
            --text-dim: #849E8B;
            --card-shadow: 0 8px 24px rgba(24, 60, 32, 0.08);
            --header-bg: rgba(255, 255, 255, 0.88);
            --danger: #D32F2F;
            --danger-bg: #FFEBEE;
            --warning: #ED6C02;
            --warning-bg: #FFF3E0;
            --info: #0288D1;
            --info-bg: #E1F5FE;
            --success: #2E7D32;
            --success-bg: #E8F5E9;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: var(--font-main);
            background-color: var(--bg-base);
            color: var(--text-main);
            min-height: 100vh;
            display: flex;
            overflow-x: hidden;
            -webkit-font-smoothing: antialiased;
        }

        /* App Layout */
        .admin-sidebar {
            width: 275px;
            background: var(--bg-surface);
            border-right: 1px solid var(--border);
            display: flex;
            flex-direction: column;
            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            z-index: 100;
            transition: var(--transition);
        }

        .sidebar-brand {
            padding: 22px 24px;
            display: flex;
            align-items: center;
            gap: 12px;
            border-bottom: 1px solid var(--border);
        }

        .brand-logo {
            width: 38px;
            height: 38px;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            border-radius: var(--radius-md);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-size: 20px;
            font-weight: 800;
            box-shadow: 0 4px 14px rgba(var(--primary-rgb), 0.4);
        }

        .brand-title {
            font-family: var(--font-heading);
            font-size: 19px;
            font-weight: 700;
            letter-spacing: -0.02em;
            color: var(--text-main);
        }

        .brand-badge {
            font-size: 10px;
            text-transform: uppercase;
            font-weight: 800;
            background: rgba(var(--primary-light-rgb), 0.16);
            color: var(--primary-light);
            padding: 3px 8px;
            border-radius: var(--radius-full);
            margin-left: 6px;
        }

        .sidebar-nav {
            flex: 1;
            overflow-y: auto;
            padding: 18px 14px;
            display: flex;
            flex-direction: column;
            gap: 4px;
        }

        .sidebar-nav::-webkit-scrollbar {
            width: 5px;
        }
        .sidebar-nav::-webkit-scrollbar-thumb {
            background: var(--border);
            border-radius: 4px;
        }

        .nav-section-title {
            font-size: 10.5px;
            text-transform: uppercase;
            letter-spacing: 0.08em;
            color: var(--text-dim);
            font-weight: 700;
            margin: 16px 12px 6px;
        }

        .nav-item {
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 10px 14px;
            color: var(--text-muted);
            text-decoration: none;
            border-radius: var(--radius-sm);
            font-size: 13.5px;
            font-weight: 500;
            cursor: pointer;
            transition: var(--transition);
        }

        .nav-item:hover {
            color: var(--text-main);
            background: var(--bg-surface-subtle);
        }

        .nav-item.active {
            color: white;
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            font-weight: 600;
            box-shadow: 0 4px 12px rgba(var(--primary-rgb), 0.35);
        }

        .nav-item i {
            font-size: 17px;
            width: 20px;
            text-align: center;
        }

        .nav-counter {
            margin-left: auto;
            font-size: 11px;
            padding: 2px 7px;
            border-radius: var(--radius-full);
            background: var(--bg-surface-elevated);
            color: var(--text-muted);
            font-weight: 600;
        }

        .nav-counter.alert {
            background: var(--danger-bg);
            color: var(--danger);
        }

        .sidebar-footer {
            padding: 16px;
            border-top: 1px solid var(--border);
            display: flex;
            align-items: center;
            gap: 12px;
            background: var(--bg-surface-elevated);
        }

        .admin-avatar {
            width: 38px;
            height: 38px;
            border-radius: var(--radius-full);
            background: var(--primary);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: 700;
            font-size: 14px;
        }

        .admin-meta {
            flex: 1;
            overflow: hidden;
        }

        .admin-name {
            font-size: 13.5px;
            font-weight: 600;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .admin-role {
            font-size: 11.5px;
            color: var(--primary-light);
            font-weight: 600;
        }

        /* Main Content */
        .admin-wrapper {
            margin-left: 275px;
            flex: 1;
            display: flex;
            flex-direction: column;
            min-width: 0;
        }

        .top-navbar {
            height: 72px;
            background: var(--header-bg);
            backdrop-filter: blur(14px);
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            padding: 0 32px;
            position: sticky;
            top: 0;
            z-index: 90;
        }

        .navbar-title {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .module-heading {
            font-family: var(--font-heading);
            font-size: 22px;
            font-weight: 700;
            letter-spacing: -0.02em;
        }

        .navbar-actions {
            display: flex;
            align-items: center;
            gap: 14px;
        }

        .status-pill {
            display: inline-flex;
            align-items: center;
            gap: 7px;
            padding: 6px 14px;
            border-radius: var(--radius-full);
            background: var(--success-bg);
            color: var(--success);
            font-size: 12px;
            font-weight: 600;
        }

        .status-dot {
            width: 7px;
            height: 7px;
            border-radius: 50%;
            background: currentColor;
            animation: pulseDot 2s infinite ease-in-out;
        }

        @keyframes pulseDot {
            0%, 100% { opacity: 1; transform: scale(1); }
            50% { opacity: 0.4; transform: scale(0.85); }
        }

        .btn-icon {
            width: 38px;
            height: 38px;
            border-radius: var(--radius-sm);
            border: 1px solid var(--border);
            background: var(--bg-surface);
            color: var(--text-muted);
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            transition: var(--transition);
        }

        .btn-icon:hover {
            color: var(--text-main);
            border-color: var(--border-hover);
            background: var(--bg-surface-elevated);
        }

        .content-area {
            padding: 32px;
            flex: 1;
        }

        /* Widgets & Cards */
        .grid-stats {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
            gap: 20px;
            margin-bottom: 28px;
        }

        .stat-card {
            background: var(--bg-surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            padding: 22px;
            box-shadow: var(--card-shadow);
            position: relative;
            overflow: hidden;
            transition: var(--transition);
        }

        .stat-card:hover {
            transform: translateY(-2px);
            border-color: var(--border-hover);
        }

        .stat-top {
            display: flex;
            align-items: center;
            justify-content: space-between;
            margin-bottom: 14px;
        }

        .stat-label {
            font-size: 13px;
            font-weight: 600;
            color: var(--text-muted);
            text-transform: uppercase;
            letter-spacing: 0.04em;
        }

        .stat-icon {
            width: 40px;
            height: 40px;
            border-radius: var(--radius-sm);
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 19px;
            background: rgba(var(--primary-rgb), 0.12);
            color: var(--primary-light);
        }

        .stat-value {
            font-family: var(--font-heading);
            font-size: 30px;
            font-weight: 800;
            letter-spacing: -0.03em;
            line-height: 1.1;
            margin-bottom: 8px;
        }

        .stat-trend {
            display: flex;
            align-items: center;
            gap: 6px;
            font-size: 12px;
            font-weight: 600;
        }

        .stat-trend.positive { color: var(--success); }
        .stat-trend.warning { color: var(--warning); }
        .stat-trend.negative { color: var(--danger); }

        /* General Card */
        .card {
            background: var(--bg-surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-md);
            box-shadow: var(--card-shadow);
            margin-bottom: 24px;
            overflow: hidden;
        }

        .card-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
            gap: 14px;
            flex-wrap: wrap;
        }

        .card-title {
            font-family: var(--font-heading);
            font-size: 17px;
            font-weight: 700;
            color: var(--text-main);
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .card-body {
            padding: 24px;
        }

        /* Buttons & Form controls */
        .btn {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 9px 18px;
            border-radius: var(--radius-sm);
            font-size: 13.5px;
            font-weight: 600;
            cursor: pointer;
            border: 1px solid transparent;
            transition: var(--transition);
            font-family: inherit;
        }

        .btn-primary {
            background: linear-gradient(135deg, var(--primary), var(--primary-light));
            color: white;
            box-shadow: 0 4px 12px rgba(var(--primary-rgb), 0.3);
        }
        .btn-primary:hover {
            box-shadow: 0 6px 18px rgba(var(--primary-rgb), 0.45);
            transform: translateY(-1px);
        }

        .btn-secondary {
            background: var(--bg-surface-elevated);
            border-color: var(--border);
            color: var(--text-main);
        }
        .btn-secondary:hover {
            border-color: var(--border-hover);
            background: var(--bg-surface-subtle);
        }

        .btn-danger {
            background: var(--danger-bg);
            color: var(--danger);
            border-color: rgba(239, 83, 80, 0.3);
        }
        .btn-danger:hover {
            background: var(--danger);
            color: white;
        }

        .btn-sm {
            padding: 6px 12px;
            font-size: 12px;
        }

        .input, .select {
            padding: 9px 14px;
            border-radius: var(--radius-sm);
            border: 1px solid var(--border);
            background: var(--bg-surface-elevated);
            color: var(--text-main);
            font-size: 13.5px;
            font-family: inherit;
            outline: none;
            transition: var(--transition);
        }

        .input:focus, .select:focus {
            border-color: var(--primary-light);
            box-shadow: 0 0 0 3px rgba(var(--primary-rgb), 0.15);
        }

        /* Tables */
        .table-responsive {
            width: 100%;
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            text-align: left;
            font-size: 13.5px;
        }

        th {
            background: var(--bg-surface-elevated);
            padding: 12px 18px;
            font-weight: 700;
            color: var(--text-muted);
            border-bottom: 1px solid var(--border);
            white-space: nowrap;
            text-transform: uppercase;
            font-size: 11px;
            letter-spacing: 0.05em;
        }

        td {
            padding: 14px 18px;
            border-bottom: 1px solid var(--border);
            color: var(--text-main);
            vertical-align: middle;
        }

        tr:hover td {
            background: var(--bg-surface-subtle);
        }

        /* Badges */
        .badge {
            display: inline-flex;
            align-items: center;
            gap: 5px;
            padding: 4px 10px;
            border-radius: var(--radius-full);
            font-size: 11.5px;
            font-weight: 700;
            text-transform: capitalize;
        }

        .badge-success { background: var(--success-bg); color: var(--success); }
        .badge-warning { background: var(--warning-bg); color: var(--warning); }
        .badge-danger { background: var(--danger-bg); color: var(--danger); }
        .badge-info { background: var(--info-bg); color: var(--info); }

        .tier-badge {
            padding: 3px 10px;
            border-radius: 6px;
            font-size: 11px;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }
        .tier-Bronze { background: #5D4037; color: #D7CCC8; }
        .tier-Silver { background: #455A64; color: #ECEFF1; }
        .tier-Gold { background: #FF8F00; color: #FFF8E1; }
        .tier-Platinum { background: #00838F; color: #E0F7FA; }

        /* Module Sections */
        .module-section {
            display: none;
            animation: fadeIn 0.25s ease-out;
        }

        .module-section.active {
            display: block;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(6px); }
            to { opacity: 1; transform: translateY(0); }
        }

        /* Modal */
        .modal-overlay {
            position: fixed;
            inset: 0;
            background: rgba(0, 0, 0, 0.72);
            backdrop-filter: blur(8px);
            z-index: 1000;
            display: none;
            align-items: center;
            justify-content: center;
            padding: 24px;
        }

        .modal-overlay.active {
            display: flex;
        }

        .modal-card {
            background: var(--bg-surface);
            border: 1px solid var(--border);
            border-radius: var(--radius-lg);
            width: 100%;
            max-width: 680px;
            max-height: 85vh;
            overflow-y: auto;
            box-shadow: 0 25px 50px rgba(0, 0, 0, 0.55);
            animation: modalScale 0.22s cubic-bezier(0.16, 1, 0.3, 1);
        }

        @keyframes modalScale {
            from { opacity: 0; transform: scale(0.95); }
            to { opacity: 1; transform: scale(1); }
        }

        .modal-header {
            padding: 20px 24px;
            border-bottom: 1px solid var(--border);
            display: flex;
            align-items: center;
            justify-content: space-between;
        }

        .modal-body {
            padding: 24px;
        }

        .modal-footer {
            padding: 16px 24px;
            border-top: 1px solid var(--border);
            display: flex;
            justify-content: flex-end;
            gap: 12px;
            background: var(--bg-surface-elevated);
        }

        /* Two columns */
        .grid-2 {
            display: grid;
            grid-template-columns: 1fr 1fr;
            gap: 24px;
        }

        @media (max-width: 1080px) {
            .grid-2 { grid-template-columns: 1fr; }
            .admin-sidebar { width: 80px; }
            .admin-sidebar .brand-title,
            .admin-sidebar .brand-badge,
            .admin-sidebar .nav-section-title,
            .admin-sidebar .nav-item span,
            .admin-sidebar .nav-counter,
            .admin-sidebar .admin-meta { display: none; }
            .admin-wrapper { margin-left: 80px; }
            .sidebar-brand { justify-content: center; padding: 18px 0; }
            .nav-item { justify-content: center; padding: 12px; }
        }
    </style>
</head>
<body>

    <!-- SIDEBAR -->
    <aside class="admin-sidebar">
        <div class="sidebar-brand">
            <div class="brand-logo"><i class="icon-refresh-cw"></i></div>
            <div class="brand-title">ShareLoop <span class="brand-badge">Admin</span></div>
        </div>

        <nav class="sidebar-nav">
            <div class="nav-section-title">Core Operations</div>
            <a class="nav-item active" onclick="switchModule('dashboard')">
                <i class="icon-layout-dashboard"></i>
                <span>1. Dashboard Overview</span>
            </a>
            <a class="nav-item" onclick="switchModule('analytics')">
                <i class="icon-trending-up"></i>
                <span>10. Analytics & Reports</span>
            </a>
            <a class="nav-item" onclick="switchModule('locations')">
                <i class="icon-map-pin"></i>
                <span>9. Location Management</span>
            </a>

            <div class="nav-section-title">Operations & Moderation</div>
            <a class="nav-item" onclick="switchModule('items')">
                <i class="icon-package"></i>
                <span>3. Item Management</span>
                <span class="nav-counter" id="badge-items-count">4</span>
            </a>
            <a class="nav-item" onclick="switchModule('requests')">
                <i class="icon-git-pull-request"></i>
                <span>4. Request Management</span>
                <span class="nav-counter" id="badge-requests-count">1</span>
            </a>
            <a class="nav-item" onclick="switchModule('moderation')">
                <i class="icon-shield-alert"></i>
                <span>5. Moderation Center</span>
                <span class="nav-counter alert" id="badge-reports-count">0</span>
            </a>
            <a class="nav-item" onclick="switchModule('categories')">
                <i class="icon-grid"></i>
                <span>6. Category Management</span>
            </a>

            <div class="nav-section-title">Community & Trust</div>
            <a class="nav-item" onclick="switchModule('users')">
                <i class="icon-users"></i>
                <span>2. User Management</span>
            </a>
            <a class="nav-item" onclick="switchModule('reviews')">
                <i class="icon-star"></i>
                <span>7. Reviews & Ratings</span>
            </a>
            <a class="nav-item" onclick="switchModule('gamification')">
                <i class="icon-award"></i>
                <span>8. Gamification System</span>
            </a>
            <a class="nav-item" onclick="switchModule('notifications')">
                <i class="icon-bell"></i>
                <span>16. Notification Center</span>
            </a>

            <div class="nav-section-title">Security & System</div>
            <a class="nav-item" onclick="switchModule('security')">
                <i class="icon-shield-check"></i>
                <span>11. Security Center</span>
            </a>
            <a class="nav-item" onclick="switchModule('audit')">
                <i class="icon-file-text"></i>
                <span>12. Audit Logs</span>
            </a>
            <a class="nav-item" onclick="switchModule('monitoring')">
                <i class="icon-activity"></i>
                <span>15. API Monitoring</span>
            </a>
            <a class="nav-item" onclick="switchModule('database')">
                <i class="icon-database"></i>
                <span>14. Database Inspector</span>
            </a>
            <a class="nav-item" onclick="switchModule('settings')">
                <i class="icon-settings"></i>
                <span>13. System Settings</span>
            </a>
            <a class="nav-item" onclick="switchModule('roles')">
                <i class="icon-user-check"></i>
                <span>17. Super Admin Roles</span>
            </a>
        </nav>

        <div class="sidebar-footer">
            <div class="admin-avatar">A</div>
            <div class="admin-meta">
                <div class="admin-name" id="admin-user-display">Super Administrator</div>
                <div class="admin-role">Full Governance</div>
            </div>
            <button class="btn-icon" title="Logout" onclick="logoutAdmin()"><i class="icon-log-out"></i></button>
        </div>
    </aside>

    <!-- WRAPPER -->
    <div class="admin-wrapper">
        <header class="top-navbar">
            <div class="navbar-title">
                <h1 class="module-heading" id="current-module-title">Dashboard Overview</h1>
            </div>

            <div class="navbar-actions">
                <div class="status-pill">
                    <span class="status-dot"></span>
                    <span>System 99.98% Healthy</span>
                </div>

                <button class="btn-icon" onclick="toggleTheme()" title="Toggle Dark/Light Mode">
                    <i class="icon-sun" id="theme-icon"></i>
                </button>

                <button class="btn btn-primary btn-sm" onclick="openBroadcastModal()">
                    <i class="icon-send"></i> New Broadcast
                </button>
            </div>
        </header>

        <main class="content-area">

            <!-- MODULE 1: DASHBOARD OVERVIEW -->
            <section id="module-dashboard" class="module-section active">
                <div class="grid-stats">
                    <div class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Total Users</span>
                            <div class="stat-icon"><i class="icon-users"></i></div>
                        </div>
                        <div class="stat-value" id="kpi-total-users">3</div>
                        <div class="stat-trend positive"><i class="icon-arrow-up-right"></i> <span>100% active accounts</span></div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Total Donations</span>
                            <div class="stat-icon"><i class="icon-gift"></i></div>
                        </div>
                        <div class="stat-value" id="kpi-total-donations">4</div>
                        <div class="stat-trend positive"><i class="icon-check-circle"></i> <span>Ready for handover</span></div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Completed Handovers</span>
                            <div class="stat-icon"><i class="icon-repeat"></i></div>
                        </div>
                        <div class="stat-value" id="kpi-completed-handovers">0</div>
                        <div class="stat-trend positive"><span>Recycled into community</span></div>
                    </div>

                    <div class="stat-card">
                        <div class="stat-top">
                            <span class="stat-label">Pending Requests</span>
                            <div class="stat-icon"><i class="icon-clock"></i></div>
                        </div>
                        <div class="stat-value" id="kpi-pending-requests">1</div>
                        <div class="stat-trend warning"><span>Awaiting donor match</span></div>
                    </div>
                </div>

                <div class="grid-2">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="icon-trending-up"></i> Donation & User Growth Velocity</h3>
                        </div>
                        <div class="card-body">
                            <canvas id="growthChart" height="230"></canvas>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="icon-pie-chart"></i> Most Requested Categories</h3>
                        </div>
                        <div class="card-body">
                            <canvas id="categoryChart" height="230"></canvas>
                        </div>
                    </div>
                </div>

                <div class="grid-2">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="icon-award"></i> Most Active Donors</h3>
                        </div>
                        <div class="table-responsive">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Donor</th>
                                        <th>District</th>
                                        <th>Tier</th>
                                        <th>Donations</th>
                                        <th>Rating</th>
                                    </tr>
                                </thead>
                                <tbody id="top-donors-body">
                                    <tr>
                                        <td><strong>Nimal Perera</strong><br><small style="color:var(--text-muted)">nimal@shareloop.test</small></td>
                                        <td>Colombo</td>
                                        <td><span class="tier-badge tier-Gold">Gold</span></td>
                                        <td><strong>2</strong></td>
                                        <td>⭐ 5.0</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="icon-map"></i> Sri Lanka District Distribution</h3>
                        </div>
                        <div class="table-responsive">
                            <table>
                                <thead>
                                    <tr>
                                        <th>District</th>
                                        <th>Donations</th>
                                        <th>Requests</th>
                                        <th>Activity Index</th>
                                    </tr>
                                </thead>
                                <tbody id="district-overview-body">
                                    <tr>
                                        <td>Colombo</td>
                                        <td>2</td>
                                        <td>0</td>
                                        <td><span class="badge badge-success">High</span></td>
                                    </tr>
                                    <tr>
                                        <td>Kandy</td>
                                        <td>1</td>
                                        <td>1</td>
                                        <td><span class="badge badge-success">Active</span></td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </section>

            <!-- MODULE 2: USER MANAGEMENT -->
            <section id="module-users" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <div style="display:flex; gap:12px; align-items:center; flex-wrap:wrap; flex:1;">
                            <input type="text" class="input" id="user-search" placeholder="Search by name, email, phone..." style="min-width:260px;" oninput="filterUsers()">
                            <select class="select" id="user-status-filter" onchange="filterUsers()">
                                <option value="">All Statuses</option>
                                <option value="active">Active</option>
                                <option value="suspended">Suspended</option>
                                <option value="banned">Banned</option>
                            </select>
                            <select class="select" id="user-district-filter" onchange="filterUsers()">
                                <option value="">All Districts</option>
                                <option value="Colombo">Colombo</option>
                                <option value="Kandy">Kandy</option>
                                <option value="Galle">Galle</option>
                                <option value="Gampaha">Gampaha</option>
                            </select>
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>User</th>
                                    <th>District & City</th>
                                    <th>Status</th>
                                    <th>Tier / Points</th>
                                    <th>Verified</th>
                                    <th>Donations</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="users-table-body">
                                <tr>
                                    <td><strong>Nimal Perera</strong><br><small style="color:var(--text-muted)">nimal@shareloop.test</small></td>
                                    <td>Colombo, Dehiwala</td>
                                    <td><span class="badge badge-success">Active</span></td>
                                    <td><span class="tier-badge tier-Gold">Gold</span> (350 pts)</td>
                                    <td><span class="badge badge-info">Verified</span></td>
                                    <td>2 items</td>
                                    <td>
                                        <button class="btn btn-secondary btn-sm" onclick="inspectUser('nimal')">Inspect</button>
                                        <button class="btn btn-danger btn-sm" onclick="toggleUserStatus('nimal', 'suspend')">Suspend</button>
                                    </td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 3: ITEM MANAGEMENT -->
            <section id="module-items" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <div style="display:flex; gap:12px; align-items:center; flex-wrap:wrap; flex:1;">
                            <input type="text" class="input" id="item-search" placeholder="Search listings..." style="min-width:240px;" oninput="fetchItems()">
                            <select class="select" id="item-category-filter" onchange="fetchItems()">
                                <option value="">All Categories</option>
                                <option value="Educational Books">Educational Books</option>
                                <option value="School Supplies">School Supplies</option>
                                <option value="Clothes">Clothes</option>
                                <option value="Household Items">Household Items</option>
                            </select>
                            <select class="select" id="item-mod-filter" onchange="fetchItems()">
                                <option value="">All Moderation Status</option>
                                <option value="approved">Approved</option>
                                <option value="pending">Pending</option>
                                <option value="rejected">Rejected</option>
                            </select>
                        </div>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Item Title</th>
                                    <th>Category</th>
                                    <th>Condition</th>
                                    <th>District</th>
                                    <th>Donor</th>
                                    <th>Moderation</th>
                                    <th>AI Scan</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="items-table-body">
                                <tr>
                                    <td colspan="8" style="text-align:center; padding:24px;">Loading listings...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 4: REQUEST MANAGEMENT -->
            <section id="module-requests" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-git-pull-request"></i> Item Requests Queue</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Requester</th>
                                    <th>Needed Item / Title</th>
                                    <th>Category</th>
                                    <th>Reason / Need Statement</th>
                                    <th>District</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="requests-table-body">
                                <tr>
                                    <td colspan="7" style="text-align:center; padding:24px;">Loading requests...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 5: MODERATION CENTER -->
            <section id="module-moderation" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-shield-alert"></i> Community Reported Queue & AI Auto-Scans</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Report ID</th>
                                    <th>Target Entity</th>
                                    <th>Reason</th>
                                    <th>Reporter</th>
                                    <th>Details</th>
                                    <th>Status</th>
                                    <th>Resolution</th>
                                </tr>
                            </thead>
                            <tbody id="reports-table-body">
                                <tr>
                                    <td colspan="7" style="text-align:center; padding:24px;">No pending community reports. System clean!</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 6: CATEGORY MANAGEMENT -->
            <section id="module-categories" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-grid"></i> Categories Directory</h3>
                        <button class="btn btn-primary btn-sm" onclick="openNewCategoryModal()"><i class="icon-plus"></i> Add Category</button>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Category Name</th>
                                    <th>Icon Identifier</th>
                                    <th>Sort Order</th>
                                    <th>Active Listings</th>
                                    <th>Status</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="categories-table-body">
                                <tr>
                                    <td colspan="6" style="text-align:center; padding:24px;">Loading categories...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 7: REVIEWS & RATINGS -->
            <section id="module-reviews" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-star"></i> Ratings & Feedback Moderate</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Rater</th>
                                    <th>Recipient (Ratee)</th>
                                    <th>Stars</th>
                                    <th>Comment</th>
                                    <th>Date</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="reviews-table-body">
                                <tr>
                                    <td colspan="6" style="text-align:center; padding:24px;">Loading reviews...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 8: GAMIFICATION SYSTEM -->
            <section id="module-gamification" class="module-section">
                <div class="grid-stats">
                    <div class="stat-card">
                        <div class="stat-top"><span class="stat-label">Bronze Donors</span><div class="stat-icon">🥉</div></div>
                        <div class="stat-value" id="badge-count-bronze">2</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-top"><span class="stat-label">Silver Donors</span><div class="stat-icon">🥈</div></div>
                        <div class="stat-value" id="badge-count-silver">0</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-top"><span class="stat-label">Gold Champions</span><div class="stat-icon">🥇</div></div>
                        <div class="stat-value" id="badge-count-gold">1</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-top"><span class="stat-label">Platinum Legends</span><div class="stat-icon">💎</div></div>
                        <div class="stat-value" id="badge-count-platinum">0</div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-award"></i> User Karma, Badges & Points Control</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>User</th>
                                    <th>Badge Tier</th>
                                    <th>Points</th>
                                    <th>Trust Score</th>
                                    <th>District</th>
                                    <th>Adjust</th>
                                </tr>
                            </thead>
                            <tbody id="gamification-table-body">
                                <tr>
                                    <td colspan="6" style="text-align:center; padding:24px;">Loading gamification data...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 9: LOCATION MANAGEMENT -->
            <section id="module-locations" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-map-pin"></i> Sri Lanka District Activity & Heatmap Density</h3>
                    </div>
                    <div class="card-body">
                        <canvas id="districtBarChart" height="200"></canvas>
                    </div>
                </div>
            </section>

            <!-- MODULE 10: ANALYTICS & REPORTS -->
            <section id="module-analytics" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-download"></i> Export Data Reports</h3>
                        <div style="display:flex; gap:10px;">
                            <a href="/api/admin/analytics/export/csv?entity=users" target="_blank" class="btn btn-secondary btn-sm"><i class="icon-file-text"></i> Export Users CSV</a>
                            <a href="/api/admin/analytics/export/csv?entity=items" target="_blank" class="btn btn-secondary btn-sm"><i class="icon-file-text"></i> Export Items CSV</a>
                            <a href="/api/admin/analytics/export/csv?entity=exchanges" target="_blank" class="btn btn-secondary btn-sm"><i class="icon-file-text"></i> Export Handovers CSV</a>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="grid-stats">
                            <div class="stat-card">
                                <div class="stat-label">Donor Conversion Rate</div>
                                <div class="stat-value" id="analytics-donor-rate">66.7%</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-label">Repeat Contributor Index</div>
                                <div class="stat-value" id="analytics-repeat-rate">50.0%</div>
                            </div>
                            <div class="stat-card">
                                <div class="stat-label">Avg Items Per Donor</div>
                                <div class="stat-value" id="analytics-avg-items">2.0</div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- MODULE 11: SECURITY CENTER -->
            <section id="module-security" class="module-section">
                <div class="grid-2">
                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="icon-shield-check"></i> Blacklisted IP Addresses</h3>
                            <button class="btn btn-danger btn-sm" onclick="openBlacklistModal()"><i class="icon-slash"></i> Blacklist IP</button>
                        </div>
                        <div class="table-responsive">
                            <table>
                                <thead>
                                    <tr>
                                        <th>IP Address</th>
                                        <th>Reason</th>
                                        <th>Blocked By</th>
                                        <th>Action</th>
                                    </tr>
                                </thead>
                                <tbody id="blacklist-table-body">
                                    <tr>
                                        <td colspan="4" style="text-align:center; padding:20px;">No IPs currently blacklisted.</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div class="card">
                        <div class="card-header">
                            <h3 class="card-title"><i class="icon-alert-triangle"></i> Security Incidents & Failed Logins</h3>
                        </div>
                        <div class="table-responsive">
                            <table>
                                <thead>
                                    <tr>
                                        <th>Event</th>
                                        <th>IP</th>
                                        <th>Severity</th>
                                        <th>Timestamp</th>
                                    </tr>
                                </thead>
                                <tbody id="security-logs-body">
                                    <tr>
                                        <td colspan="4" style="text-align:center; padding:20px;">Zero critical security incidents in 24h.</td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </section>

            <!-- MODULE 12: AUDIT LOGS -->
            <section id="module-audit" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-file-text"></i> System Audit Trail</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Timestamp</th>
                                    <th>Administrator</th>
                                    <th>Action</th>
                                    <th>Target Entity</th>
                                    <th>IP / Agent</th>
                                    <th>Description</th>
                                </tr>
                            </thead>
                            <tbody id="audit-table-body">
                                <tr>
                                    <td colspan="6" style="text-align:center; padding:24px;">Loading audit logs...</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 13: SYSTEM SETTINGS -->
            <section id="module-settings" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-settings"></i> Global Platform Configuration</h3>
                        <button class="btn btn-primary btn-sm" onclick="saveSettings()"><i class="icon-check"></i> Save Changes</button>
                    </div>
                    <div class="card-body">
                        <div style="display:flex; flex-direction:column; gap:20px; max-width:680px;">
                            <div style="display:flex; justify-content:space-between; align-items:center; padding:14px; background:var(--bg-surface-elevated); border-radius:var(--radius-sm);">
                                <div>
                                    <strong>Platform Maintenance Mode</strong><br>
                                    <small style="color:var(--text-muted)">Show maintenance screen to mobile and web guests</small>
                                </div>
                                <button class="btn btn-secondary btn-sm" id="btn-toggle-maintenance" onclick="toggleMaintenance()">Toggle Maintenance</button>
                            </div>

                            <div>
                                <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Platform Name</label>
                                <input type="text" class="input" id="setting-app-name" value="ShareLoop Sri Lanka" style="width:100%;">
                            </div>

                            <div>
                                <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Support Contact Email</label>
                                <input type="email" class="input" id="setting-email" value="support@shareloop.lk" style="width:100%;">
                            </div>

                            <div>
                                <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Max Concurrent Active Requests Per User</label>
                                <input type="number" class="input" id="setting-max-requests" value="5" style="width:100%;">
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            <!-- MODULE 14: DATABASE INSPECTOR -->
            <section id="module-database" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <div style="display:flex; gap:12px; align-items:center; flex-wrap:wrap; flex:1;">
                            <h3 class="card-title"><i class="icon-database"></i> Read-Only Safe Inspector</h3>
                            <select class="select" id="db-table-select" onchange="inspectDbTable()">
                                <option value="users">users</option>
                                <option value="items">items</option>
                                <option value="item_requests">item_requests</option>
                                <option value="exchanges">exchanges</option>
                                <option value="categories">categories</option>
                                <option value="audit_logs">audit_logs</option>
                                <option value="system_settings">system_settings</option>
                            </select>
                        </div>
                    </div>
                    <div class="table-responsive" id="db-inspector-container">
                        <p style="padding:24px; color:var(--text-muted);">Select a table to view live records.</p>
                    </div>
                </div>
            </section>

            <!-- MODULE 15: API MONITORING -->
            <section id="module-monitoring" class="module-section">
                <div class="grid-stats">
                    <div class="stat-card">
                        <div class="stat-label">24h API Calls</div>
                        <div class="stat-value" id="api-total-calls">142</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Average Response Time</div>
                        <div class="stat-value" id="api-latency">34 ms</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-label">Error Rate (4xx/5xx)</div>
                        <div class="stat-value" id="api-error-rate">0.0%</div>
                    </div>
                </div>

                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-activity"></i> Top Monitored Endpoints</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Endpoint</th>
                                    <th>Total Requests</th>
                                    <th>Avg Latency</th>
                                    <th>Error Count</th>
                                </tr>
                            </thead>
                            <tbody id="api-endpoints-body">
                                <tr>
                                    <td><code>/api/items</code></td>
                                    <td>74</td>
                                    <td>28 ms</td>
                                    <td>0</td>
                                </tr>
                                <tr>
                                    <td><code>/api/categories</code></td>
                                    <td>42</td>
                                    <td>12 ms</td>
                                    <td>0</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 16: NOTIFICATION CENTER -->
            <section id="module-notifications" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-bell"></i> Broadcast Notifications Dispatcher</h3>
                        <button class="btn btn-primary btn-sm" onclick="openBroadcastModal()"><i class="icon-plus"></i> Compose Broadcast</button>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Title</th>
                                    <th>Target Audience</th>
                                    <th>Channel</th>
                                    <th>Recipients</th>
                                    <th>Sent Date</th>
                                </tr>
                            </thead>
                            <tbody id="notifications-table-body">
                                <tr>
                                    <td colspan="5" style="text-align:center; padding:24px;">No broadcast announcements sent yet.</td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

            <!-- MODULE 17: SUPER ADMIN ROLES -->
            <section id="module-roles" class="module-section">
                <div class="card">
                    <div class="card-header">
                        <h3 class="card-title"><i class="icon-user-check"></i> Administrative Roles & Governance Matrix</h3>
                    </div>
                    <div class="table-responsive">
                        <table>
                            <thead>
                                <tr>
                                    <th>Role Name</th>
                                    <th>Slug</th>
                                    <th>Description</th>
                                    <th>System Protected</th>
                                </tr>
                            </thead>
                            <tbody id="roles-table-body">
                                <tr>
                                    <td><strong>Super Administrator</strong></td>
                                    <td><code>super-admin</code></td>
                                    <td>Full control over all platform modules, settings, and administrators.</td>
                                    <td><span class="badge badge-info">Yes</span></td>
                                </tr>
                                <tr>
                                    <td><strong>Community Moderator</strong></td>
                                    <td><code>moderator</code></td>
                                    <td>Handles user verification, content moderation, reports, and reviews.</td>
                                    <td><span class="badge badge-info">Yes</span></td>
                                </tr>
                                <tr>
                                    <td><strong>Support Staff</strong></td>
                                    <td><code>support-staff</code></td>
                                    <td>Customer assistance, user inspection, requests inquiry.</td>
                                    <td><span class="badge badge-info">Yes</span></td>
                                </tr>
                                <tr>
                                    <td><strong>Content Reviewer</strong></td>
                                    <td><code>content-reviewer</code></td>
                                    <td>Approves listings, categories, and AI moderation review.</td>
                                    <td><span class="badge badge-info">Yes</span></td>
                                </tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </section>

        </main>
    </div>

    <!-- MODAL: BROADCAST ANNOUNCEMENT -->
    <div class="modal-overlay" id="broadcastModal">
        <div class="modal-card">
            <div class="modal-header">
                <h3 style="font-family:var(--font-heading); font-size:18px;">Send Broadcast Notification</h3>
                <button class="btn-icon" onclick="closeBroadcastModal()"><i class="icon-x"></i></button>
            </div>
            <div class="modal-body" style="display:flex; flex-direction:column; gap:16px;">
                <div>
                    <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Notification Title</label>
                    <input type="text" class="input" id="broadcast-title" placeholder="e.g. New School Year Donation Drive in Kandy" style="width:100%;">
                </div>

                <div>
                    <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Message Content</label>
                    <textarea class="input" id="broadcast-message" rows="4" placeholder="Type announcement details for the community..." style="width:100%;"></textarea>
                </div>

                <div class="grid-2">
                    <div>
                        <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Target Audience</label>
                        <select class="select" id="broadcast-target" style="width:100%;">
                            <option value="all">All Registered Users</option>
                            <option value="donors">Active Donors Only</option>
                            <option value="requesters">Requesters Only</option>
                        </select>
                    </div>

                    <div>
                        <label style="font-weight:600; font-size:13px; display:block; margin-bottom:6px;">Delivery Channels</label>
                        <select class="select" id="broadcast-channel" style="width:100%;">
                            <option value="in_app">In-App Notification</option>
                            <option value="push">Push Notification (FCM)</option>
                            <option value="email">Email Notification</option>
                            <option value="all">All Channels</option>
                        </select>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-secondary" onclick="closeBroadcastModal()">Cancel</button>
                <button class="btn btn-primary" onclick="submitBroadcast()"><i class="icon-send"></i> Send Broadcast</button>
            </div>
        </div>
    </div>

    <!-- JAVASCRIPT LOGIC -->
    <script>
        // Theme Toggle
        function toggleTheme() {
            const html = document.documentElement;
            const current = html.getAttribute('data-theme') || 'dark';
            const next = current === 'dark' ? 'light' : 'dark';
            html.setAttribute('data-theme', next);
            localStorage.setItem('shareloop_theme', next);
            document.getElementById('theme-icon').className = next === 'dark' ? 'icon-sun' : 'icon-moon';
        }

        // Module Switcher
        function switchModule(moduleKey) {
            document.querySelectorAll('.module-section').forEach(el => el.classList.remove('active'));
            document.querySelectorAll('.nav-item').forEach(el => el.classList.remove('active'));

            const targetSection = document.getElementById('module-' + moduleKey);
            if (targetSection) targetSection.classList.add('active');

            // Set active class on nav
            const clickedNav = Array.from(document.querySelectorAll('.nav-item')).find(el => el.getAttribute('onclick')?.includes(moduleKey));
            if (clickedNav) clickedNav.classList.add('active');

            // Update title
            const titleMap = {
                'dashboard': 'Dashboard Overview',
                'users': 'User Management',
                'items': 'Item Management',
                'requests': 'Request Management',
                'moderation': 'Moderation Center',
                'categories': 'Category Management',
                'reviews': 'Reviews & Ratings',
                'gamification': 'Gamification System',
                'locations': 'Location Management',
                'analytics': 'Analytics & Reports',
                'security': 'Security Center',
                'audit': 'Audit Logs',
                'settings': 'System Settings',
                'database': 'Database Inspector',
                'monitoring': 'API Monitoring',
                'notifications': 'Notification Center',
                'roles': 'Super Admin Roles'
            };
            document.getElementById('current-module-title').innerText = titleMap[moduleKey] || 'Admin Console';

            // Lazy load relevant data
            if (moduleKey === 'items') fetchItems();
            if (moduleKey === 'requests') fetchRequests();
            if (moduleKey === 'categories') fetchCategories();
            if (moduleKey === 'reviews') fetchReviews();
            if (moduleKey === 'gamification') fetchGamification();
            if (moduleKey === 'audit') fetchAuditLogs();
            if (moduleKey === 'security') fetchSecurity();
            if (moduleKey === 'database') inspectDbTable();
        }

        // Charts
        let growthChartInstance, categoryChartInstance, districtChartInstance;

        function initCharts(growthData, categoryData, districtData) {
            const ctxGrowth = document.getElementById('growthChart')?.getContext('2d');
            if (ctxGrowth) {
                if (growthChartInstance) growthChartInstance.destroy();
                growthChartInstance = new Chart(ctxGrowth, {
                    type: 'line',
                    data: {
                        labels: growthData?.labels || ['Oct 25', 'Oct 26', 'Oct 27', 'Oct 28', 'Oct 29', 'Oct 30', 'Nov 01'],
                        datasets: [
                            {
                                label: 'Donations Listed',
                                data: growthData?.donations || [0, 1, 2, 4, 4, 4, 4],
                                borderColor: '#4CAF50',
                                backgroundColor: 'rgba(76, 175, 80, 0.15)',
                                fill: true,
                                tension: 0.35,
                                borderWidth: 3
                            },
                            {
                                label: 'New Users',
                                data: growthData?.users || [0, 0, 1, 3, 3, 3, 3],
                                borderColor: '#81C784',
                                backgroundColor: 'transparent',
                                borderDash: [4, 4],
                                tension: 0.35,
                                borderWidth: 2
                            }
                        ]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { labels: { color: '#8EA895' } } },
                        scales: {
                            x: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#8EA895' } },
                            y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#8EA895' } }
                        }
                    }
                });
            }

            const ctxCat = document.getElementById('categoryChart')?.getContext('2d');
            if (ctxCat) {
                if (categoryChartInstance) categoryChartInstance.destroy();
                categoryChartInstance = new Chart(ctxCat, {
                    type: 'doughnut',
                    data: {
                        labels: ['Books', 'Supplies', 'Clothes', 'Household'],
                        datasets: [{
                            data: [1, 1, 1, 1],
                            backgroundColor: ['#2E7D32', '#4CAF50', '#81C784', '#A5D6A7'],
                            borderWidth: 0
                        }]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { position: 'bottom', labels: { color: '#8EA895' } } }
                    }
                });
            }

            const ctxDist = document.getElementById('districtBarChart')?.getContext('2d');
            if (ctxDist) {
                if (districtChartInstance) districtChartInstance.destroy();
                districtChartInstance = new Chart(ctxDist, {
                    type: 'bar',
                    data: {
                        labels: ['Colombo', 'Kandy', 'Galle', 'Gampaha', 'Matara', 'Jaffna'],
                        datasets: [
                            { label: 'Donations', data: [2, 1, 1, 0, 0, 0], backgroundColor: '#2E7D32' },
                            { label: 'Requests', data: [0, 1, 0, 0, 0, 0], backgroundColor: '#81C784' }
                        ]
                    },
                    options: {
                        responsive: true,
                        plugins: { legend: { labels: { color: '#8EA895' } } },
                        scales: {
                            x: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#8EA895' } },
                            y: { grid: { color: 'rgba(255,255,255,0.05)' }, ticks: { color: '#8EA895' } }
                        }
                    }
                });
            }
        }

        // Live API integration functions
        async function fetchDashboard() {
            try {
                const res = await fetch('/api/admin/overview', {
                    headers: { 'Accept': 'application/json' }
                });
                if (res.ok) {
                    const data = await res.json();
                    document.getElementById('kpi-total-users').innerText = data.kpis.total_users;
                    document.getElementById('kpi-total-donations').innerText = data.kpis.total_donations;
                    document.getElementById('kpi-completed-handovers').innerText = data.kpis.completed_handovers;
                    document.getElementById('kpi-pending-requests').innerText = data.kpis.pending_requests;
                    initCharts(data.trends, data.categories, data.districts);
                } else {
                    initCharts();
                }
            } catch (e) {
                initCharts();
            }
        }

        async function fetchItems() {
            try {
                const search = document.getElementById('item-search')?.value || '';
                const category = document.getElementById('item-category-filter')?.value || '';
                const mod = document.getElementById('item-mod-filter')?.value || '';
                const res = await fetch(`/api/admin/items?search=${encodeURIComponent(search)}&category=${encodeURIComponent(category)}&moderation_status=${encodeURIComponent(mod)}`);
                if (res.ok) {
                    const json = await res.json();
                    const tbody = document.getElementById('items-table-body');
                    if (json.data && json.data.length > 0) {
                        tbody.innerHTML = json.data.map(item => `
                            <tr>
                                <td><strong>${item.title}</strong><br><small style="color:var(--text-muted)">${item.city || item.district}</small></td>
                                <td><span class="badge badge-info">${item.category}</span></td>
                                <td>${item.condition}</td>
                                <td>${item.district}</td>
                                <td>${item.donor?.display_name || 'Donor'}</td>
                                <td><span class="badge ${item.moderation_status === 'approved' ? 'badge-success' : 'badge-warning'}">${item.moderation_status}</span></td>
                                <td>${item.ai_flagged ? '<span class="badge badge-danger">AI Flagged</span>' : '<span class="badge badge-success">Clean (0%)</span>'}</td>
                                <td>
                                    <button class="btn btn-secondary btn-sm" onclick="moderateItem('${item.id}', 'approve')">Approve</button>
                                    <button class="btn btn-secondary btn-sm" onclick="runAiScan('${item.id}')">Scan AI</button>
                                    <button class="btn btn-danger btn-sm" onclick="deleteItem('${item.id}')">Delete</button>
                                </td>
                            </tr>
                        `).join('');
                    } else {
                        tbody.innerHTML = '<tr><td colspan="8" style="text-align:center; padding:24px;">No items match criteria.</td></tr>';
                    }
                }
            } catch (e) {}
        }

        async function fetchRequests() {
            try {
                const res = await fetch('/api/admin/requests');
                if (res.ok) {
                    const json = await res.json();
                    const tbody = document.getElementById('requests-table-body');
                    if (json.data && json.data.length > 0) {
                        tbody.innerHTML = json.data.map(r => `
                            <tr>
                                <td><strong>${r.requester?.display_name || 'Requester'}</strong></td>
                                <td>${r.item_name || r.item?.title || 'General Need'}</td>
                                <td><span class="badge badge-info">${r.category}</span></td>
                                <td>${r.reason}</td>
                                <td>${r.district}</td>
                                <td><span class="badge badge-warning">${r.status}</span></td>
                                <td>
                                    <button class="btn btn-secondary btn-sm" onclick="updateRequestStatus('${r.id}', 'approve')">Approve</button>
                                    <button class="btn btn-danger btn-sm" onclick="updateRequestStatus('${r.id}', 'reject')">Reject</button>
                                </td>
                            </tr>
                        `).join('');
                    }
                }
            } catch (e) {}
        }

        async function fetchCategories() {
            try {
                const res = await fetch('/api/admin/categories');
                if (res.ok) {
                    const data = await res.json();
                    const tbody = document.getElementById('categories-table-body');
                    tbody.innerHTML = data.map(c => `
                        <tr>
                            <td><strong>${c.name}</strong></td>
                            <td><code>${c.icon_name}</code></td>
                            <td>${c.sort_order}</td>
                            <td><strong>${c.items_count || 0}</strong> items</td>
                            <td><span class="badge ${c.is_active ? 'badge-success' : 'badge-danger'}">${c.is_active ? 'Active' : 'Disabled'}</span></td>
                            <td>
                                <button class="btn btn-secondary btn-sm" onclick="alert('Category editor available.')">Edit</button>
                            </td>
                        </tr>
                    `).join('');
                }
            } catch (e) {}
        }

        async function fetchGamification() {
            try {
                const res = await fetch('/api/admin/gamification');
                if (res.ok) {
                    const json = await res.json();
                    const tbody = document.getElementById('gamification-table-body');
                    if (json.users?.data) {
                        tbody.innerHTML = json.users.data.map(u => `
                            <tr>
                                <td><strong>${u.display_name}</strong><br><small style="color:var(--text-muted)">${u.email}</small></td>
                                <td><span class="tier-badge tier-${u.badge}">${u.badge}</span></td>
                                <td><strong>${u.points}</strong> pts</td>
                                <td>${u.trust_score}%</td>
                                <td>${u.district}</td>
                                <td>
                                    <button class="btn btn-secondary btn-sm" onclick="adjustKarma('${u.id}')">+100 Pts</button>
                                </td>
                            </tr>
                        `).join('');
                    }
                }
            } catch (e) {}
        }

        async function adjustKarma(userId) {
            await fetch(`/api/admin/gamification/${userId}`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
                body: JSON.stringify({ points_delta: 100, reason: 'Community contribution bonus' })
            });
            fetchGamification();
        }

        async function runAiScan(itemId) {
            const res = await fetch(`/api/admin/items/${itemId}/ai-scan`, {
                method: 'POST',
                headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content }
            });
            const data = await res.json();
            alert(`AI Scan Complete!\nScam Score: ${data.scan_results.scam_score}%\nToxicity Score: ${data.scan_results.toxicity_score}%\nFlagged: ${data.scan_results.is_flagged ? 'YES' : 'NO'}`);
            fetchItems();
        }

        async function moderateItem(itemId, action) {
            await fetch(`/api/admin/items/${itemId}/moderation`, {
                method: 'PATCH',
                headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
                body: JSON.stringify({ action: action, notes: 'Approved by admin dashboard.' })
            });
            fetchItems();
        }

        async function deleteItem(itemId) {
            if (!confirm('Are you sure you want to permanently delete this listing?')) return;
            await fetch(`/api/admin/items/${itemId}`, {
                method: 'DELETE',
                headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content }
            });
            fetchItems();
        }

        async function inspectDbTable() {
            const table = document.getElementById('db-table-select')?.value || 'users';
            const res = await fetch(`/api/admin/database/tables/${table}`);
            const container = document.getElementById('db-inspector-container');
            if (res.ok) {
                const json = await res.json();
                const cols = json.columns || [];
                const rows = json.records?.data || [];
                if (rows.length === 0) {
                    container.innerHTML = `<p style="padding:24px; color:var(--text-muted)">Table <strong>${table}</strong> is currently empty.</p>`;
                    return;
                }
                let html = '<table><thead><tr>' + cols.map(c => `<th>${c}</th>`).join('') + '</tr></thead><tbody>';
                html += rows.map(r => '<tr>' + cols.map(c => `<td>${typeof r[c] === 'object' ? JSON.stringify(r[c]) : (r[c] !== null ? r[c] : '<span style="color:var(--text-dim)">NULL</span>')}</td>`).join('') + '</tr>').join('');
                html += '</tbody></table>';
                container.innerHTML = html;
            }
        }

        // Broadcast Modal
        function openBroadcastModal() {
            document.getElementById('broadcastModal').classList.add('active');
        }
        function closeBroadcastModal() {
            document.getElementById('broadcastModal').classList.remove('active');
        }
        async function submitBroadcast() {
            const title = document.getElementById('broadcast-title').value;
            const msg = document.getElementById('broadcast-message').value;
            const target = document.getElementById('broadcast-target').value;
            const channel = document.getElementById('broadcast-channel').value;
            if (!title || !msg) {
                alert('Please enter a title and message.');
                return;
            }
            const res = await fetch('/api/admin/notifications/broadcast', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content },
                body: JSON.stringify({ title, message: msg, target_type: target, channel })
            });
            const data = await res.json();
            alert(data.message || 'Notification broadcast queued.');
            closeBroadcastModal();
        }

        function toggleMaintenance() {
            fetch('/api/admin/settings/toggle-maintenance', {
                method: 'POST',
                headers: { 'X-CSRF-TOKEN': document.querySelector('meta[name="csrf-token"]').content }
            }).then(r => r.json()).then(data => alert(data.message));
        }

        function logoutAdmin() {
            if (confirm('Sign out from ShareLoop Admin?')) {
                window.location.href = '/';
            }
        }

        // Initialize on load
        window.addEventListener('DOMContentLoaded', () => {
            const savedTheme = localStorage.getItem('shareloop_theme') || 'dark';
            document.documentElement.setAttribute('data-theme', savedTheme);
            document.getElementById('theme-icon').className = savedTheme === 'dark' ? 'icon-sun' : 'icon-moon';
            fetchDashboard();
        });
    </script>
</body>
</html>
