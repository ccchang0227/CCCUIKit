# Change Log
All notable changes to CCCCamera will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) <br>
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]
### Changed
- `CCCCameraSessionDelegate`新增方法:`-cccCameraSession:didReceiveSampleBuffer:fromConnection:`

## [1.1.1] - 2017-05-25
### Fixed
- 修正delegate在只偵測到人臉時還是會呼叫`-cccCameraView:didScanBarcodeWithArray:`方法的bug
- 修正相機閃光燈設定

### Added
- 滑動畫面調整曝光功能(類似內建相機，曝光補償限制-3~3)
- 畫面側邊`UISlider`滑動調整曝光補償，調整後鎖定補償值
- 自製調整曝光補償功能

### Changed
- 調整`CCCCameraView`顯示

## [1.0.1] - 2017-02-20
### Added
- CHANGLOG.md file.

## [1.0.0] - 2017-02-16
- First release
