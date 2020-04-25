# Apple Developer Discover RSS Feed

The new Apple Developer app has some neat content that isn't (yet?) available with an RSS feed. This generates that RSS feed.

A small Swift program is run daily and on pushes to generate the feed and publish it to GitHub Pages here: [https://interstateone.github.io/AppleDeveloperDiscover/feed.xml](https://interstateone.github.io/AppleDeveloperDiscover/feed.xml)

<a href="https://validator.w3.org/feed/check.cgi?url=https%3A//interstateone.github.io/AppleDeveloperDiscover/feed.xml"><img src="valid-rss-rogers.png" alt="[Valid RSS]" title="Validate my RSS feed" /></a>

## Disclaimers

- I don't want this project to be necessary. Someone at Apple should make an RSS feed for this content. 😄
- This is a little hobby project, not a polished codebase. I got nerd sniped by [iOS Dev Weekly](https://iosdevweekly.com/issues/453#news) and made this one evening. If something isn't working in a reasonable way then it might get fixed, but you should probably open a PR to fix it yourself.
- The Apple URL that this hits was found with [Charles for iOS](https://www.charlesproxy.com/documentation/ios/) and, based on some digging with [Hopper](https://www.hopperapp.com), seems like it's not user-specific and won't change without a change to the app itself. No guarantees though.
