require 'package'

class Uget < Package
  description 'Open Source Download Manager'
  homepage 'https://ugetdm.com/'
  version '2.2.1'
  license 'LGPL-2.1'
  compatibility 'aarch64 armv7l x86_64'
  source_url 'https://prdownloads.sourceforge.net/project/urlget/uget%20%28stable%29/2.2.1/uget-2.2.1.tar.gz'
  source_sha256 '445cf58799a9a06e08cd4180b172f4b0a8a8c2ee82da732bdfe2dd502d949936'
  binary_compression 'tar.xz'

  binary_sha256({
    aarch64: 'ca69d322f0584a63365f90a390adc5b5c543fc8554091f27b23b8cdd2dc60a5a',
     armv7l: 'ca69d322f0584a63365f90a390adc5b5c543fc8554091f27b23b8cdd2dc60a5a',
     x86_64: 'e75eeddfb77a1d22fbe9ff38b20b65a2e85862b22812f78296a4f760f44a0854'
  })

  depends_on 'curl'
  depends_on 'gtk3'
  depends_on 'libnotify'
  depends_on 'gstreamer'
  depends_on 'shared_mime_info'
  depends_on 'gnome_icon_theme'
  depends_on 'hicolor_icon_theme'
  depends_on 'sommelier'

  def self.build
    system './configure',
           "--prefix=#{CREW_PREFIX}",
           "--libdir=#{CREW_LIB_PREFIX}"
    system 'make'
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install'
    system "ln -sf #{CREW_PREFIX}/bin/uget-gtk #{CREW_DEST_PREFIX}/bin/uget"
  end
end
