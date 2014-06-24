Gem::Specification.new do |s|
  s.name = 'salsa20'
  s.version = '0.1.0'

  s.summary = "Salsa20 stream cipher algorithm."
  s.description = <<-EOF
    Salsa20 is a stream cipher algorithm designed by Daniel Bernstein. salsa20-ruby provides
    a simple Ruby wrapper.
  EOF

  s.files = `git ls-files`.split("\n")
  s.require_path = 'lib'

  s.test_files = `git ls-files test`.split("\n")

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rake-compiler'
  s.add_development_dependency 'rdoc'

  s.has_rdoc = true
  s.rdoc_options += ['--title', 'salsa20', '--main', 'README.rdoc']
  s.extra_rdoc_files += ['README.rdoc', 'LICENSE', 'CHANGELOG', 'lib/salsa20.rb']

  s.extensions = 'ext/salsa20_ext/extconf.rb'

  s.authors = ["Dov Murik"]
  s.email = "dov.murik@gmail.com"
  s.homepage = "https://github.com/dubek/salsa20-ruby"
end
