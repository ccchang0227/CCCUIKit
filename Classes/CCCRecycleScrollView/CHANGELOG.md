# Change Log
All notable changes to CCCRecycleScrollView will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) <br>
and this project adheres to [Semantic Versioning](http://semver.org/).

## Unreleased

## [1.2.0] - 2018-06-27
### 修正
- `-scrollToIndex:direction:animated:`在animated是NO時，log出現NSLock的warning訊息

### 新增
- `-reloadDataWithCenterIndex:`方法，指定重載畫面時中間的index

## [1.1.0] - 2017-09-18
### 修正
- 滑動時subview錯位的問題
    - layoutSubviews的呼叫時機導致

### 修改
- NSTimer改成dispatch_source_t，原本在另一個執行緒做的動作拉回到主執行緒做

### 新增
- 方法 -decelerateToIndex 和 -stopScrollAtIndex 用於停止/減速至特定index

## [1.0.1] - 2017-02-20
### Added
- CHANGLOG.md file.

## [1.0.0] - 2017-02-17
- First release
