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
- Automated peer review.
- Three modes:
  1. development - distractions like social media buttons and comments removed.
  2. simulated production - Just like production but local.  Good to check out
     before publishing when customizing style and layout.
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
vim LICENSE.txt
# Step 5
git remote add myblog git@github.com:<your_username>/<your_blog>.git
git push myblog 'refs/heads/master:refs/heads/gh-pages'
```

> Note: `gh-pages` branch automatically gets published to GitHub pages.
> However, if you'd rather be more like this blog publishing from `master`, then
> you can customize the branch to master from the repository settings.

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

The blog requires Ruby 2.4 to be installed.  It's best to use [rvm][rvm] for
Ruby.

Set up with `rvm`.

    rvm install 2.4
    #optionally install within a "blog" gemset
    rvm use 2.4@blog --create

If you encounter an error about not being in a login shell then use `bash -l` to
create one.  Now when you open a new terminal be sure to execute the following
commands before modifying the blog.

    rvm use 2.4@blog --create

Install dependencies.

    make deps

#### Developing the site

There a "make" commands which make developing this blog easier and performing
more complex tasks.

- `make` - Starts the website removing all distractions (development mode).
- `make prod` - Starts a local copy of the website like it is meant to be viewed
  in production (simulated production mode).
- `make test` - Performs automated peer review and generates the live site in
  the `_site/` directory (production mode).

Other make commands:

- `make history` - will generate data for your site which will be used for the
  "last updated" links in blog posts.  This automatically gets run with `make
  test` as well.
- `make sign` - will GPG sign blog posts which have changed using your default
  GPG private key.

# Automated peer review

What is it?  It performs common and repeatable tasks a person would normally do
when checking this blog.  Rather than having to do it you're able to rely on
computers to check it for you.

What sort of tasks are performed in automated peer review for this blog?

- Grammar and spelling checking.  It smartly checks posts which have changed
  rather than everything.
- GPG signature checking for blog posts to ensure you didn't miss signing your
  content.
- Builds the website for uploading to other sources.

Automated peer review is useful to run before you even publish the website for
readers to see.  I use [GitHub pull requests][pr] and Travis CI for automated
peer review when publishing my new blog posts.

> Note: Grammar and spell checking isn't perfect due to the technical nature of
> my blog.  I have added `grammar_ignore.dict` for skipping keywords and
> `grammar_skip.sentences` for skipping whole sentences when I'm writing.  It
> doesn't always get it right but it still forces me to double check the
> sentences it calls out.

# Tips for myself

Sign any changed blog posts:

    make sign

Sign a commit:

    git commit -S

# Summary of Licenses

All source code is MIT Licensed by [LICENSE.txt](LICENSE.txt) with exception
for:

- All content under `_drafts/`, `_posts/`, and `images/` is licensed under
  [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International][cc]
  and is governed by the contents of [LICENSE.txt](LICENSE.txt).
- Any content governed by 3rd parties which is covered by copyrights, licenses,
  and notices outlined in the [`3rd_party/`](3rd_party) folder.

[c]: _config.yml
[cc]: https://creativecommons.org/licenses/by-nc-sa/4.0/
[ci]: https://travis-ci.org/samrocketman/blog
[flux]: https://justgetflux.com/research.html
[gfm]: https://guides.github.com/features/mastering-markdown/
[kb.io]: https://keybase.io/
[nvm]: https://github.com/creationix/nvm
[post]: http://sam.gleske.net/blog/slice-of-life/2015/10/22/intro.html
[pr]: https://github.com/samrocketman/blog/pulls?q=is%3Apr
[rvm]: https://rvm.io/
[stat]: https://travis-ci.org/samrocketman/blog.svg?branch=master
