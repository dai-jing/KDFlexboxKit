#
# Be sure to run `pod lib lint KDFlexboxKit.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'KDFlexboxKit'
  s.version          = '0.1.0'
  s.summary          = 'FlexboxKit is a Swift declarative UI framework supported by CSS flexbox.'
  s.description      = "FlexboxKit is a Swift declarative UI framework supported by CSS flexbox. It makes the UI codes easier to write and maintain"

  s.homepage         = 'https://github.com/dai-jing/KDFlexboxKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'dai-jing' => 'kobedai24@gmail.com' }
  s.source           = { :git => 'https://github.com/dai-jing/KDFlexboxKit.git', :tag => "#{s.version}" }

  s.platform     = :ios, "10.0"
  
  s.swift_version = "5.0"
  s.swift_versions = ['4.0', '4.2', '5.0']

  s.libraries    = 'c++'
  
  s.source_files = 'KDFlexboxKit/Classes/**/*'

  s.requires_arc = true

  s.dependency 'Yoga', '1.14.0'
  s.dependency 'Kingfisher'
end

