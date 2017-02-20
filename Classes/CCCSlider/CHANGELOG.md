# Change Log
All notable changes to CCCSlider will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) <br>
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.1.0] - 2017-02-20
### Added
- CHANGLOG.md file.
- Add method: <br>
<code> - (CGRect)thumbRectForBounds:(CGRect)bounds trackRect:(CGRect)rect value:(float)value; </code>

### Changed
- Change method: <br>
<code> - (void)setThumbHidden:(BOOL)hidden</code><br>
To property: <br>
<code> @property (nonatomic, getter=isThumbHidden) BOOL thumbHidden; </code>
- Change implementation of methods: <br>
<code> - (CGRect)minimumValueImageRectForBounds:(CGRect)bounds; </code>
<code> - (CGRect)maximumValueImageRectForBounds:(CGRect)bounds; </code>
<code> - (CGRect)trackRectForBounds:(CGRect)bounds; </code>
<code> - (CGRect)thumbRectForBounds:(CGRect)bounds; </code><br>
- Change calculations of sublayers' size and position.
- Edit implementation of retain-properties' setter method.

## [1.0.0] - 2017-02-16
- First release