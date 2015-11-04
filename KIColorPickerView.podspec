Pod::Spec.new do |s|
  s.name         = "KIColorPickerView"
  s.version      = "0.0.1"
  s.summary      = "KIColorPickerView"
  s.description  = <<-DESC
  				   KIColorPickerView.
                   DESC

  s.homepage     = "https://github.com/smartwalle/KIColorPickerView"
  s.license      = "MIT"
  s.author             = { "SmartWalle" => "smartwalle@gmail.com" }
  s.platform     = :ios, "6.0"
  s.source       = { :git => "https://github.com/smartwalle/KIColorPickerView.git", :branch => "master" }

  s.source_files  = "KIColorPickerView/KIColorPickerView/*.{h,m}"
  s.requires_arc = true
end
