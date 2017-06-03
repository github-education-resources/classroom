# -*- encoding: utf-8 -*-

require File.expand_path('../lib/jquery-turbolinks/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name              = 'jquery-turbolinks'
  gem.rubyforge_project = 'jquery-turbolinks'
  gem.version           = JqueryTurbolinks::VERSION

  gem.authors           = ['Sasha Koss']
  gem.email             = 'koss@nocorp.me'

  gem.description       = 'jQuery plugin for drop-in fix binded events problem caused by Turbolinks'
  gem.summary           = 'jQuery plugin for drop-in fix binded events problem caused by Turbolinks'
  gem.homepage          = 'https://github.com/kossnocorp/jquery.turbolinks'

  gem.executables       = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files             = `git ls-files`.split("\n")
  gem.test_files        = `git ls-files -- {test,spec,features}/*`.split("\n")

  gem.licenses          = ['MIT']

  gem.require_paths     = ['lib']

  gem.rubygems_version  = '1.8.15'

  gem.add_dependency 'railties', '>= 3.1.0'
  gem.add_dependency 'turbolinks'
end
