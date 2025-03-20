// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import 'govuk-frontend'

document.addEventListener('DOMContentLoaded', () => {
  GOVUKFrontend.initAll();

  const button = document.getElementById('copy-to-clipboard')
  const target = document.getElementById('api-key-id')

  button?.addEventListener('click', () => {
    navigator.clipboard.writeText(target.textContent)
      .then(() => {
        button.textContent = 'Copied!'
        setTimeout(() => button.textContent = 'Copy to clipboard', 1500)
      })
      .catch(err => console.error('Failed to copy:', err))
  })
})
