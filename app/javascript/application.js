// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { initAll } from 'govuk-frontend'

document.addEventListener('DOMContentLoaded', () => {
  initAll();

  const button = document.getElementById('copy-to-clipboard')
  const target = document.getElementById('api-key-secret')

  button?.addEventListener('click', () => {
    navigator.clipboard.writeText(target.textContent)
      .then(() => {
        button.textContent = 'Copied!'
        setTimeout(() => button.textContent = 'Copy to clipboard', 1500)
      })
      .catch(err => console.error('Failed to copy:', err))
  })

  // Show/hide FPO-specific content based on role selection
  const roleSelect = document.getElementById('role_request_role_name')
  const fpoHintContent = document.getElementById('fpo-hint-content')

  if (roleSelect && fpoHintContent) {
    const toggleFpoContent = () => {
      if (roleSelect.value === 'fpo:full') {
        fpoHintContent.style.display = 'inline'
      } else {
        fpoHintContent.style.display = 'none'
      }
    }

    // Set initial state
    toggleFpoContent()

    // Listen for changes
    roleSelect.addEventListener('change', toggleFpoContent)
  }
})
