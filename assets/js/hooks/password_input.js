export default PasswordInput = {
  mounted() {
    const hook = this
    const passwordInputContainer = hook.el
    const passwordInputIcon = passwordInputContainer.querySelector('.hero-eye')
    const passwordInputIconSlash =
      passwordInputContainer.querySelector('.hero-eye-slash')
    const passwordInput = passwordInputContainer.querySelector('input')

    passwordInputIcon.addEventListener('click', () => {
      passwordInput.type = 'text'
      passwordInputIcon.classList.add('hidden')
      passwordInputIconSlash.classList.remove('hidden')
    })

    passwordInputIconSlash.addEventListener('click', () => {
      passwordInput.type = 'password'
      passwordInputIcon.classList.remove('hidden')
      passwordInputIconSlash.classList.add('hidden')
    })
  },
}
