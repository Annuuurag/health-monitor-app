import os
import re

REPORT_DIR = os.path.dirname(__file__)
OUTPUT_HTML = os.path.join(REPORT_DIR, "assembled_report.html")

FILES = [
    "table_of_contents.md",
    "chapter1_introduction.md",
    "chapter2_theoretical_background.md",
    "chapter3_system_design.md",
    "chapter4_hardware_firmware.md",
    "chapter5_cloud_software.md",
    "chapter6_results_evaluation.md",
    "chapter7_conclusion_future.md",
    "bibliography.md"
]

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>B.Tech Project Report: IoT Health Monitor App</title>
    
    <!-- Premium Google Fonts -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&family=Outfit:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
    
    <!-- Marked.js (Markdown Parser) -->
    <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
    
    <!-- MathJax (LaTeX Math equations renderer) -->
    <script>
    window.MathJax = {
        tex: {
            inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
            displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']],
            processEscapes: true
        },
        options: {
            ignoreHtmlClass: 'tex2jax_ignore',
            processHtmlClass: 'tex2jax_process'
        }
    };
    </script>
    <script id="MathJax-script" async src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js"></script>
    
    <!-- Mermaid.js (Diagrams renderer) -->
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    <script>
        mermaid.initialize({
            startOnLoad: false,
            theme: 'dark',
            securityLevel: 'loose'
        });
    </script>
    
    <style>
        :root {
            --bg-color: #0f0f1a;
            --sidebar-bg: #16162a;
            --text-color: #e0e0e8;
            --text-muted: #9090a8;
            --accent-color: #00d4ff;
            --accent-glow: rgba(0, 212, 255, 0.2);
            --border-color: #222244;
            --card-bg: #1a1a32;
            --font-main: 'Inter', sans-serif;
            --font-headers: 'Outfit', sans-serif;
            --font-mono: 'JetBrains Mono', monospace;
        }
        
        body.light-mode {
            --bg-color: #f5f5fa;
            --sidebar-bg: #eaeaf2;
            --text-color: #202030;
            --text-muted: #606078;
            --accent-color: #0088cc;
            --accent-glow: rgba(0, 136, 204, 0.15);
            --border-color: #d0d0e0;
            --card-bg: #ffffff;
        }

        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }

        body {
            font-family: var(--font-main);
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.7;
            display: flex;
            min-height: 100vh;
            transition: background-color 0.3s, color 0.3s;
        }

        /* Sidebar Navigation */
        .sidebar {
            width: 320px;
            background-color: var(--sidebar-bg);
            border-right: 1px solid var(--border-color);
            padding: 24px;
            position: fixed;
            top: 0;
            bottom: 0;
            left: 0;
            overflow-y: auto;
            z-index: 100;
            display: flex;
            flex-direction: column;
            gap: 20px;
        }

        .sidebar-header {
            font-family: var(--font-headers);
            font-size: 1.25rem;
            font-weight: 700;
            color: var(--accent-color);
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 15px;
            margin-bottom: 10px;
        }

        .nav-links {
            display: flex;
            flex-direction: column;
            gap: 8px;
            list-style: none;
        }

        .nav-item {
            padding: 10px 14px;
            border-radius: 8px;
            cursor: pointer;
            font-weight: 500;
            font-size: 0.9rem;
            color: var(--text-muted);
            transition: all 0.2s;
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .nav-item:hover, .nav-item.active {
            color: var(--text-color);
            background-color: var(--card-bg);
            border-left: 3px solid var(--accent-color);
        }

        /* Toolbar Actions */
        .toolbar {
            display: flex;
            gap: 10px;
            margin-top: auto;
            padding-top: 20px;
            border-top: 1px solid var(--border-color);
        }

        .btn {
            flex: 1;
            padding: 10px;
            border-radius: 8px;
            border: 1px solid var(--border-color);
            background-color: var(--card-bg);
            color: var(--text-color);
            font-family: var(--font-main);
            font-weight: 600;
            font-size: 0.85rem;
            cursor: pointer;
            transition: all 0.2s;
            display: flex;
            align-items: center;
            justify-content: center;
            gap: 6px;
        }

        .btn:hover {
            border-color: var(--accent-color);
            box-shadow: 0 0 8px var(--accent-glow);
        }

        /* Main Content Container */
        .content-area {
            margin-left: 320px;
            padding: 50px 80px;
            max-width: 1100px;
            width: calc(100% - 320px);
        }

        /* Document Styling */
        .report-section {
            display: none;
        }

        .report-section.active {
            display: block;
            animation: fadeIn 0.4s ease;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(10px); }
            to { opacity: 1; transform: translateY(0); }
        }

        h1, h2, h3, h4 {
            font-family: var(--font-headers);
            color: var(--text-color);
            margin-top: 1.8rem;
            margin-bottom: 0.9rem;
            font-weight: 700;
        }

        h1 {
            font-size: 2.3rem;
            color: var(--accent-color);
            border-bottom: 2px solid var(--border-color);
            padding-bottom: 12px;
            margin-top: 0;
            margin-bottom: 1.8rem;
        }

        h2 {
            font-size: 1.6rem;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 6px;
            margin-top: 2.2rem;
        }

        h3 { font-size: 1.25rem; }

        p {
            margin-bottom: 1.2rem;
            font-size: 1.05rem;
        }

        ul, ol {
            margin-bottom: 1.2rem;
            padding-left: 24px;
            font-size: 1.05rem;
        }

        li {
            margin-bottom: 6px;
        }

        /* Code Blocks */
        pre {
            background-color: var(--sidebar-bg);
            border: 1px solid var(--border-color);
            padding: 16px;
            border-radius: 10px;
            overflow-x: auto;
            margin-bottom: 1.5rem;
        }

        code {
            font-family: var(--font-mono);
            font-size: 0.9rem;
            background-color: rgba(128,128,128,0.1);
            padding: 2px 6px;
            border-radius: 4px;
        }

        pre code {
            background-color: transparent;
            padding: 0;
            border-radius: 0;
        }

        /* Tables */
        table {
            width: 100%;
            border-collapse: collapse;
            margin-bottom: 1.8rem;
            margin-top: 1rem;
            font-size: 0.95rem;
        }

        th, td {
            padding: 12px 16px;
            border: 1px solid var(--border-color);
            text-align: left;
        }

        th {
            background-color: var(--sidebar-bg);
            font-weight: 600;
            font-family: var(--font-headers);
        }

        tr:nth-child(even) td {
            background-color: rgba(128,128,128,0.03);
        }

        /* Mermaid Diagrams Container */
        .mermaid {
            background-color: var(--sidebar-bg);
            border: 1px solid var(--border-color);
            border-radius: 12px;
            padding: 24px;
            margin: 1.8rem 0;
            display: flex;
            justify-content: center;
        }

        /* Math Blocks */
        .mjx-chtml {
            font-size: 1.1rem !important;
        }

        /* Print Specific Styles */
        @media print {
            .sidebar {
                display: none !important;
            }
            .content-area {
                margin-left: 0 !important;
                padding: 0 !important;
                width: 100% !important;
                max-width: 100% !important;
                color: #000000 !important;
                background-color: #ffffff !important;
            }
            .report-section {
                display: block !important;
                page-break-after: always;
            }
            h1, h2, h3, h4, p, li, td, th {
                color: #000000 !important;
            }
            pre, code {
                border-color: #cccccc !important;
                background-color: #f8f8f8 !important;
                color: #000000 !important;
            }
            th {
                background-color: #eaeaea !important;
            }
            .mermaid {
                border-color: #cccccc !important;
                background-color: #ffffff !important;
            }
        }
    </style>
</head>
<body>

    <!-- Sidebar Navigation -->
    <div class="sidebar">
        <div class="sidebar-header">
            🎓 Project Thesis
        </div>
        <ul class="nav-links">
            <li class="nav-item active" onclick="showSection(0)">Table of Contents</li>
            <li class="nav-item" onclick="showSection(1)">Chapter 1: Introduction</li>
            <li class="nav-item" onclick="showSection(2)">Chapter 2: Theory & Components</li>
            <li class="nav-item" onclick="showSection(3)">Chapter 3: System Design</li>
            <li class="nav-item" onclick="showSection(4)">Chapter 4: Hardware & Firmware</li>
            <li class="nav-item" onclick="showSection(5)">Chapter 5: Cloud & Software</li>
            <li class="nav-item" onclick="showSection(6)">Chapter 6: Testing & Evaluation</li>
            <li class="nav-item" onclick="showSection(7)">Chapter 7: Conclusions</li>
            <li class="nav-item" onclick="showSection(8)">Bibliography</li>
        </ul>
        
        <div class="toolbar">
            <button class="btn" onclick="toggleTheme()">🌓 Mode</button>
            <button class="btn" onclick="window.print()">🖨️ Print / PDF</button>
        </div>
    </div>

    <!-- Main Content Area -->
    <div class="content-area" id="content">
        <!-- Sections will be injected here dynamically -->
    </div>

    <!-- Raw Markdown Chapters Container -->
    {markdown_blocks}

    <script>
        const sections = [
            "table-of-contents",
            "chapter-1",
            "chapter-2",
            "chapter-3",
            "chapter-4",
            "chapter-5",
            "chapter-6",
            "chapter-7",
            "bibliography"
        ];

        // Parse and render all markdown sections
        function renderReport() {
            const container = document.getElementById("content");
            
            sections.forEach((id, idx) => {
                const rawMdEl = document.getElementById(`raw-${id}`);
                if (rawMdEl) {
                    const sectionDiv = document.createElement("div");
                    sectionDiv.className = `report-section ${idx === 0 ? 'active' : ''}`;
                    sectionDiv.id = `section-${id}`;
                    
                    // Parse Markdown to HTML using marked.js
                    let htmlContent = marked.parse(rawMdEl.textContent);
                    
                    // Handle MathJax classes to protect LaTeX formulas
                    sectionDiv.innerHTML = htmlContent;
                    container.appendChild(sectionDiv);
                }
            });

            // Convert raw code blocks with class "language-mermaid" into standard mermaid divs
            document.querySelectorAll("pre code.language-mermaid").forEach((block) => {
                const pre = block.parentElement;
                const mermaidDiv = document.createElement("div");
                mermaidDiv.className = "mermaid";
                mermaidDiv.textContent = block.textContent;
                pre.replaceWith(mermaidDiv);
            });

            // Run Mermaid parser
            mermaid.run();
            
            // Run MathJax parser
            if (window.MathJax) {
                MathJax.typeset();
            }
        }

        // Section switcher
        function showSection(index) {
            document.querySelectorAll(".report-section").forEach((sec, idx) => {
                sec.classList.toggle("active", idx === index);
            });
            
            document.querySelectorAll(".nav-item").forEach((item, idx) => {
                item.classList.toggle("active", idx === index);
            });

            window.scrollTo({ top: 0, behavior: 'smooth' });
        }

        // Light/Dark mode toggler
        function toggleTheme() {
            document.body.classList.toggle("light-mode");
        }

        // Initialize rendering on load
        window.addEventListener("load", renderReport);
    </script>
</body>
</html>
"""

def assemble():
    print("Reading and assembling markdown report chapters...")
    markdown_blocks = ""
    
    for filename in FILES:
        filepath = os.path.join(REPORT_DIR, filename)
        section_id = filename.replace(".md", "").replace("_", "-")
        
        # Clean section id names
        section_id = section_id.replace("chapter1", "chapter-1")
        section_id = section_id.replace("chapter2", "chapter-2")
        section_id = section_id.replace("chapter3", "chapter-3")
        section_id = section_id.replace("chapter4", "chapter-4")
        section_id = section_id.replace("chapter5", "chapter-5")
        section_id = section_id.replace("chapter6", "chapter-6")
        section_id = section_id.replace("chapter7", "chapter-7")
        
        if not os.path.exists(filepath):
            print(f"Error: missing file {filename}")
            continue
            
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
            
        # Wrap raw markdown inside a script tag to prevent HTML parser execution
        markdown_blocks += f'\n    <script id="raw-{section_id}" type="text/markdown">\n{content}\n    </script>\n'
        
    final_html = HTML_TEMPLATE.replace("{markdown_blocks}", markdown_blocks)
    
    with open(OUTPUT_HTML, "w", encoding="utf-8") as f:
        f.write(final_html)
        
    print(f"Assembled report compiled successfully! File saved to: {OUTPUT_HTML}")

if __name__ == "__main__":
    assemble()
