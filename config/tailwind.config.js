/** @type {import("tailwindcss").Config} */
module.exports = {
    content: ["./src/elm/*.elm", "./src/elm/**/*.elm"],
    darkMode: "media",
    daisyui: {
        themes: [
            {
                light: {
                    "primary": "#4384CE",
                    "primary-content": "#140036",
                    "secondary": "#8CC63F",
                    "secondary-content": "#310025",
                    "accent": "#FFD700",
                    "accent-content": "#00098A",
                    "neutral": "#F0F0F0",
                    "neutral-content": "#630046",
                    "base-100": "#F5F5F5",
                    "base-200": "#E5E5E5",
                    "base-300": "#D5D5D5",
                    "base-content": "#171717",
                    "info": "#3178C6",
                    "info-content": "#FFFFFF",
                    "success": "#6dd145",
                    "success-content": "#000000",
                    "warning": "#FFA726",
                    "warning-content": "#202020",
                    "error": "#E57373",
                    "error-content": "#FFFFFF",

                    "--rounded-box": "1rem",
                    "--rounded-btn": "0.5rem",
                    "--rounded-badge": "1.9rem",
                    "--animation-btn": "0.25s",
                    "--animation-input": "0.2s",
                    "--btn-focus-scale": "0.95",
                    "--border-btn": "1px",
                    "--tab-border": "1px",
                    "--tab-radius": "0.5rem",
                },
                dark: {
                    "primary": "#4384CE",
                    "primary-content": "#FFFFFF",
                    "secondary": "#8CC63F",
                    "secondary-content": "#0D0D0D",
                    "accent": "#FFD700",
                    "accent-content": "#02002B",
                    "neutral": "#2B3A47",
                    "neutral-content": "#E0E0E0",
                    "base-100": "#142531",
                    "base-200": "#1F3441",
                    "base-300": "#2B3A47",
                    "base-content": "#EBEBEB",
                    "info": "#3178C6",
                    "info-content": "#FFFFFF",
                    "success": "#6dd145",
                    "success-content": "#000000",
                    "warning": "#FFA726",
                    "warning-content": "#212121",
                    "error": "#E57373",
                    "error-content": "#0F0F0F",

                    "--rounded-box": "1rem",
                    "--rounded-btn": "0.5rem",
                    "--rounded-badge": "1.9rem",
                    "--animation-btn": "0.25s",
                    "--animation-input": "0.2s",
                    "--btn-focus-scale": "0.95",
                    "--border-btn": "1px",
                    "--tab-border": "1px",
                    "--tab-radius": "0.5rem",
                }
            }
        ],
        darkTheme: "dark",
        base: true,
        styled: true,
        utils: true,
        prefix: "",
        logs: true,
        themeRoot: ":root",
    },
    theme: {
        extend: {
            fontFamily: {
                sans: [
                    '"Source Sans 3"',
                    'ui-sans-serif',
                    'system-ui',
                    'sans-serif',
                    '"Apple Color Emoji"',
                    '"Segoe UI Emoji"',
                    '"Segoe UI Symbol"',
                    '"Noto Color Emoji"'
                ],
                serif: [
                    '"Source Serif 4"',
                    'ui-serif',
                    'Georgia',
                    'Cambria',
                    '"Times New Roman"',
                    'Times',
                    'serif'
                ],
                mono: [
                    '"Source Code Pro"',
                    'ui-monospace',
                    'SFMono-Regular',
                    'Menlo',
                    'Monaco',
                    'Consolas',
                    '"Liberation Mono"',
                    '"Courier New"',
                    'monospace'
                ]
            }
        }
    },
    plugins: [
        require("@tailwindcss/typography"),
        require('@tailwindcss/aspect-ratio'),
        require('daisyui')
    ],
    variants: []
}