---
layout: post
title: Building Composable CLI Utilities
category: engineering
tags:
 - programming
 - python
 - shell
 - tips
year: 2017
month: 10
day: 25
published: true
type: markdown
---

The idea of composable command line (CLI) utilities is simple.  CLI utilities
should be built for reuse in other programs and scripts.  They should be able to
be composed as a part of a [compound command][bash-cc] in a shell script.

# Standard anatomy of a program on Unix-like systems

This discussion is agnostic to the language you're using to develop the CLI
utility because all programs in Linux have standard features for interacting
with other programs.

- Receiving input on stdin (file descriptor 0)
- Outputting to stdout (file descriptor 1)
- Outputting to stderr (file descriptor 2)
- File descriptors beyond 0, 1, and 2 are available but are not necessary.  It
  depends on the use case of the utility.
- Exiting with an integer exit code between 0 and 255.

Here's an example of each component being used in a shell script:

{% highlight bash %}
# Read stdin for user or program input
read -sp 'Password:' USER_PASSWORD

# Outputting to stdout
echo "Hello world"

# Outputting to stderr
echo "See you later world" 1>&2

# Exiting with an exit code of 3
exit 3
{% endhighlight %}

Here's an example of each component being used in a Python script:

{% highlight python %}
import sys

# Read stdin for JSON blob
json.load(sys.stdin)

# Outputting to stdout
print "Hello world"

# Outputting to stderr
print >> sys.stderr, 'See you later world'

# Exiting with an exit code of 3
sys.exit(3)
{% endhighlight %}

# What is a composable CLI utility?

To put simply, it is a utility which can be combined with other programs in
order to make a more complex program.  For example, take the following one
liner which reads a file for specific lines and then alphabetically sorts the
output.

{% highlight bash %}
grep '^g' file.txt | sort
{% endhighlight %}

`grep` is outputting to stdout and `sort` is reading `grep` output on stdin.
`grep` and `sort` are what I would call composable utilities.  In a shell
script, simple programs can be chained together to create a more advanced
program.

# Utilizing standard features effectively

In Bash and other shells, exit codes of a program play a major role in how that
program is used in logic.  The same could be said programs interacting with each
other using input and output.  With this in mind, in order to build a CLI
utility which is composable I recommend the adhering to the following
conventions.

- When a program has an option to read a file, ensure that file can also be read
  from `stdin`.
- Output results and data which are meant to be processed by other programs to
  stdout.
- Output messages intended for the user and error messages on stderr.
- In shell, an exit code of zero (`0`) means success.  A failure is non-zero.
  This is because there's only one reason for success.  There could be many
  reasons why a utility would fail.

It makes sense to write wrapper methods around these concepts.  Here's some
example wrapper methods in bash.

{% highlight bash %}
# output to stdout so other programs can process the output
function programOutput() {
  echo "$@"
}

# error messages (outputs to stderr)
function printErr() {
  echo "$@" 1>&2
}

# messages meant for the user (outputs to stderr)
function userMsg() {
  errMessage "$@"
}

# exit with a zero exit code (success)
function exitSuccess() {
  exit
}

# exit with a non-zero exit code (failure)
function exitFailed() {
  # by default exits with 1 but can specify a custom exit code
  exit "${1:-1}"
}
{% endhighlight %}

Here's a python example which includes wrapper methods for these concepts.

{% highlight python %}
import sys

# output to stdout so other programs can process the output
def programOutput(message=''):
    print message

# error messages (outputs to stderr)
def printErr(message=''):
    sys.stderr.write(message + '\n')
    sys.stderr.flush()

# messages meant for the user (outputs to stderr)
def userMsg(message=''):
    printErr(message)

# exit with a zero exit code (success)
def exitSuccess():
    sys.exit()

# exit with a non-zero exit code (failure)
def exitFailed(code=1):
    # by default exits with 1 but can specify a custom exit code
    sys.exit(code)
{% endhighlight %}

Some of the names are exagerated but it's to illustrate the point.  For example,
for printing to stdout I would probably just use `echo` in Bash.  In Python, I
would just use `print` or `printf` for printing to stdout.  However, the primary
purpose here is to elaborate for better understanding.

Hopefully, your own scripts will level up and become a library of composable CLI
utilities.  It is good for a CLI utility when reuse in shell scripts is part of
the design.

[bash-cc]: https://www.gnu.org/software/bash/manual/html_node/Compound-Commands.html
