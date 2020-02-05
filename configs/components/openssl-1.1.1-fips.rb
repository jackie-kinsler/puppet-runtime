component 'openssl-1.1.1-fips' do |pkg, settings, _platform|
  pkg.version '1.1.1-8'
  pkg.md5sum 'da54e0d141def857fc895daf87d17b55'
  pkg.url "http://vault.centos.org/8.0.1905/BaseOS/Source/SPackages/openssl-#{pkg.get_version}.el8.src.rpm"
  pkg.mirror "#{settings[:buildsources_url]}/openssl-#{pkg.get_version}.el8.src.rpm"

  pkg.build_requires 'rpm-build'
  pkg.build_requires 'krb5-devel'
  pkg.build_requires 'zlib-devel'
  pkg.build_requires 'lksctp-tools-devel'
  pkg.build_requires 'perl-Test-Harness'
  pkg.build_requires 'perl-Module-Load-Conditional'

  # FIXME: pkg.apply_patch is not usefull here as vanagon component does
  # not know how to extract rpm and patch happend before configure step
  # proper fix would be extension in vanagon for source rpm handling
  pkg.add_source 'file://resources/patches/openssl/openssl-1.1.1-fips-force-fips-mode.patch'
  pkg.add_source 'file://resources/patches/openssl/openssl-1.1.1-fips-post-rand.patch'
  pkg.add_source 'file://resources/patches/openssl/openssl-1.1.1-fips-spec-file.patch'

  topdir = "--define \"_topdir `pwd`/openssl-#{pkg.get_version}\""
  libdir = "--define '%_libdir %{_prefix}/lib'"
  prefix = "--define '%_prefix #{settings[:prefix]}'"

  pkg.configure do
    [
      "rpm -i #{topdir} openssl-#{pkg.get_version}.el8.src.rpm",
      "cd openssl-#{pkg.get_version} && /usr/bin/patch --strip=1 --fuzz=0 --ignore-whitespace --no-backup-if-mismatch < ../openssl-1.1.1-fips-force-fips-mode.patch; cd -",
      "cd openssl-#{pkg.get_version} && /usr/bin/patch --strip=1 --fuzz=0 --ignore-whitespace --no-backup-if-mismatch < ../openssl-1.1.1-fips-post-rand.patch; cd -",
      "cd openssl-#{pkg.get_version} && /usr/bin/patch --strip=1 --fuzz=0 --ignore-whitespace --no-backup-if-mismatch < ../openssl-1.1.1-fips-spec-file.patch; cd -"
    ]
  end

  pkg.build do
    [
      'if [ -f /etc/system-fips ]; then mv /etc/system-fips /etc/system-fips.off; fi',
      "rpmbuild -bc --nocheck #{libdir} #{prefix} #{topdir} openssl-#{pkg.get_version}/SPECS/openssl.spec",
      'if [ -f /etc/system-fips.off ]; then mv /etc/system-fips.off /etc/system-fips; fi'
    ]
  end

  pkg.install do
    [
      "cd openssl-#{pkg.get_version}/BUILD/openssl-1.1.1 && make install",
      'if [ -f /etc/system-fips ]; then mv /etc/system-fips /etc/system-fips.off; fi',
      "/usr/bin/strip #{settings[:prefix]}/lib/libcrypto.so.1.1 && LD_LIBRARY_PATH=. crypto/fips/fips_standalone_hmac #{settings[:prefix]}/lib/libcrypto.so.1.1 > #{settings[:prefix]}/lib/.libcrypto.so.1.1.hmac",
      "/usr/bin/strip #{settings[:prefix]}/lib/libssl.so.1.1    && LD_LIBRARY_PATH=. crypto/fips/fips_standalone_hmac #{settings[:prefix]}/lib/libssl.so.1.1    > #{settings[:prefix]}/lib/.libssl.so.1.1.hmac",
      'if [ -f /etc/system-fips.off ]; then mv /etc/system-fips.off /etc/system-fips; fi'
    ]
  end
end