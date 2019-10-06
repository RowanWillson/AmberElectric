# AmberElectric
Unofficial Amber Electric iOS / WatchOS client

This is a developer/hobbyist implementation of a native iOS app to display live Amber Electric retail electricity prices. To create an account with Amber Electric firstly visit the [Amber Electric Website](https://www.amberelectric.com.au).

**LICENSE**
MIT

**Platform support**:

- [x] iPhone (iOS 12.4+)
- [x] iPhone Today Extension (home screen widget)
- [x] Apple Watch Extension (including complications)
- [ ] iPad
- [ ] MacOS

![iOS App](https://image-asset.sfo2.cdn.digitaloceanspaces.com/AmberElectric/Amber-iOS.jpg)
![iOS Today Extension](https://image-asset.sfo2.cdn.digitaloceanspaces.com/AmberElectric/Amber-TodayExtension.jpg)
![WatchOS Complication](https://image-asset.sfo2.cdn.digitaloceanspaces.com/AmberElectric/Amber-WatchComplication.png)


**iOS Features**
- [x] Live price
- [x] Predicted Prices (30min increments)
- [x] Background fetch
- [x] Local Notification when prices below $0.00
- [ ] Historical prices
- [ ] Historical account usage
- [ ] Localization

**WatchOS Features & Complications**
- [ ] Native login on WatchApp (currently uses WCSession to use iPhone login credentials)
- [ ] Standalone WatchApp support
- [x] Watch app (limited functionality - can be better)
- [x] Background fetch
- [x] circularSmall complication
- [x] modularSmall complication
- [ ] modularLarge complication
- [ ] utilitarianSmall complication
- [x] utilitarianSmallFlat complication
- [ ] utilitarianLarge complication
- [x] extraLarge complication
- [ ] graphicCorner complication
- [ ] graphicBezel complication
- [x] graphicCircular complication
- [ ] graphicRectangular complication

## Developers

This is not something I'll be maintaining full time, but I will regularly release updates to the App Store as patches come in.

Please try to minimise external depedencies. I will consider adding Podfile if there's a really good reason, but ideally it stays as lightweight as possible and uses vanilla Apple SDK's where possible. This is to maximise long term support and for ease of development and the ability for others to make modifications like adding or tweaking WatchOS complications.

