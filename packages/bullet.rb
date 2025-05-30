require 'package'

class Bullet < Package
  description '3D Collision Detection and Rigid Body Dynamics Library'
  homepage 'https://pybullet.org/Bullet/phpBB3/'
  version '2.89'
  license 'ZLIB'
  compatibility 'aarch64 armv7l x86_64'
  source_url 'https://github.com/bulletphysics/bullet3/archive/2.89.tar.gz'
  source_sha256 '621b36e91c0371933f3c2156db22c083383164881d2a6b84636759dc4cbb0bb8'
  binary_compression 'tar.xz'

  binary_sha256({
    aarch64: 'de8d4c188438087d438173aa33cea512deadc88e1c3f94cd6b9932c389b46d47',
     armv7l: 'de8d4c188438087d438173aa33cea512deadc88e1c3f94cd6b9932c389b46d47',
     x86_64: 'a864c0d9f5429c0a5bff7e4a38b5367820ca3bf110f9baacff5b3b5306114b09'
  })

  depends_on 'bdftopcf'
  depends_on 'libglu'
  depends_on 'openvr'

  def self.build
    Dir.mkdir 'build'
    Dir.chdir 'build' do
      system "cmake .. -DCMAKE_INSTALL_PREFIX=#{CREW_PREFIX} -DLIB_DESTINATION=#{ARCH_LIB} -DCMAKE_BUILD_TYPE=Release"
      system 'make'
    end
  end

  def self.install
    Dir.chdir 'build' do
      system "DESTDIR=#{CREW_DEST_DIR} make install"
    end
  end
end
