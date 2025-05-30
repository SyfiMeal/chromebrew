require 'package'

class Xorg_libinput_driver < Package
  description 'The X.Org Libinput Driver is a thin wrapper around libinput and allows for libinput to be used for input devices in X. This driver can be used as drop-in replacement for evdev and synaptics.'
  homepage 'https://www.x.org/wiki/'
  version '0.27.1'
  license 'ISC'
  compatibility 'aarch64 armv7l x86_64'
  source_url 'https://www.x.org/pub/individual/driver/xf86-input-libinput-0.27.1.tar.bz2'
  source_sha256 'd4ad8dc5ad6f962a3f15f61ba9e9f8e37fa0b57eee9f484e2bd721d60ca72ee6'
  binary_compression 'tar.xz'

  binary_sha256({
    aarch64: 'a053e2e55ad706913c2cafcca3a4f6da585e315c672bebafadc6844dc75f3663',
     armv7l: 'a053e2e55ad706913c2cafcca3a4f6da585e315c672bebafadc6844dc75f3663',
     x86_64: 'f3687b252e47e08cabe31e7c7d09f00c456b875eaa0826b2de446d70674c4727'
  })

  depends_on 'libinput'
  depends_on 'xorg_server' => :build

  def self.build
    system './configure',
           "--prefix=#{CREW_PREFIX}",
           "--libdir=#{CREW_LIB_PREFIX}",
           '--enable-shared',
           '--disable-static'
    system 'make'
  end

  def self.check
    system "make -j#{CREW_NPROC} check"
  end

  def self.install
    system 'make', "DESTDIR=#{CREW_DEST_DIR}", 'install-strip'
  end
end
