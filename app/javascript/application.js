// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { initAll } from 'govuk-frontend'

document.addEventListener('DOMContentLoaded', () => {
  initAll();

  const legacyButton = document.getElementById('copy-to-clipboard')
  const legacyTarget = document.getElementById('api-key-secret')

  legacyButton?.addEventListener('click', () => {
    navigator.clipboard.writeText(legacyTarget.textContent)
      .then(() => {
        legacyButton.textContent = 'Copied!'
        setTimeout(() => legacyButton.textContent = 'Copy to clipboard', 1500)
      })
      .catch(err => console.error('Failed to copy:', err))
  })

  document.querySelectorAll('[data-copy-target]').forEach((copyButton) => {
    copyButton.addEventListener('click', () => {
      const targetId = copyButton.getAttribute('data-copy-target')
      const copyTarget = document.getElementById(targetId)
      const copyText = copyTarget?.textContent
      if (!copyText) return

      const originalLabel = copyButton.textContent
      navigator.clipboard.writeText(copyText)
        .then(() => {
          copyButton.textContent = 'Copied!'
          setTimeout(() => (copyButton.textContent = originalLabel), 1500)
        })
        .catch(err => console.error('Failed to copy:', err))
    })
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
