// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require('tailwindcss/plugin')
const fs = require('fs')
const path = require('path')

// Custom color palettes from Figma design system
const customColors = {
  // Primary Brand Color - Pry Violet
  violet: {
    50: '#f2edf7',
    100: '#d6c8e5',
    200: '#c2aed8',
    300: '#a788c7',
    400: '#9571bc',
    500: '#7b4eab', // Primary brand color
    600: '#70479c',
    700: '#573779',
    800: '#442b5e',
    900: '#342148',
    950: '#291936', // Extrapolated
  },

  // Gray palette
  gray: {
    50: '#f5f5f5',
    100: '#e0e0e0',
    200: '#c6c6c6',
    300: '#a8a8a8',
    400: '#8d8d8d',
    500: '#717171',
    600: '#5e5e5e',
    700: '#4a4a4a',
    800: '#383838',
    900: '#262626',
    950: '#1a1a1a',
  },

  // Warning - Orange
  warning: {
    50: '#fff3e0',
    100: '#ffe0b2',
    200: '#ffcc80',
    300: '#ffb74d',
    400: '#ffa726',
    500: '#ff9800',
    600: '#fb8c00',
    700: '#f57c00',
    800: '#ef6c00',
    900: '#e65100',
    950: '#bf360c',
  },

  // Red - Error
  red: {
    50: '#ffebee',
    100: '#ffcdd2',
    200: '#ef9a9a',
    300: '#e57373',
    400: '#ef5350',
    500: '#f44336',
    600: '#e53935',
    700: '#d32f2f',
    800: '#c62828',
    900: '#b71c1c',
    950: '#7f0000',
  },

  // Green - Success
  green: {
    50: '#e8f5e9',
    100: '#c8e6c9',
    200: '#a5d6a7',
    300: '#81c784',
    400: '#66bb6a',
    500: '#4caf50',
    600: '#77bb3c',
    700: '#388e3c',
    800: '#2e7d32',
    900: '#1b5e20',
    950: '#0d3e10',
  },

  // Blue
  blue: {
    50: '#e3f2fd',
    100: '#bbdefb',
    200: '#90caf9',
    300: '#64b5f6',
    400: '#42a5f5',
    500: '#2196f3',
    600: '#1e88e5',
    700: '#1976d2',
    800: '#1565c0',
    900: '#0d47a1',
    950: '#0a3d8f',
  },
}

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/bemeda_personal_web.ex',
    '../lib/bemeda_personal_web/**/*.*ex',
  ],
  theme: {
    // Complete color system from Figma - no Tailwind defaults
    colors: {
      // Semantic color names only - no duplicate color palettes
      primary: customColors.violet, // Primary brand color - used for main CTAs, links, active states
      secondary: customColors.gray, // Secondary color - used for less prominent elements
      error: customColors.red, // Error states - form validation, error messages, destructive actions
      success: customColors.green, // Success states - success messages, completed states, positive feedback
      warning: customColors.warning, // Warning states - warning messages, alerts, caution
      info: customColors.blue, // Info states - informational messages, tooltips, neutral information

      // Keep gray and blue as base colors (as requested)
      gray: customColors.gray, // General gray scale for UI elements
      blue: customColors.blue, // General blue scale for links, focus states

      // Surface/Background colors from Figma
      background: {
        primary: '#ffffff', // Main background color for pages
        dark: '#0e0e12', // Color/Base/Base Dark - dark mode background
      },
      surface: {
        DEFAULT: '#ffffff', // Surface/Surface primary - card backgrounds, modals
        primary: '#ffffff', // Primary surface color
        secondary: '#f9f9f9', // Secondary surface - alternate row backgrounds, subtle backgrounds
        tertiary: '#f2f2f2', // Tertiary surface - even more subtle backgrounds
        dark: '#1c1c1e', // Dark surface color for dark mode
      },

      // Basic colors
      white: '#ffffff', // Color/Neutrals/White - text on dark backgrounds, white elements
      black: '#000000', // Color/Neutrals/Black - high contrast text, icons
      transparent: 'transparent',
      current: 'currentColor',

      // Strokes and borders
      strokes: '#e0e6ed', // Strokes color - borders, dividers, input borders

      // Special background colors from Figma
      'blue-background': '#f2f1fd', // Color/Base/Blue Background - Used for upload areas, light purple backgrounds
      'profile-avatar': '#f2edf7', // Profile Avatar background color

      // Icon colors (semantic naming for different icon states)
      icon: {
        primary: '#1f1f1f', // Icons/Icons Primary - main icons
        secondary: '#555555', // Icons/Icons Secondary - less prominent icons
        tertiary: '#717171', // Icons/Icons Tertiary - subtle icons
      },

      // Typography colors (for special text that doesn't fit primary/secondary)
      purple: '#7b4eab', // Typography/Purple text - for purple text that isn't a link/button

      // Descriptive colors from Figma (for specific use cases)
      peach: {
        50: '#ffcc99', // Peach-50 - Used for tags/badges related to care services
      },
      pine: {
        100: '#bbdefb', // Pine blue-100 - Used for informational highlights
      },
      'light-blue': {
        300: '#00bcd4', // Light blue-300 - Used for links/interactive elements in specific contexts
      },
    },
    extend: {
      fontFamily: {
        sans: [
          'Inter',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          'Segoe UI',
          'Roboto',
          'Helvetica Neue',
          'Arial',
          'sans-serif',
        ],
      },

      // Standardized spacing scale with Figma values
      spacing: {
        xs: '0.5rem', // 8px
        sm: '1rem', // 16px
        md: '1.5rem', // 24px
        lg: '2rem', // 32px
        xl: '3rem', // 48px
        xxl: '4rem', // 64px
        // Figma-specific spacing values
        1: '0.25rem', // 4px - from Figma Spacing token
        2: '0.5rem', // 8px - from Figma Numbers/Spacing/8 Px
        4: '1rem', // 16px - from Figma Horizontal padding
        8: '2rem', // 32px - from Figma Vertical padding
      },

      // Typography scale with Figma values
      fontSize: {
        h1: ['3rem', { lineHeight: '1.2', fontWeight: '800' }],
        h2: ['2.25rem', { lineHeight: '1.3', fontWeight: '700' }],
        h3: ['1.875rem', { lineHeight: '1.4', fontWeight: '600' }],
        h4: ['1.5rem', { lineHeight: '1.4', fontWeight: '600' }],
        h5: ['1.25rem', { lineHeight: '1.5', fontWeight: '500' }],
        h6: ['1.125rem', { lineHeight: '1.5', fontWeight: '500' }],
        'body-lg': ['1.125rem', { lineHeight: '1.75' }],
        body: ['1rem', { lineHeight: '1.75' }],
        'body-sm': ['0.875rem', { lineHeight: '1.5' }],
        caption: ['0.75rem', { lineHeight: '1.5' }],
        // Figma typography tokens
        'body-1': ['1rem', { lineHeight: '1.75', fontWeight: '400' }], // Body 1 from Figma
        'subtitle-2': ['0.875rem', { lineHeight: '1.57', fontWeight: '400' }], // Subtitle 2 from Figma
        'figma-caption': ['0.75rem', { lineHeight: '1.33', fontWeight: '400' }], // Caption from Figma
      },

      // Consistent border radius
      borderRadius: {
        none: '0',
        sm: '0.25rem',
        DEFAULT: '0.375rem',
        md: '0.5rem',
        lg: '0.75rem',
        xl: '1rem',
        full: '9999px',
      },

      // Box shadows
      boxShadow: {
        xs: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        sm: '0 1px 3px 0 rgb(0 0 0 / 0.1)',
        DEFAULT: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
        md: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
        lg: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
        xl: '0 25px 50px -12px rgb(0 0 0 / 0.25)',
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({ addVariant }) =>
      addVariant('phx-click-loading', [
        '.phx-click-loading&',
        '.phx-click-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-submit-loading', [
        '.phx-submit-loading&',
        '.phx-submit-loading &',
      ])
    ),
    plugin(({ addVariant }) =>
      addVariant('phx-change-loading', [
        '.phx-change-loading&',
        '.phx-change-loading &',
      ])
    ),

    // Embeds Heroicons (https://heroicons.com) into your app.css bundle
    // See your `CoreComponents.icon/1` for more information.
    //
    plugin(function ({ matchComponents, theme }) {
      let iconsDir = path.join(__dirname, '../deps/heroicons/optimized')
      let values = {}
      let icons = [
        ['', '/24/outline'],
        ['-solid', '/24/solid'],
        ['-mini', '/20/solid'],
        ['-micro', '/16/solid'],
      ]
      icons.forEach(([suffix, dir]) => {
        fs.readdirSync(path.join(iconsDir, dir)).forEach((file) => {
          let name = path.basename(file, '.svg') + suffix
          values[name] = { name, fullPath: path.join(iconsDir, dir, file) }
        })
      })
      matchComponents(
        {
          hero: ({ name, fullPath }) => {
            let content = fs
              .readFileSync(fullPath)
              .toString()
              .replace(/\r?\n|\r/g, '')
            let size = theme('spacing.6')
            if (name.endsWith('-mini')) {
              size = theme('spacing.5')
            } else if (name.endsWith('-micro')) {
              size = theme('spacing.4')
            }
            return {
              [`--hero-${name}`]: `url('data:image/svg+xml;utf8,${content}')`,
              '-webkit-mask': `var(--hero-${name})`,
              mask: `var(--hero-${name})`,
              'mask-repeat': 'no-repeat',
              'background-color': 'currentColor',
              'vertical-align': 'middle',
              display: 'inline-block',
              width: size,
              height: size,
            }
          },
        },
        { values }
      )
    }),
  ],
}
