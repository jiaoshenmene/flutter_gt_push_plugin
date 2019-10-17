#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_gt_push_plugin'
  s.version          = '0.0.2'
  s.summary          = 'A new Flutter plugin with push'
  s.description      = <<-DESC
A new Flutter plugin with push
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => '815319775@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'GTSDK'
  s.static_framework = true
  s.ios.deployment_target = '10.0'
  s.frameworks = 'PushKit' , 'UserNotifications', 'CallKit'
end

