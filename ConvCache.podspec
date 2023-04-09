#
# Be sure to run `pod lib lint ConvCache.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'ConvCache'
  s.version          = '0.1.0'
  s.summary          = 'A simple cache library that supports memory, disk, and modernization.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
    "ConvCache leverages Etag to modernize caches and supports memory and disk caches."
    "ConvCache was created using only the Apple frameworks."
    "Please enable Etag when you use it."
                       DESC
  s.swift_version = '4.0'
  s.homepage         = 'https://github.com/oguuk/ConvCache'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'oguuk' => 'ogw135@gmail.com' }
  s.source           = { :git => 'https://github.com/oguuk/ConvCache.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '13.0'

  s.source_files = 'ConvCache/Classes/**/*'
  
  # s.resource_bundles = {
  #   'ConvCache' => ['ConvCache/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
