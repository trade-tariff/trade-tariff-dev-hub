// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { initAll } from 'govuk-frontend'

const ONE_YEAR_SECONDS = 60 * 60 * 24 * 365

function metaContent(name) {
  const el = document.querySelector('meta[name="' + name + '"]')
  return el ? el.getAttribute('content') : null
}

// Names mirror the Ruby constants in TradeTariffDevHub. Fallbacks preserve behaviour
// on pages rendered before the meta tags existed or if a meta tag is accidentally removed.
const COOKIES_POLICY = metaContent('analytics-policy-cookie') || 'cookies_policy'
const COOKIES_PREFERENCES_SET = metaContent('analytics-preferences-cookie') || 'cookies_preferences_set'
const ANALYTICS_COOKIE_PREFIXES = (metaContent('analytics-cookie-prefixes') || '_ga,_gat,_gid')
  .split(',')
  .map((p) => p.trim())
  .filter(Boolean)
const ANALYTICS_COOKIE_DELETE_DOMAINS = (
  metaContent('analytics-cookie-delete-domains') || fallbackAnalyticsCookieDeleteDomains()
)
  .split(',')
  .map((d) => d.trim())
  .filter(Boolean)

function readCookie(name) {
  const match = document.cookie.match(new RegExp('(?:^|; )' + name.replace(/[-.$?*|{}()[\]\\/+^]/g, '\\$&') + '=([^;]*)'))
  return match ? decodeURIComponent(match[1]) : null
}

function writeCookie(name, value, maxAgeSeconds) {
  const attrs = [
    'path=/',
    'max-age=' + maxAgeSeconds,
    'SameSite=Lax',
  ]
  if (window.location.protocol === 'https:') attrs.push('Secure')
  document.cookie = name + '=' + encodeURIComponent(value) + ';' + attrs.join(';')
}

function readCookiesPolicy() {
  const raw = readCookie(COOKIES_POLICY)
  if (!raw) return null
  try {
    return JSON.parse(raw)
  } catch (_e) {
    return null
  }
}

function writeCookiesPolicy(policy) {
  writeCookie(COOKIES_POLICY, JSON.stringify(policy), ONE_YEAR_SECONDS)
}

function fallbackAnalyticsCookieDeleteDomains() {
  const host = window.location.hostname
  const baseDomain = host.split('.').slice(-2).join('.')
  return [host, '.' + host, '.' + baseDomain].join(',')
}

function deleteAnalyticsCookies() {
  document.cookie.split(';').forEach((c) => {
    const name = c.split('=')[0].trim()
    if (!ANALYTICS_COOKIE_PREFIXES.some((prefix) => name.startsWith(prefix))) return

    ANALYTICS_COOKIE_DELETE_DOMAINS.forEach((d) => {
      document.cookie = name + '=; path=/; domain=' + d + '; expires=Thu, 01 Jan 1970 00:00:01 GMT'
    })
    document.cookie = name + '=; path=/; expires=Thu, 01 Jan 1970 00:00:01 GMT'
  })
}

function initCookieBanner() {
  const root = document.querySelector('[data-cookies-banner="root"]')
  if (!root) return

  const sections = {
    ask: root.querySelector('[data-cookies-banner="ask"]'),
    accepted: root.querySelector('[data-cookies-banner="accepted"]'),
    rejected: root.querySelector('[data-cookies-banner="rejected"]'),
  }

  const show = (key) => {
    root.hidden = false
    Object.entries(sections).forEach(([name, el]) => {
      if (!el) return
      el.hidden = name !== key
    })
  }

  const hide = () => {
    root.hidden = true
    Object.values(sections).forEach((el) => { if (el) el.hidden = true })
  }

  const policy = readCookiesPolicy()
  const preferencesSet = readCookie(COOKIES_PREFERENCES_SET) === 'true'

  if (!policy) {
    show('ask')
  } else if (!preferencesSet) {
    show(policy.usage ? 'accepted' : 'rejected')
  } else {
    hide()
  }

  root.addEventListener('click', (event) => {
    const target = event.target.closest('[data-cookies-banner-action]')
    if (!target) return
    event.preventDefault()
    const action = target.getAttribute('data-cookies-banner-action')

    if (action === 'accept') {
      writeCookiesPolicy({ usage: true, remember_settings: true })
      show('accepted')
      // Reload so the server injects the GTM snippet on the next render. This is a
      // deliberate choice over client-side GTM injection to keep a single (server-rendered,
      // CSP-nonced) code path for the snippet. Cost is one extra request on first accept.
      window.location.reload()
    } else if (action === 'reject') {
      writeCookiesPolicy({ usage: false, remember_settings: false })
      deleteAnalyticsCookies()
      show('rejected')
    } else if (action === 'hide') {
      writeCookie(COOKIES_PREFERENCES_SET, 'true', ONE_YEAR_SECONDS)
      hide()
    }
  })
}

document.addEventListener('DOMContentLoaded', () => {
  initAll();
  initCookieBanner();

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
