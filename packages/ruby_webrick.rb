require 'buildsystems/ruby'

class Ruby_webrick < RUBY
  description 'WEBrick is an HTTP server toolkit that can be configured as an HTTPS server, a proxy server, and a virtual-host server.'
  homepage 'https://github.com/ruby/webrick/'
  version "1.9.1-#{CREW_RUBY_VER}"
  license 'BSD-2'
  compatibility 'all'
  source_url 'SKIP'

  no_compile_needed
end
