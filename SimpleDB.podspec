Pod::Spec.new do |s|
  s.name               = "SimpleDB"
  s.version            = "1.1.0"
  s.summary            = "SimpleDB is a key-value persistent database that makes it very easy to store and retrieve data or object state for your application."
  s.license            = { :type => 'MIT', :file => 'LICENSE' }
  s.author             = { "Aaron L. Bratcher" => "aaronbratcher1@gmail.com" }
  s.social_media_url   = "http://twitter.com/AaronLBratcher"
  s.source             = { :git => "https://github.com/AaronBratcher/SimpleDB", :tag => s.version.to_s }
  s.requires_arc = true
  s.source_files = 'SimpleDB_Classes'
  s.dependency 'ABSQLite', '~> 1.1'
  
end
