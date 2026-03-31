# CORS — Cross-Origin Resource Sharing
#
# The browser's same-origin policy blocks JavaScript from making requests
# to a different origin (protocol + domain + port) than the page it's on.
# Next.js on localhost:3000 calling Rails on localhost:3001 = cross-origin = blocked.
#
# rack-cors adds middleware at the very front of the Rails stack (position 0)
# so it intercepts every request before anything else runs and attaches the
# appropriate Access-Control-* headers to the response.
#
# In production: replace the origins list with your actual deployed domains.
# Never use origins "*" (wildcard) with credentials: true — browsers reject it.

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Set FRONTEND_URL in your environment to your deployed domain.
    # e.g. FRONTEND_URL=https://chatterly.vercel.app
    origins ENV.fetch("FRONTEND_URL", "http://localhost:3000")

    resource "*",
      # Accept any headers the client sends (including Authorization for JWT)
      headers: :any,

      # HTTP methods our API uses — OPTIONS is required for preflight requests.
      # Before every cross-origin POST/PATCH/DELETE, the browser sends an OPTIONS
      # "preflight" request asking "are you OK with this?" — Rails must respond 200.
      methods: %i[get post put patch delete options head],

      # credentials: true allows the browser to include the Authorization header.
      # Without this, JWT tokens in headers get stripped on cross-origin requests.
      credentials: true,

      # expose: tells the browser which response headers JavaScript is allowed to read.
      # Authorization must be exposed because devise-jwt returns the JWT token
      # in the response header after login/register — our frontend reads it from there.
      expose: [ "Authorization" ]
  end
end
