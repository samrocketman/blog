# My blog - [![Build Status][stat]][ci]

This is a blogging website where I post technical information for myself, Sam
Gleske.  If others find it useful then more power to 'em.  If you'd like to
learn more about me then check out my [first post][post].

# Features of my blog

- Minimal as possible while still remaining useful.
- Easy to copy and make your own.  All author settings for customizing this blog
  is stored in [`_config.yml`][c].
- Write blog posts in [GitHub flavored markdown][gfm].
- Slightly [reddish/pink tint which is good for readers' eyes][flux].
- Tags and categories.
- Integrated with some social media:
  - Disqus (for comments)
  - GitHub (for post history)
  - Keybase.io (links and hosting GPG keys for automated peer review)
  - Twitter (post sharing)
- Automated peer review available from 3rd parties by using `make test`.  It
  validates Grammar, GPG signatures, and even building the site.  This site uses
  [GitHub pull requests][pr] and Travis CI for automated peer review when
  publishing new blog posts.
- Three modes:
  1. development - social media buttons and comments removed.  All URLs point to
     localhost.
  2. simulated production - Just like production but all URLs point to
    localhost.  Good to check out just before publishing.
  3. production - The live site.

# Copy my blog and make it your own

1. Fork or clone this blog.  I recommend you clone and copy so you get stats in
   your GitHub profile.
2. Remove all posts from `_posts` and `_drafts`.
3. Customize `_config.yml` with your own information.
4. Update `LICENSE.txt` and make it your own.
4. Publish back to GitHub.

```bash
# Step 1
git clone https://github.com/samrocketman/blog
# Step 2
rm _posts/*.md* _drafts/*.md
# Step 3
vim _config.yml
# Step 4
git remote add myblog git@github.com:<your_username>/<your_blog>.git
git push myblog 'refs/heads/master:refs/heads/gh-pages'
```

> Note: `gh-pages` branch automatically gets published to GitHub pages.
> However, if you'd rather be more like this blog publishing from `master` you
> can customize the branch to master from the repository settings.

Legal note: the `3rd_party/` directory must remain intact in order to satisfy
license requirements of both work provided by myself and authors in which I
built upon.  It contains all notices and licenses for using other peoples'
source code.

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

[c]: _config.yml
[cc]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[ci]: https://travis-ci.org/samrocketman/blog
[ff-gm]: https://addons.mozilla.org/en-us/firefox/addon/greasemonkey/
[flux]: https://justgetflux.com/research.html
[gfm]: https://guides.github.com/features/mastering-markdown/
[kb.io]: https://keybase.io/
[nvm]: https://github.com/creationix/nvm
[post]: http://sam.gleske.net/blog/slice-of-life/2015/10/22/intro.html
[pr]: https://github.com/samrocketman/blog/pulls?q=is%3Apr
[rvm]: https://rvm.io/
[stat]: https://travis-ci.org/samrocketman/blog.svg?branch=master
