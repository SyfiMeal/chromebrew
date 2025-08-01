require 'package'

class Llvm20_build < Package
  @llvm_projects_to_build = ARCH == 'x86_64' ? 'bolt;clang;clang-tools-extra;compiler-rt;lld;lldb;polly;pstl' : 'clang;clang-tools-extra;compiler-rt;lld;lldb;polly;pstl'
  description "The LLVM Project is a collection of modular and reusable compiler and toolchain technologies. The packages included are: #{@llvm_projects_to_build.gsub(';', ' ')}"
  homepage 'https://llvm.org/'
  version '20.1.8'
  # When upgrading llvm*_build, be sure to upgrade llvm_lib*, llvm_dev*, libclc, and openmp in tandem.
  license 'Apache-2.0-with-LLVM-exceptions, UoI-NCSA, BSD, public-domain, rc, Apache-2.0 and MIT'
  compatibility 'all'
  source_url 'https://github.com/llvm/llvm-project.git'
  git_hashtag "llvmorg-#{version}"
  binary_compression 'tar.zst'

  binary_sha256({
    aarch64: '1adf11e5d9aa8e1c0402fe6b1bbd53404545a7483bc2a7467f2561b093449afc',
     armv7l: '1adf11e5d9aa8e1c0402fe6b1bbd53404545a7483bc2a7467f2561b093449afc',
       i686: 'a3260144000633c3310daa3cac2fbb1d93e3fb21cf2a7ec83c633fe7c59ccca7',
     x86_64: 'a2e2242dfb20142761f264e14759742b677e03bd14a32f745a65b2b2946837fd'
  })

  depends_on 'gcc_lib' # R
  depends_on 'glibc' # R
  depends_on 'libedit' # R
  depends_on 'libffi' # R
  depends_on 'libxml2' # R
  depends_on 'llvm20_dev' => :build
  depends_on 'ocaml' => :build
  depends_on 'py3_pygments' => :build
  depends_on 'py3_pyyaml' => :build
  depends_on 'xzutils' # R
  depends_on 'zlib' # R
  depends_on 'zstd' # R

  conflicts_ok
  no_env_options

  case ARCH
  when 'aarch64', 'armv7l'
    # LLVM_TARGETS_TO_BUILD = 'ARM;AArch64;AMDGPU'
    # LLVM_TARGETS_TO_BUILD = 'all'.freeze
    @ARCH_C_FLAGS = "-mfloat-abi=hard -mthumb -mfpu=vfpv3-d16 -march=armv7-a+fp -ccc-gcc-name #{CREW_TARGET}"
    @ARCH_CXX_FLAGS = "-mfloat-abi=hard -mthumb -mfpu=vfpv3-d16 -march=armv7-a+fp -ccc-gcc-name #{CREW_TARGET}"
    @ARCH_LDFLAGS = ''
  when 'i686'
    # LLVM_TARGETS_TO_BUILD = 'X86'.freeze
    # Because ld.lld: error: undefinler-rt;libc;libcxx;libcxxabi;libunwind;openmped symbol: __atomic_store
    # Polly demands fPIC
    @ARCH_C_FLAGS = '-latomic'
    @ARCH_CXX_FLAGS = '-latomic'
    # Because getting this error:
    # ld.lld: error: relocation R_386_PC32 cannot be used against symbol isl_map_fix_si; recompile with -fPIC
    # So as per https://github.com/openssl/openssl/issues/11305#issuecomment-602003528
    @ARCH_LDFLAGS = '-Wl,-znotext'
    # lldb fails on i686 due to requirement for a kernel > 4.1.
    # See https://github.com/llvm/llvm-project/issues/57594
  when 'x86_64'
    # LLVM_TARGETS_TO_BUILD = 'X86;AMDGPU'
    # LLVM_TARGETS_TO_BUILD = 'all'.freeze
    @ARCH_C_FLAGS = ''
    @ARCH_CXX_FLAGS = ''
    @ARCH_LDFLAGS = ''
  end
  @ARCH_C_LTO_FLAGS = "#{@ARCH_C_FLAGS} -fPIC -flto=thin #{CREW_LINKER_FLAGS}"
  @ARCH_CXX_LTO_FLAGS = "#{@ARCH_CXX_FLAGS} -fPIC -flto=thin #{CREW_LINKER_FLAGS}"
  @ARCH_LTO_LDFLAGS = "#{@ARCH_LDFLAGS} -flto=thin #{CREW_LINKER_FLAGS}"
  # flang isn't supported on 32-bit architectures.
  # openmp is its own package.

  # Using Targets 'all' for non-i686 because otherwise mesa complains.
  # This may be patched upstream as per
  # https://reviews.llvm.org/rG1de56d6d13c083c996dfd44a32041dacae037d66
  LLVM_TARGETS_TO_BUILD = 'all'.freeze

  def self.patch
    # Remove rc suffix on final release.
    system "sed -i 's,set(LLVM_VERSION_SUFFIX rc),,' llvm/CMakeLists.txt"

    # Patch for LLVM 15+ because of https://github.com/llvm/llvm-project/issues/58851
    File.write 'llvm_crew_lib_prefix.patch', <<~LLVM_PATCH_EOF
      --- a/clang/lib/Driver/ToolChains/Linux.cpp	2022-11-30 15:50:36.777754608 -0500
      +++ b/clang/lib/Driver/ToolChains/Linux.cpp	2022-11-30 15:51:57.004417484 -0500
      @@ -314,6 +314,7 @@ Linux::Linux(const Driver &D, const llvm
             D.getVFS().exists(D.Dir + "/../lib/libc++.so"))
           addPathIfExists(D, D.Dir + "/../lib", Paths);

      +  addPathIfExists(D, concat(SysRoot, "#{CREW_LIB_PREFIX}"), Paths);
         addPathIfExists(D, concat(SysRoot, "/lib"), Paths);
         addPathIfExists(D, concat(SysRoot, "/usr/lib"), Paths);
       }
    LLVM_PATCH_EOF
    system 'patch -Np1 -i llvm_crew_lib_prefix.patch'
  end

  def self.build
    ############################################################
    puts "Building LLVM Targets: #{LLVM_TARGETS_TO_BUILD}".lightgreen
    puts "Building LLVM Projects: #{@llvm_projects_to_build}".lightgreen
    ############################################################

    unless Dir.exist?('builddir')
      FileUtils.mkdir_p 'builddir'
      File.write 'builddir/clc', <<~CLC_EOF
        #!/bin/bash
        machine=$(gcc -dumpmachine)
        version=$(gcc -dumpversion)
        gnuc_lib=#{CREW_LIB_PREFIX}/gcc/${machine}/${version}
        clang -B ${gnuc_lib} -L ${gnuc_lib} "$@"
      CLC_EOF
      File.write 'builddir/clc++', <<~CLCPLUSPLUS_EOF
        #!/bin/bash
        machine=$(gcc -dumpmachine)
        version=$(gcc -dumpversion)
        cxx_sys=#{CREW_PREFIX}/include/c++/${version}
        cxx_inc=#{CREW_PREFIX}/include/c++/${version}/${machine}
        gnuc_lib=#{CREW_LIB_PREFIX}/gcc/${machine}/${version}
        clang++ -fPIC -rtlib=compiler-rt -stdlib=libc++ -cxx-isystem ${cxx_sys} -I ${cxx_inc} -B ${gnuc_lib} -L ${gnuc_lib} "$@"
      CLCPLUSPLUS_EOF
      system "cmake -B builddir -G Ninja llvm \
            -DCLANG_DEFAULT_LINKER=mold \
            -DCMAKE_ASM_COMPILER_TARGET=#{CREW_TARGET} \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_C_COMPILER=$(which clang) \
            -DCMAKE_C_COMPILER_TARGET=#{CREW_TARGET} \
            -DCMAKE_C_FLAGS='#{@ARCH_C_LTO_FLAGS}' \
            -DCMAKE_CXX_COMPILER=$(which clang++) \
            -DCMAKE_CXX_FLAGS='#{@ARCH_CXX_LTO_FLAGS}' \
            -DCMAKE_EXE_LINKER_FLAGS='#{@ARCH_LTO_LDFLAGS}' \
            -DCMAKE_INSTALL_LIBDIR=#{ARCH_LIB} \
            -DCMAKE_INSTALL_PREFIX=#{CREW_PREFIX} \
            -DCMAKE_LIBRARY_PATH='#{CREW_GLIBC_INTERPRETER.nil? ? CREW_LIB_PREFIX : "#{CREW_GLIBC_PREFIX};#{CREW_LIB_PREFIX}"}' \
            -D_CMAKE_TOOLCHAIN_PREFIX=llvm- \
            -DCOMPILER_RT_BUILD_BUILTINS=ON \
            -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
            -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
            -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
            -DLLDB_INCLUDE_TESTS=OFF \
            -DLLVM_BINUTILS_INCDIR='#{CREW_PREFIX}/include' \
            -DLLVM_BUILD_LLVM_DYLIB=ON \
            -DLLVM_DEFAULT_TARGET_TRIPLE=#{CREW_TARGET} \
            -DLLVM_ENABLE_FFI=ON \
            -DLLVM_ENABLE_LTO=Thin \
            -DLLVM_ENABLE_PIC=ON \
            -DLLVM_ENABLE_PROJECTS='#{@llvm_projects_to_build}' \
            -DLLVM_ENABLE_RTTI=ON \
            -DLLVM_INCLUDE_BENCHMARKS=OFF \
            -DLLVM_INSTALL_UTILS=ON \
            -DLLVM_LIBDIR_SUFFIX='#{CREW_LIB_SUFFIX}' \
            -DLLVM_LINK_LLVM_DYLIB=ON \
            -DLLVM_OPTIMIZED_TABLEGEN=ON \
            -DLLVM_TARGETS_TO_BUILD='#{LLVM_TARGETS_TO_BUILD}' \
            -Wno-dev"
    end
    system "#{CREW_NINJA} -C builddir -j #{CREW_NPROC}"
  end

  def self.install
    system "DESTDIR=#{CREW_DEST_DIR} #{CREW_NINJA} -C builddir install"
    Dir.chdir('builddir') do
      FileUtils.install 'clc', "#{CREW_DEST_PREFIX}/bin/clc", mode: 0o755
      FileUtils.install 'clc++', "#{CREW_DEST_PREFIX}/bin/clc++", mode: 0o755
      FileUtils.mkdir_p "#{CREW_DEST_LIB_PREFIX}/bfd-plugins"
      Dir.chdir("#{CREW_DEST_LIB_PREFIX}/bfd-plugins") do
        FileUtils.ln_s "../../lib#{CREW_LIB_SUFFIX}/LLVMgold.so", 'LLVMgold.so'
      end
      # libunwind.* conflicts with libunwind package
      FileUtils.rm Dir.glob("#{CREW_DEST_LIB_PREFIX}/libunwind.*")
    end
  end

  # preserve for check, skip check for current version
  # def self.check
  #   Dir.chdir('builddir') do
  #     system 'ninja check-llvm || true'
  #     system 'ninja check-clang || true'
  #     system 'ninja check-lld || true'
  #   end
  # end

  def self.postinstall
    puts
    puts "To compile programs, use 'clang' or 'clang++'.".lightblue
    puts
    puts 'To avoid the repeated use of switch options,'.lightblue
    puts "try the wrapper scripts 'clc' or 'clc++'.".lightblue
    puts
    puts 'For more information, see https://llvm.org/pubs/2008-10-04-ACAT-LLVM-Intro.pdf'.lightblue
    puts
  end
end
