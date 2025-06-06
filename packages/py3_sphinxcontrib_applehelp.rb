require 'buildsystems/pip'

class Py3_sphinxcontrib_applehelp < Pip
  description 'sphinxcontrib-applehelp is a sphinx extension which outputs Apple help books.'
  homepage 'https://www.sphinx-doc.org/'
  version "2.0.0-#{CREW_PY_VER}"
  license 'BSD'
  compatibility 'all'
  source_url 'SKIP'

  depends_on 'python3' => :build

  no_compile_needed
end
