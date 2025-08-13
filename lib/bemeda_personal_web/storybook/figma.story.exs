defmodule BemedaPersonalWeb.Storybook.Figma do
  use PhoenixStorybook.Story, :page

  @spec doc() :: String.t()
  def doc, do: "Figma Design System References and Tokens"

  @spec render(map()) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 py-8">
      <h1 class="text-4xl font-bold mb-8 text-gray-900">Figma Design System</h1>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4 text-gray-800">Component Library</h2>
        <div class="bg-gray-50 p-4 rounded-lg mb-4">
          <p class="text-sm text-gray-600 mb-2">Reference: Node ID 1956-18958</p>
          <a
            href="https://www.figma.com/design/CLjAFx9B6sKvS709P4JIZ2/Bemeda-Personal-App?node-id=1956-18958"
            target="_blank"
            class="text-primary-600 hover:text-primary-700 font-medium inline-flex items-center"
          >
            View in Figma
            <svg class="w-4 h-4 ml-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
              />
            </svg>
          </a>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4 text-gray-800">Design Tokens</h2>
        <p class="text-sm text-gray-600 mb-6">Reference: Node ID 10-2090</p>

        <h3 class="text-xl font-semibold mb-4 text-gray-700">Color Palette</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 my-6">
          <div class="text-center">
            <div class="bg-primary-500 h-24 rounded-lg mb-2 shadow-sm flex items-center justify-center">
              <span class="text-white font-medium">Primary</span>
            </div>
            <p class="text-sm font-mono text-gray-600">#7b4eab</p>
          </div>
          <div class="text-center">
            <div class="bg-success-500 h-24 rounded-lg mb-2 shadow-sm flex items-center justify-center">
              <span class="text-white font-medium">Success</span>
            </div>
            <p class="text-sm font-mono text-gray-600">#83ce42</p>
          </div>
          <div class="text-center">
            <div class="bg-error-500 h-24 rounded-lg mb-2 shadow-sm flex items-center justify-center">
              <span class="text-white font-medium">Error</span>
            </div>
            <p class="text-sm font-mono text-gray-600">#e74a4a</p>
          </div>
          <div class="text-center">
            <div class="bg-warning-500 h-24 rounded-lg mb-2 shadow-sm flex items-center justify-center">
              <span class="text-white font-medium">Warning</span>
            </div>
            <p class="text-sm font-mono text-gray-600">#ff9800</p>
          </div>
        </div>

        <h3 class="text-xl font-semibold mb-4 text-gray-700">Primary Color Scale</h3>
        <div class="grid grid-cols-5 md:grid-cols-10 gap-2 my-6">
          <div class="text-center">
            <div class="bg-primary-50 h-16 rounded-lg shadow-sm border border-gray-200"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">50</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-100 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">100</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-200 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">200</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-300 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">300</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-400 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">400</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-500 h-16 rounded-lg shadow-sm ring-2 ring-primary-500 ring-offset-2">
            </div>
            <p class="text-xs mt-1 font-bold text-primary-600">500</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-600 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">600</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-700 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">700</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-800 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">800</p>
          </div>
          <div class="text-center">
            <div class="bg-primary-900 h-16 rounded-lg shadow-sm"></div>
            <p class="text-xs mt-1 font-medium text-gray-600">900</p>
          </div>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4 text-gray-800">Typography Scale</h2>
        <p class="text-sm text-gray-600 mb-6">Reference: Node ID 47-1062 - Material Design Scale</p>
        <div class="space-y-8 my-8">
          <div class="border-l-4 border-primary-200 pl-4">
            <h1 class="text-h1 font-light text-gray-900">Heading 1</h1>
            <p class="text-sm text-gray-500 mt-2">96px / 131px line-height / 300 weight</p>
          </div>
          <div class="border-l-4 border-primary-200 pl-4">
            <h2 class="text-h2 font-light text-gray-900">Heading 2</h2>
            <p class="text-sm text-gray-500 mt-2">60px / 82px line-height / 300 weight</p>
          </div>
          <div class="border-l-4 border-primary-200 pl-4">
            <h3 class="text-h3 text-gray-900">Heading 3</h3>
            <p class="text-sm text-gray-500 mt-2">48px / 65px line-height / 400 weight</p>
          </div>
          <div class="border-l-4 border-primary-200 pl-4">
            <h4 class="text-h4 text-gray-900">Heading 4</h4>
            <p class="text-sm text-gray-500 mt-2">34px / 46px line-height / 400 weight</p>
          </div>
          <div class="border-l-4 border-primary-200 pl-4">
            <h5 class="text-h5 text-gray-900">Heading 5</h5>
            <p class="text-sm text-gray-500 mt-2">24px / 33px line-height / 400 weight</p>
          </div>
          <div class="border-l-4 border-primary-200 pl-4">
            <h6 class="text-h6 text-gray-900">Heading 6</h6>
            <p class="text-sm text-gray-500 mt-2">20px / 27px line-height / 400 weight</p>
          </div>
          <div class="border-l-4 border-gray-200 pl-4">
            <p class="text-body-1 text-gray-700">Body 1 - Primary body text for main content</p>
            <p class="text-sm text-gray-500 mt-2">16px / 28px line-height / 400 weight</p>
          </div>
          <div class="border-l-4 border-gray-200 pl-4">
            <p class="text-body-2 text-gray-700">Body 2 - Secondary body text</p>
            <p class="text-sm text-gray-500 mt-2">15px / 20px line-height / 400 weight</p>
          </div>
          <div class="border-l-4 border-gray-200 pl-4">
            <p class="text-caption text-gray-600">Caption - Small text for labels</p>
            <p class="text-sm text-gray-500 mt-2">12px / 16px line-height / 400 weight</p>
          </div>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4 text-gray-800">Spacing System</h2>
        <p class="text-sm text-gray-600 mb-6">Reference: Node ID 10-195 - 4-Point Grid</p>
        <div class="bg-gray-50 p-6 rounded-lg">
          <div class="space-y-3">
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium w-12 text-gray-700">xs</span>
              <div class="bg-primary-200 h-6 rounded" style="width: 8px;"></div>
              <span class="text-sm font-mono text-gray-600">8px</span>
            </div>
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium w-12 text-gray-700">sm</span>
              <div class="bg-primary-300 h-6 rounded" style="width: 16px;"></div>
              <span class="text-sm font-mono text-gray-600">16px</span>
            </div>
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium w-12 text-gray-700">md</span>
              <div class="bg-primary-400 h-6 rounded" style="width: 24px;"></div>
              <span class="text-sm font-mono text-gray-600">24px</span>
            </div>
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium w-12 text-gray-700">lg</span>
              <div class="bg-primary-500 h-6 rounded" style="width: 32px;"></div>
              <span class="text-sm font-mono text-gray-600">32px</span>
            </div>
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium w-12 text-gray-700">xl</span>
              <div class="bg-primary-600 h-6 rounded" style="width: 48px;"></div>
              <span class="text-sm font-mono text-gray-600">48px</span>
            </div>
            <div class="flex items-center gap-4">
              <span class="text-sm font-medium w-12 text-gray-700">xxl</span>
              <div class="bg-primary-700 h-6 rounded" style="width: 64px;"></div>
              <span class="text-sm font-mono text-gray-600">64px</span>
            </div>
          </div>
        </div>
      </section>

      <section class="mb-12">
        <h2 class="text-2xl font-semibold mb-4 text-gray-800">Component Specifications</h2>

        <h3 class="text-xl font-semibold mb-4 text-gray-700">Border Radius</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 my-6">
          <div class="text-center">
            <div
              class="bg-gradient-to-br from-primary-100 to-primary-200 h-20 rounded shadow-sm"
              style="border-radius: 4px;"
            >
            </div>
            <p class="text-sm mt-2 font-medium text-gray-700">Input</p>
            <p class="text-xs text-gray-500">4px</p>
          </div>
          <div class="text-center">
            <div class="bg-gradient-to-br from-primary-200 to-primary-300 h-20 rounded-lg shadow-sm">
            </div>
            <p class="text-sm mt-2 font-medium text-gray-700">Button</p>
            <p class="text-xs text-gray-500">8px</p>
          </div>
          <div class="text-center">
            <div class="bg-gradient-to-br from-primary-300 to-primary-400 h-20 rounded-xl shadow-sm">
            </div>
            <p class="text-sm mt-2 font-medium text-gray-700">Card</p>
            <p class="text-xs text-gray-500">12px</p>
          </div>
          <div class="text-center">
            <div class="bg-gradient-to-br from-primary-400 to-primary-500 h-20 rounded-2xl shadow-sm">
            </div>
            <p class="text-sm mt-2 font-medium text-gray-700">Modal</p>
            <p class="text-xs text-gray-500">16px</p>
          </div>
        </div>

        <h3 class="text-xl font-semibold mb-4 text-gray-700 mt-8">Box Shadows</h3>
        <div class="space-y-6 my-6">
          <div class="bg-white p-6 rounded-xl shadow-card border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="font-semibold text-gray-800">Card Shadow</p>
                <p class="text-sm font-mono text-gray-500 mt-1">shadow-card</p>
              </div>
              <div class="text-right">
                <p class="text-xs text-gray-600">0 2px 8px</p>
                <p class="text-xs text-gray-500">rgba(0, 0, 0, 0.1)</p>
              </div>
            </div>
          </div>
          <div class="bg-white p-6 rounded-2xl shadow-modal border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="font-semibold text-gray-800">Modal Shadow</p>
                <p class="text-sm font-mono text-gray-500 mt-1">shadow-modal</p>
              </div>
              <div class="text-right">
                <p class="text-xs text-gray-600">0 4px 16px</p>
                <p class="text-xs text-gray-500">rgba(0, 0, 0, 0.15)</p>
              </div>
            </div>
          </div>
          <div class="bg-white p-6 rounded-lg shadow-dropdown border border-gray-100">
            <div class="flex items-center justify-between">
              <div>
                <p class="font-semibold text-gray-800">Dropdown Shadow</p>
                <p class="text-sm font-mono text-gray-500 mt-1">shadow-dropdown</p>
              </div>
              <div class="text-right">
                <p class="text-xs text-gray-600">0 2px 12px</p>
                <p class="text-xs text-gray-500">rgba(0, 0, 0, 0.12)</p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
