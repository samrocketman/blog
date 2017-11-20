# My blog - [![Build Status][stat]][ci]

This is a blogging website where I post technical information for myself, Sam
Gleske.  If others find it useful then more power to 'em.  If you'd like to
learn more about me then check out my [first post][post].

# Features of my blog

- Minimal as possible while still remaining useful.
- Slightly [reddish/pink tint which is good for readers' eyes][flux].
- Tags and categories.
- Some social media buttons and Disqus comments for posts.
- Integrated with GitHub (via the `_config.yml` file).
  - `make history` generates `_data/updated.yml` based in the git history of
    when a post was last updated.
  - Displays when a post was last updated and links to the history in GitHub
    which serves as a changelog for tracking changes to individual posts.
- Three modes:
  1. development - social media buttons and comments removed.  All URLs point to
     localhost.
  2. simulated production - Just like production but all URLs point to
    localhost.  Good to check out just before publishing.
  3. production - The live site.
- Post authoriship is integrated with GPG validation.  This way posts by the
  author can be cryptographically verified.

# Getting started with development

#### Prerequisites

- OS: Ubuntu GNU/Linux
- Ruby 2.4

If you're using a Mac, then building the blog won't work.  It's due to
differences in the BSD toolset vs the GNU toolset.

The blog requires Ruby 2.2 to be installed.  It's best to use [rvm][rvm] for
Ruby.

Set up with `rvm`.

    rvm install 2.4
    #optionally install within a "blog" gemset
    rvm use 2.4@blog --create

If you encounter an error about not being in a login shell then use `bash -l` to
create one.  Now when you open a new terminal be sure to execute the following
commands before modifying the blog.

    rvm use 2.4@blog --create

#### Install dependencies

I have provided a handy `Makefile` to aid with development.  Here's a summary of
a few `make` commands I've provided for myself.

- `make deps` - will bundle install dependencies.  I assume you're working in a
  managed ruby environment such as [rvm][rvm].  This should be the first command
  you run before any other.
- `make` - will start the Jekyll server environment and website in "development
  mode."  This does three things:
  1. Removes distracting comments and social media buttons.
  2. Displays posts from the `_drafts/` folder.
  3. Displays unpublished posts.
- `make prod` - will start the Jekyll server environment and website in a
  simulated "production mode."  This starts the website with all of the
  addresses pointing at a local `site.url`.  It basically brings back the social
  media buttons and comments but allows you to browse the site locally.

I also have the [Greasemonkey Firefox Add-on][ff-gm] installed and use the
following script.

```javascript
window.onload = function() {
  window.scrollTo(0,document.body.scrollHeight);
}
setTimeout(function() {location.reload();}, 5000);
```

This will reload the page every 5 seconds and scroll to the bottom of the page.
This is useful to see live page updates as I'm writing blog posts in
"development mode."  It works best with dual monitors having the code on one
screen and the webpage on the other.

# Tips for myself

Sign any changed blog posts:

    make sign

Sign a commit:

    git commit -S

# Summary of Licenses

All source code is MIT Licensed by [LICENSE.txt](LICENSE.txt) with exception
for:

- All content under `_posts/` and `images/` is licensed under [Creative Commons
  Attribution-NonCommercial-ShareAlike 4.0 International][cc] and is governed by
  the contents of [LICENSE.txt](LICENSE.txt).
- Any content governed by 3rd parties which is covered by copyrights, licenses,
  and notices outlined in the [`3rd_party/`](3rd_party) folder.

[cc]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[ci]: https://travis-ci.org/samrocketman/blog
[ff-gm]: https://addons.mozilla.org/en-us/firefox/addon/greasemonkey/
[flux]: https://justgetflux.com/research.html
[nvm]: https://github.com/creationix/nvm
[post]: http://sam.gleske.net/blog/slice-of-life/2015/10/22/intro.html
[rvm]: https://rvm.io/
[stat]: https://travis-ci.org/samrocketman/blog.svg?branch=master
