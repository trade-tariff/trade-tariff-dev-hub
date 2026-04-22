# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data,
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com",
                       "https://*.google-analytics.com",
                       "https://*.analytics.google.com"
    policy.object_src  :none
    policy.script_src  :self, :https,
                       "https://www.googletagmanager.com",
                       "https://www.google-analytics.com"
    policy.connect_src :self,
                       "https://www.google-analytics.com",
                       "https://*.analytics.google.com",
                       "https://*.googletagmanager.com",
                       "https://*.google-analytics.com"
    policy.frame_src   :self, "https://www.googletagmanager.com"
    policy.style_src   :self, :https
    # Specify URI for violation reports
    policy.report_uri "/csp-violation-report"
  end

  # Generate session nonces for permitted importmap, inline scripts, and inline styles.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
  config.content_security_policy_nonce_directives = %w[script-src style-src]

  # Report violations without enforcing the policy.
  config.content_security_policy_report_only = true
end
