const PhoneInput = {
  mounted() {
    const hook = this
    const el = hook.el
    const countryCodes = JSON.parse(el.dataset.countryCodes)
    const dropdown = el.querySelector('[id$="_dropdown"]')
    const hiddenInput = el.querySelector('input[type="hidden"]')
    const phoneInput = el.querySelector('input[type="tel"]')
    const defaultSelectedCode = el.dataset.defaultSelectedCode
    const buttonEl = el.querySelector('[id$="-button"]')
    const countryFlagEl = buttonEl.querySelector('.country-flag')
    const countryCodeEl = buttonEl.querySelector('.country-code')

    let phoneNumber
    let countryCode

    const getCountryCodeAndFlag = code => {
      countryFlagEl.textContent = countryCodes[code].flag
      countryCodeEl.textContent = code
    }

    dropdown.addEventListener('click', (event) => {
      event.preventDefault()
      getCountryCodeAndFlag(event.target.dataset.countryCode.trim())
      countryCode = event.target.dataset.countryCode.trim()
    })


    phoneInput.addEventListener('input', (event) => {
      if (countryCode && event.target.value.length > 0) {
        phoneNumber = countryCode + event.target.value.trim()
        hiddenInput.value = phoneNumber
        hiddenInput.dispatchEvent(new Event('input', { bubbles: true }))
      } else if (event.target.value.length > 0) {   
        phoneNumber = defaultSelectedCode + event.target.value.trim()
        hiddenInput.value = phoneNumber
        hiddenInput.dispatchEvent(new Event('input', { bubbles: true }))
      }
    }) 
  }
};

export default PhoneInput;
