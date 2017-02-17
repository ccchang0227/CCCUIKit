Pod::Spec.new do |s|
  s.name             = 'CCCUIKit'
  s.version          = '1.0.1'
  s.summary          = "C.C.Chang's custom UIKit."

  s.homepage         = 'https://github.com/ccchang0227/CCCUIKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.authors          = { 'Chih-chieh Chang' => 'ccch.realtouch@gmail.com' }
  s.source           = { :git => 'https://github.com/ccchang0227/CCCUIKit.git', :tag => s.version.to_s }

  s.ios.deployment_target = '6.0'
  s.source_files = 'Classes/CCCUIKit.h'

  s.frameworks = 'UIKit'

  s.subspec 'UIKit+CCCAdditions' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.ios.deployment_target = '6.0'
    ss.tvos.deployment_target = '9.0'
    ss.source_files = 'Classes/UIKit+CCCAdditions/**/*.{h,m}'
  end

  s.subspec 'CCCAssetsViewController' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCAssetsViewController/*.{h,m}'
    ss.resources = 'Classes/CCCAssetsViewController/*.xib', 'Assets/*.png'
    ss.frameworks = 'AssetsLibrary', 'MediaPlayer'
    ss.weak_frameworks = 'Photos'

    ss.subspec 'CCCAssetsModel' do |sss|
      sss.source_files = 'Classes/CCCAssetsViewController/CCCAssetsModel/*.{h,m}'
    end

    ss.subspec 'ChildrenViewControllers' do |sss|
      sss.source_files = 'Classes/CCCAssetsViewController/ChildrenViewControllers/*.{h,m}'
      sss.resources = 'Classes/CCCAssetsViewController/ChildrenViewControllers/*.xib'
      sss.dependency 'CCCUIKit/CCCAssetsViewController/CCCAssetsModel'
    end
  end

  s.subspec 'CCCCamera' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCCamera/**/*.{h,m}'
    ss.frameworks = 'AVFoundation', 'ImageIO', 'MobileCoreServices', 'CoreMotion'
  end

  s.subspec 'CCCCanvas' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCCanvas/**/*.{h,m}'
    ss.frameworks = 'AVFoundation'
    ss.dependency 'CCCUIKit/CCCSlider'
  end

  s.subspec 'CCCCycleView' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCCycleView/*.{h,m}'
    ss.frameworks = 'GLKit', 'CoreGraphics', 'QuartzCore'

    ss.subspec 'XYPieChart' do |sss|
      sss.requires_arc = true
      sss.source_files = 'Classes/CCCCycleView/XYPieChart/*.{h,m}'
    end
  end

  s.subspec 'CCCDevice' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.ios.deployment_target = '6.0'
    ss.tvos.deployment_target = '9.0'
    ss.source_files = 'Classes/CCCDevice/**/*.{h,m}'
  end

  s.subspec 'CCCMaskedLabel' do |ss|
    # current version: 0.0.5
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCMaskedLabel/**/*.{h,m}'
  end

  s.subspec 'CCCPageControl' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCPageControl/**/*.{h,m}'
  end

  s.subspec 'CCCRatingControl' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCRatingControl/**/*.{h,m}'
  end

  s.subspec 'CCCRecycleScrollView' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCRecycleScrollView/**/*.{h,m}'
  end

  s.subspec 'CCCSlider' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCSlider/**/*.{h,m}'
  end

  s.subspec 'CCCSlidingViewController' do |ss|
    # current version: 1.0.0
    ss.requires_arc = false
    ss.source_files = 'Classes/CCCSlidingViewController/**/*.{h,m}'
  end

  s.subspec 'CCCSwitch' do |ss|
    # current version: 0.0.5
    ss.requires_arc = false
    ss.ios.deployment_target = '6.0'
    ss.tvos.deployment_target = '9.0'
    ss.source_files = 'Classes/CCCSwitch/**/*.{h,m}'
  end

end
