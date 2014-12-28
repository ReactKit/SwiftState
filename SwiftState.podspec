Pod::Spec.new do |s|
  s.name     = 'SwiftState'
  s.version  = '1.1.1'
  s.license  = { :type => 'MIT' }
  s.homepage = 'https://github.com/ReactKit/SwiftState'
  s.authors  = { 'Yasuhiro Inami' => 'inamiy@gmail.com' }
  s.summary  = 'Elegant state machine for Swift.'
  s.source   = { :git => 'https://github.com/inamiy/SwiftState.git', :tag => "#{s.version}" }
  s.source_files = 'SwiftState/**/*.{h,swift}'
  s.requires_arc = true
end