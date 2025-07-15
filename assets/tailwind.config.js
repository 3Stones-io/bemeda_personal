// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require('tailwindcss/plugin')
const fs = require('fs')
const path = require('path')
const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/bemeda_personal_web.ex',
    '../lib/bemeda_personal_web/**/*.*ex',
  ],
  theme: {
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
      colors: {
        // Primary Violet colors from Figma
        primary: {
          50: '#f7f1fd',
          100: '#efe3fb',
          200: '#e0c7f6',
          300: '#d0acf1',
          400: '#c090ed',
          500: '#b074e8', // Main brand color from Figma
          600: '#9d4ae0',
          700: '#8428d6',
          800: '#6b1fae',
          900: '#521785',
          950: '#380e5d',
        },

        // Violet alias for backwards compatibility
        violet: {
          50: '#f7f1fd',
          100: '#efe3fb',
          200: '#e0c7f6',
          300: '#d0acf1',
          400: '#c090ed',
          500: '#b074e8',
          600: '#9d4ae0',
          700: '#8428d6',
          800: '#6b1fae',
          900: '#521785',
          950: '#380e5d',
        },

        // Gray shades from Figma design
        gray: {
          50: '#f9f9f9',
          100: '#f2f2f2',
          200: '#e6e6e6',
          300: '#d9d9d9',
          400: '#cccccc',
          500: '#bfbfbf',
          600: '#999999',
          700: '#737373',
          800: '#4d4d4d',
          900: '#262626',
          950: '#1a1a1a',
        },

        // Semantic color aliases from Figma
        secondary: colors.gray,
        danger: {
          ...colors.red,
          500: '#ff3b30',
          600: '#c60e00',
        },
        success: {
          ...colors.green,
          500: '#34c759',
          600: '#248a3d',
        },
        warning: {
          ...colors.orange,
          500: '#ff9500',
          600: '#ff6d00',
        },
        info: colors.blue,

        // Surface colors for backgrounds
        surface: {
          DEFAULT: '#ffffff',
          secondary: '#f9f9f9',
          tertiary: '#f2f2f2',
          dark: '#1c1c1e',
        },

        // Additional colors from Figma
        neutral: {
          500: '#2b2b2b',
        },
        strokes: '#e0e6ed',
        chrome: {
          mobile: {
            3: '#f1f3f4',
            5: '#5f6368',
          },
        },
      },

      // Standardized spacing scale
      spacing: {
        xs: '0.5rem', // 8px
        sm: '1rem', // 16px
        md: '1.5rem', // 24px
        lg: '2rem', // 32px
        xl: '3rem', // 48px
        xxl: '4rem', // 64px
      },

      // Typography scale
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
