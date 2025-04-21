# Captive

A captive portal for [OpenWrt](https://openwrt.org/).

## Installation

### Dependencies

OpenWrt with uhttpd and uhttpd-mod-lua. Depending on the chosen mode, lunatik or nft.

### Installation

Replace `OpenWrt` by the ip / name of your router:

`./make.moon root@OpenWrt`

If using luci for configuration:

`./make.moon install_luci root@OpenWrt`

### Usage

`ssh root@OpenWrt lunatik spawn captive/main`