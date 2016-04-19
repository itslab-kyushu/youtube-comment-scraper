Youtube comment scraper
==========================
[![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE)
[![npm version](https://badge.fury.io/js/youtube-comment-scraper.svg)](https://badge.fury.io/js/youtube-comment-scraper)
[![Code Climate](https://codeclimate.com/github/itslab-kyushu/youtube-comment-scraper/badges/gpa.svg)](https://codeclimate.com/github/itslab-kyushu/youtube-comment-scraper)

Scraping comments from Youtube.

Install
----------
```sh
$ npm install -g youtube-comment-scraper
```

Usage
-------

```
Usage: scraper url [options]

        url
                URL for a Youtube video page or video ID.

        --help, -h
                Displays help information about this script

        --version
                Displays version info
```

Output is a JSON file and its schema is

```json
{
  "url": "the given url",
  "comments": [
    {
      "root": "root comment",
      "author": "author of the root comment",
      "like": "like score (summation of +1 for like and -1 for dislike)",
      "children": [
        {
          "comment": "reply comment",
          "author": "author of the reply comment.",
          "like": "like score",
          "receiver": "receiver name if the comment is a reply for a specific user."
        },
        ...
      ]
    },
    ...
  ]
}
```


Method
---------
```js
var scraper = require("youtube-comment-scraper");
```

### `scraper(url)`
Scraping a given Youtube page and return a set of comments.

- Args:
  - url: URL of the target page or video ID.
- Returns:
 Promise object. Use "then" to recieve results.

### example
```js
scraper(some_url).then(function(res) {
  return console.log(JSON.stringify({
    url: some_url,
    comments: res
  }));
});
```

For developers
-----------------

### Build
Run the following two command.

```sh
$ npm install
$ npm run build
```

### Run

```sh
$ ./bin/cli.js <url>
```

`<url>` is a Youtube url.

License
--------
This software is released under the MIT License, see [LICENSE](LICENSE).
