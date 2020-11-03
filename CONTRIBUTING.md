# Contributing to Kuma's Website

Hello, and welcome! Whether you are looking for help, trying to report a bug,
thinking about getting involved in the project or about to submit a patch, this
document is for you! Its intent is to be both an entry point for newcomers to
the community (with various technical backgrounds), and a guide/reference for
contributors and maintainers.

Consult the Table of Contents below, and jump to the desired section.

## Table of Contents

- [Contributing to Kuma's Website](#contributing-to-kumas-website)
  - [Table of Contents](#table-of-contents)
  - [Where to seek help?](#where-to-seek-help)
  - [Where to report bugs?](#where-to-report-bugs)
  - [Contributing](#contributing)
    - [Submitting a patch](#submitting-a-patch)
      - [Writing tests](#writing-tests)
    - [Contributor T-shirt](#contributor-t-shirt)

## Where to seek help?

[Slack](https://kuma-mesh.slack.com) is the main chat channel used by the
community and the maintainers of this project. If you do not have an
existing account, please follow this [link](https://chat.kuma.io) to sign
up for free.

**Please avoid opening GitHub issues for general questions or help**, as those
should be reserved for actual bug reports. The Kuma community is welcoming and
more than willing to assist you on Slack!

[Back to TOC](#table-of-contents)

## Where to report bugs?

Feel free to [submit an issue](https://github.com/kumahq/kuma-website/issues/new) on
the GitHub repository, we would be grateful to hear about it! Please be provide a direct link to the webpage that contains the issue.

If you wish, you are more than welcome to propose a patch to fix the issue!
See the [Submit a patch](#submitting-a-patch) section for more information
on how to best do so.

[Back to TOC](#table-of-contents)

## Contributing

We welcome contributions of all kinds, you do not need to code to be helpful!
All of the following tasks are noble and worthy contributions that you can
make without coding:

- Reporting a bug (see the [report bugs](#where-to-report-bugs) section)
- Helping other members of the community on Slack
- Fixing a typo in the documentation
- Providing your feedback on the proposed features and designs
- Reviewing Pull Requests

If you wish to contribute code (features or bug fixes), see the [Submitting a
patch](#submitting-a-patch) section.

[Back to TOC](#table-of-contents)

### Submitting a patch

Feel free to contribute, we love to receive Pull
Requests! If you have any questions throughout the process, come chat with us first on [Slack](#where-to-seek-for-help)!

When contributing, please follow the guidelines provided in this document. They
will cover topics such as the different Git branches we use, the commit message
format to use or the appropriate code style.

Once you have read them, and you are ready to submit your Pull Request, be sure
to verify a few things:

- Your work was based on the appropriate branch (`master` or `next` vs. `feature/latest`),
  and you are opening your Pull Request against the appropriate one
- Updates that affect the current website and current version of the Kuma documentation 
  should be opened against `master`. Updates that are only going to be effective from the 
  next version of Kuma should be opened against `next` on the same folder as the current
  Kuma version. Prior to any new release we will merge all the PRs against `next` into
  `next`, copy the latest documentation folder into the new release folder, and merge
  against `master`.
- Your commit history is clean: changes are atomic and the git message format
  was respected
- Rebase your work on top of the base branch (seek help online on how to use
  `git rebase`; this is important to ensure your commit history is clean and
   linear)
- The tests are passing: run `yarn test` 

If the above guidelines are respected, your Pull Request will be reviewed by
a maintainer. And if you are asked to update your patch by a reviewer, please do so!

If your Pull Request was accepted and fixes a bug, adds functionality, or
makes it significantly easier to use or understand Kuma's website, congratulations!
You are now an official contributor to Kuma. Get in touch with us to receive
your very own [Contributor T-shirt](#contributor-t-shirt)!

[Back to TOC](#table-of-contents)

#### Writing tests

We use [Jest](https://jestjs.io/) to write our tests. Your patch
should include the related test updates or additions, in the appropriate test
suite.

[Back to TOC](#table-of-contents)

### Contributor T-shirt

If your Pull Request to [kumahq/kuma](https://github.com/kumahq/kuma) was
accepted, and it fixes a bug, adds functionality, or makes it significantly
easier to use or understand Kuma, congratulations! You are eligible to
receive the very special Contributor T-shirt! Go ahead and fill out the
[Contributors Submissions form](https://goo.gl/forms/5w6mxLaE4tz2YM0L2).

[Back to TOC](#table-of-contents)