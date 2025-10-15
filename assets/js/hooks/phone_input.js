import {
  parsePhoneNumberFromString,
  getCountryCallingCode,
} from 'libphonenumber-js'

export default PhoneInput = {
  mounted() {
    const hook = this
    const container = hook.el
    const phoneInputId = container.dataset.phoneInputId

    const hiddenInput = container.querySelector(`#${phoneInputId}`)
    const promptButton = container.querySelector(
      `#country-code-prompt-${phoneInputId}`
    )
    const promptText = promptButton.querySelector('.prompt-text')
    const chevronIcon = container.querySelector(
      `#country-code-chevron-${phoneInputId}`
    )
    const dropdownContainer = container.querySelector(
      `#country-code-dropdown-container-${phoneInputId}`
    )
    const optionsList = container.querySelector(
      `#country-code-options-list-${phoneInputId}`
    )
    const optionsItems = Array.from(optionsList.children)
    const searchInput = container.querySelector(
      `#country-code-search-${phoneInputId}`
    )
    const telInput = container.querySelector('.country-code-input')

    this.selectedCode = null
    this.selectedCountryISO = null

    this.initializeCountryCode(hiddenInput, promptText, optionsItems)

    promptButton.addEventListener('click', (event) => {
      event.preventDefault()
      event.stopPropagation()
      this.toggleDropdown(
        dropdownContainer,
        chevronIcon,
        promptButton,
        searchInput
      )
    })

    searchInput.addEventListener('input', (event) => {
      const searchValue = event.target.value.toLowerCase().trim()
      this.filterOptions(searchValue, optionsItems)
    })

    optionsItems.forEach((option) => {
      option.addEventListener('click', (event) => {
        const listItem = event.target.closest('li')
        const selectedCode = listItem.dataset.countryCode
        const selectedFlag = listItem.dataset.countryFlag
        const selectedName = listItem.dataset.countryName

        this.selectedCode = selectedCode
        this.selectedCountryISO = this.getCountryISOFromCode(selectedCode)
        promptText.innerHTML = `<span class="text-base">${selectedFlag}</span><span>${selectedCode}</span>`

        this.closeDropdown(
          dropdownContainer,
          chevronIcon,
          promptButton,
          searchInput
        )
        this.formatAndUpdatePhone(hiddenInput, telInput)
      })
    })

    telInput.addEventListener('blur', () => {
      if (this.selectedCode) {
        this.formatAndUpdatePhone(hiddenInput, telInput)
      }
    })

    telInput.addEventListener('input', (event) => {
      const cursorPosition = event.target.selectionStart
      const oldValue = event.target.value

      const newValue = oldValue.replace(/[^\d\s\-()]/g, '')

      if (oldValue !== newValue) {
        event.target.value = newValue
        event.target.setSelectionRange(cursorPosition - 1, cursorPosition - 1)
      }
    })

    document.addEventListener('click', (event) => {
      if (!container.contains(event.target)) {
        this.closeDropdown(
          dropdownContainer,
          chevronIcon,
          promptButton,
          searchInput
        )
      }
    })
  },

  initializeCountryCode(hiddenInput, promptText, optionsItems) {
    const hiddenValue = hiddenInput.value.trim()
    let countryCode = '+41'

    if (hiddenValue) {
      const phoneNumber = parsePhoneNumberFromString(hiddenValue)
      if (phoneNumber) {
        countryCode = '+' + phoneNumber.countryCallingCode
        this.selectedCountryISO = phoneNumber.country
      } else {
        const match = hiddenValue.match(/^\+\d{1,4}/)
        if (match) {
          countryCode = match[0]
        }
      }
    }

    const matchingCountry = optionsItems.find(
      (item) => item.dataset.countryCode === countryCode
    )

    if (matchingCountry) {
      const flag = matchingCountry.dataset.countryFlag
      const code = matchingCountry.dataset.countryCode
      this.selectedCode = code
      this.selectedCountryISO = this.getCountryISOFromCode(code)
      promptText.innerHTML = `<span class="text-base">${flag}</span><span>${code}</span>`

      if (!hiddenValue) {
        hiddenInput.value = code
      }
    } else {
      const swissCountry = optionsItems.find(
        (item) => item.dataset.countryCode === '+41'
      )
      if (swissCountry) {
        const flag = swissCountry.dataset.countryFlag
        this.selectedCode = '+41'
        this.selectedCountryISO = 'CH'
        promptText.innerHTML = `<span class="text-base">${flag}</span><span>+41</span>`
        hiddenInput.value = '+41'
      }
    }
  },

  toggleDropdown(dropdownContainer, chevronIcon, promptButton, searchInput) {
    const isHidden = dropdownContainer.classList.contains('hidden')

    if (isHidden) {
      dropdownContainer.classList.remove('hidden')
      chevronIcon.classList.add('rotate-180')
      promptButton.classList.remove('border-form-input-border')
      promptButton.classList.add('border-form-border-focus')

      setTimeout(() => searchInput.focus(), 100)
    } else {
      this.closeDropdown(
        dropdownContainer,
        chevronIcon,
        promptButton,
        searchInput
      )
    }
  },

  closeDropdown(dropdownContainer, chevronIcon, promptButton, searchInput) {
    dropdownContainer.classList.add('hidden')
    chevronIcon.classList.remove('rotate-180')
    promptButton.classList.add('border-form-input-border')
    promptButton.classList.remove('border-form-border-focus')

    searchInput.value = ''

    const optionsList = dropdownContainer.querySelector('ul')
    const optionsItems = Array.from(optionsList.children)
    optionsItems.forEach((option) => {
      option.classList.remove('hidden')
    })
  },

  filterOptions(searchValue, optionsItems) {
    if (!searchValue) {
      optionsItems.forEach((option) => {
        option.classList.remove('hidden')
      })
      return
    }

    optionsItems.forEach((option) => {
      const countryName = option.dataset.countryName.toLowerCase()
      const countryCode = option.dataset.countryCode.toLowerCase()

      if (
        countryName.includes(searchValue) ||
        countryCode.includes(searchValue)
      ) {
        option.classList.remove('hidden')
      } else {
        option.classList.add('hidden')
      }
    })
  },

  formatAndUpdatePhone(hiddenInput, telInput) {
    const rawNumber = telInput.value.trim()

    if (!rawNumber) {
      hiddenInput.value = this.selectedCode
      hiddenInput.dispatchEvent(new Event('input', { bubbles: true }))
      return
    }

    let digitsOnly = rawNumber.replace(/[^\d]/g, '')
    let cleanNumber = digitsOnly.replace(/^0+(?=\d)/, '')

    if (!cleanNumber && digitsOnly) {
      cleanNumber = digitsOnly
    }

    let phoneNumber

    if (this.selectedCountryISO) {
      phoneNumber = parsePhoneNumberFromString(
        cleanNumber,
        this.selectedCountryISO
      )

      if (!phoneNumber) {
        phoneNumber = parsePhoneNumberFromString(
          this.selectedCode + cleanNumber,
          this.selectedCountryISO
        )
      }
    }

    if (!phoneNumber) {
      phoneNumber = parsePhoneNumberFromString(this.selectedCode + cleanNumber)
    }

    if (phoneNumber && phoneNumber.isValid()) {
      const e164Number = phoneNumber.format('E.164')
      hiddenInput.value = e164Number

      const nationalFormat = phoneNumber.formatNational()
      telInput.value = nationalFormat
    } else {
      if (cleanNumber) {
        hiddenInput.value = `${this.selectedCode}${cleanNumber}`
      } else {
        hiddenInput.value = this.selectedCode
      }
    }

    hiddenInput.dispatchEvent(new Event('input', { bubbles: true }))
  },

  getCountryISOFromCode(countryCode) {
    const codeToISO = {
      '+1': 'US',
      '+7': 'RU',
      '+20': 'EG',
      '+27': 'ZA',
      '+30': 'GR',
      '+31': 'NL',
      '+32': 'BE',
      '+33': 'FR',
      '+34': 'ES',
      '+36': 'HU',
      '+39': 'IT',
      '+40': 'RO',
      '+41': 'CH',
      '+43': 'AT',
      '+44': 'GB',
      '+45': 'DK',
      '+46': 'SE',
      '+47': 'NO',
      '+48': 'PL',
      '+49': 'DE',
      '+51': 'PE',
      '+52': 'MX',
      '+53': 'CU',
      '+54': 'AR',
      '+55': 'BR',
      '+56': 'CL',
      '+57': 'CO',
      '+58': 'VE',
      '+60': 'MY',
      '+61': 'AU',
      '+62': 'ID',
      '+63': 'PH',
      '+64': 'NZ',
      '+65': 'SG',
      '+66': 'TH',
      '+81': 'JP',
      '+82': 'KR',
      '+84': 'VN',
      '+86': 'CN',
      '+90': 'TR',
      '+91': 'IN',
      '+92': 'PK',
      '+93': 'AF',
      '+94': 'LK',
      '+95': 'MM',
      '+98': 'IR',
      '+212': 'MA',
      '+213': 'DZ',
      '+216': 'TN',
      '+218': 'LY',
      '+220': 'GM',
      '+221': 'SN',
      '+222': 'MR',
      '+223': 'ML',
      '+224': 'GN',
      '+225': 'CI',
      '+226': 'BF',
      '+227': 'NE',
      '+228': 'TG',
      '+229': 'BJ',
      '+230': 'MU',
      '+231': 'LR',
      '+232': 'SL',
      '+233': 'GH',
      '+234': 'NG',
      '+235': 'TD',
      '+236': 'CF',
      '+237': 'CM',
      '+238': 'CV',
      '+239': 'ST',
      '+240': 'GQ',
      '+241': 'GA',
      '+242': 'CG',
      '+243': 'CD',
      '+244': 'AO',
      '+245': 'GW',
      '+248': 'SC',
      '+249': 'SD',
      '+250': 'RW',
      '+251': 'ET',
      '+252': 'SO',
      '+253': 'DJ',
      '+254': 'KE',
      '+255': 'TZ',
      '+256': 'UG',
      '+257': 'BI',
      '+258': 'MZ',
      '+260': 'ZM',
      '+261': 'MG',
      '+263': 'ZW',
      '+264': 'NA',
      '+265': 'MW',
      '+266': 'LS',
      '+267': 'BW',
      '+268': 'SZ',
      '+269': 'KM',
      '+350': 'GI',
      '+351': 'PT',
      '+352': 'LU',
      '+353': 'IE',
      '+354': 'IS',
      '+355': 'AL',
      '+356': 'MT',
      '+357': 'CY',
      '+358': 'FI',
      '+359': 'BG',
      '+370': 'LT',
      '+371': 'LV',
      '+372': 'EE',
      '+373': 'MD',
      '+374': 'AM',
      '+375': 'BY',
      '+376': 'AD',
      '+377': 'MC',
      '+378': 'SM',
      '+379': 'VA',
      '+380': 'UA',
      '+381': 'RS',
      '+382': 'ME',
      '+385': 'HR',
      '+386': 'SI',
      '+387': 'BA',
      '+389': 'MK',
      '+420': 'CZ',
      '+421': 'SK',
      '+423': 'LI',
      '+500': 'FK',
      '+501': 'BZ',
      '+502': 'GT',
      '+503': 'SV',
      '+504': 'HN',
      '+505': 'NI',
      '+506': 'CR',
      '+507': 'PA',
      '+509': 'HT',
      '+591': 'BO',
      '+592': 'GY',
      '+593': 'EC',
      '+595': 'PY',
      '+597': 'SR',
      '+598': 'UY',
      '+670': 'TL',
      '+673': 'BN',
      '+674': 'NR',
      '+675': 'PG',
      '+676': 'TO',
      '+677': 'SB',
      '+678': 'VU',
      '+679': 'FJ',
      '+680': 'PW',
      '+685': 'WS',
      '+686': 'KI',
      '+688': 'TV',
      '+691': 'FM',
      '+692': 'MH',
      '+850': 'KP',
      '+852': 'HK',
      '+853': 'MO',
      '+855': 'KH',
      '+856': 'LA',
      '+880': 'BD',
      '+886': 'TW',
      '+960': 'MV',
      '+961': 'LB',
      '+962': 'JO',
      '+963': 'SY',
      '+964': 'IQ',
      '+965': 'KW',
      '+966': 'SA',
      '+967': 'YE',
      '+968': 'OM',
      '+971': 'AE',
      '+972': 'IL',
      '+973': 'BH',
      '+974': 'QA',
      '+975': 'BT',
      '+976': 'MN',
      '+977': 'NP',
      '+992': 'TJ',
      '+993': 'TM',
      '+994': 'AZ',
      '+995': 'GE',
      '+996': 'KG',
      '+998': 'UZ',
      '+1242': 'BS',
      '+1246': 'BB',
      '+1268': 'AG',
      '+1284': 'VG',
      '+1340': 'VI',
      '+1441': 'BM',
      '+1473': 'GD',
      '+1649': 'TC',
      '+1664': 'MS',
      '+1670': 'MP',
      '+1671': 'GU',
      '+1684': 'AS',
      '+1758': 'LC',
      '+1767': 'DM',
      '+1784': 'VC',
      '+1809': 'DO',
      '+1829': 'DO',
      '+1849': 'DO',
      '+1868': 'TT',
      '+1869': 'KN',
      '+1876': 'JM',
    }

    return codeToISO[countryCode] || null
  },
}
