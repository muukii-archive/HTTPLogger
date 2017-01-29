#
# Be sure to run `pod lib lint BrickRequest.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = "HTTPLogger"
    s.version          = "0.2.0"
    s.summary          = "Logging HTTP Request with NSURLProtocol"
    
    s.description      = <<-DESC
    Pretty print HTTP Request with NSURLProtocol
    DESC

    s.homepage         = "https://github.com/muukii/HTTPLogger"
    s.license          = 'MIT'
    s.author           = { "muukii" => "m@muukii.me" }
    s.source           = { :git => "https://github.com/muukii/HTTPLogger.git", :tag => s.version.to_s }

    s.ios.deployment_target = '8.0'
    s.tvos.deployment_target = '9.0'
    s.watchos.deployment_target = '2.0'

    s.requires_arc = true

    s.source_files = 'HTTPLogger/*.swift'
end
