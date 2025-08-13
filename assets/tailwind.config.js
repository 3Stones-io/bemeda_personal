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
    '../lib/bemeda_personal_web/**/*.exs',
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

      // 4-point grid spacing system from Figma
      spacing: {
        // Semantic spacing names
        xs: '0.5rem', // 8px
        sm: '1rem', // 16px
        md: '1.5rem', // 24px
        lg: '2rem', // 32px
        xl: '3rem', // 48px
        xxl: '4rem', // 64px
        // 4-point grid values (4px increments)
        1: '4px',
        2: '8px',
        3: '12px',
        4: '16px',
        5: '20px',
        6: '24px',
        7: '28px',
        8: '32px',
        9: '36px',
        10: '40px',
        11: '44px',
        12: '48px',
        13: '52px',
        14: '56px',
        15: '60px',
        16: '64px',
        17: '68px', // From Figma node 10-195
        18: '72px', // From Figma node 10-195
        19: '76px', // From Figma node 10-195
        20: '80px', // From Figma node 10-195
      },

      // Typography scale from Figma Material Design
      fontSize: {
        // Headlines from Figma node 47-1062
        h1: ['96px', { lineHeight: '131px', fontWeight: '300' }], // Light weight
        h2: ['60px', { lineHeight: '82px', fontWeight: '300' }], // Light weight
        h3: ['48px', { lineHeight: '65px', fontWeight: '400' }], // Regular weight
        h4: ['34px', { lineHeight: '46px', fontWeight: '400' }], // Regular weight
        h5: ['24px', { lineHeight: '33px', fontWeight: '400' }], // Regular weight
        h6: ['20px', { lineHeight: '27px', fontWeight: '400' }], // Regular weight
        // Subtitles from Figma
        'subtitle-1': ['16px', { lineHeight: '28px', fontWeight: '400' }],
        'subtitle-2': ['14px', { lineHeight: '22px', fontWeight: '400' }],
        // Body text from Figma
        'body-1': ['16px', { lineHeight: '28px', fontWeight: '400' }],
        'body-2': ['15px', { lineHeight: '20px', fontWeight: '400' }],
        // Caption from Figma
        caption: ['12px', { lineHeight: '16px', fontWeight: '400' }],
        // Keep legacy aliases for backward compatibility
        'body-lg': ['1.125rem', { lineHeight: '1.75' }],
        body: ['1rem', { lineHeight: '1.75' }],
        'body-sm': ['0.875rem', { lineHeight: '1.5' }],
      },

      // Border radius tokens from Figma design system
      borderRadius: {
        none: '0',
        sm: '0.25rem',
        DEFAULT: '0.375rem',
        md: '0.5rem',
        lg: '0.75rem',
        xl: '1rem',
        full: '9999px',
        // Component-specific radius
        button: '8px',
        input: '4px',
        card: '12px',
        modal: '16px',
      },

      // Box shadows from Figma design system
      boxShadow: {
        xs: '0 1px 2px 0 rgb(0 0 0 / 0.05)',
        sm: '0 1px 3px 0 rgb(0 0 0 / 0.1)',
        DEFAULT: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
        md: '0 10px 15px -3px rgb(0 0 0 / 0.1)',
        lg: '0 20px 25px -5px rgb(0 0 0 / 0.1)',
        xl: '0 25px 50px -12px rgb(0 0 0 / 0.25)',
        // Component-specific shadows
        card: '0 2px 8px rgba(0, 0, 0, 0.1)',
        modal: '0 4px 16px rgba(0, 0, 0, 0.15)',
        dropdown: '0 2px 12px rgba(0, 0, 0, 0.12)',
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
