Pod::Spec.new do |s|
  s.name     = 'SwiftState'
  s.version  = '3.0.0'
  s.license  = { :type => 'MIT' }
  s.homepage = 'https://github.com/ReactKit/SwiftState'
  s.authors  = { 'Yasuhiro Inami' => 'inamiy@gmail.com' }
  s.summary  = 'Elegant state machine for Swift.'
  s.source   = { :git => 'https://github.com/ReactKit/SwiftState.git', :tag => "#{s.version}" }
  s.source_files = 'SwiftState/**/*.{h,swift}'
  s.requires_arc = true

  s.osx.deployment_target = '10.9'
  s.ios.deployment_target = '8.0'
end