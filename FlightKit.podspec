#
# Be sure to run `pod lib lint FlightKit.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "FlightKit"
  s.version          = "0.1.0"
  s.summary          = "A short description of FlightKit."
  s.description      = <<-DESC
                       An optional longer description of FlightKit

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/<GITHUB_USERNAME>/FlightKit"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Nikolay Derkach" => "nderk@me.com" }
  s.source           = { :git => "https://github.com/<GITHUB_USERNAME>/FlightKit.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  s.resource_bundles = {
    'FlightKit' => ['Pod/Assets/*']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'KeychainAccess'
  s.dependency 'Alamofire'
  s.dependency 'SwiftyJSON'
  s.dependency 'SCLAlertView'
end
