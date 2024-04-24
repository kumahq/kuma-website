# Contributing to Kuma's Website

Hello, and welcome! Whether you are looking for help, trying to report a bug, thinking about getting involved in the project or about to submit a patch, this document is for you! Its intent is to be both an entry point for newcomers to the community (with various technical backgrounds), and a guide/reference for contributors and maintainers.

## Where to seek help?

[Slack](https://kuma-mesh.slack.com) is the main chat channel used by the community and the maintainers of this project. If you do not have an existing account, please follow this [link](https://join.slack.com/t/kuma-mesh/shared_invite/zt-1rcll3y6t-DkV_CAItZUoy0IvCwQ~jlQ) to sign up for free.

**Please avoid opening GitHub issues for general questions or help**, as those should be reserved for actual bug reports. The Kuma community is welcoming and more than willing to assist you on Slack!

## Where to report bugs?

Feel free to [submit an issue](https://github.com/kumahq/kuma-website/issues/new/choose) on the GitHub repository, we would be grateful to hear about it! Please provide a direct link to the webpage that contains the issue and make sure to respect the GitHub issue template, and include:

1. A summary of the issue
2. A list of steps to reproduce the issue

If you wish, you are more than welcome to propose a patch to fix the issue! See the [Submit a patch](#submitting-a-patch) section for more information on how to best do so.

## Contributing

We welcome contributions of all kinds, you do not need to code to be helpful! All of the following tasks are noble and worthy contributions that you can make without coding:

- Reporting a bug (see the [report bugs](#where-to-report-bugs) section)
- Helping other members of the community on Slack
- Fixing a typo in the documentation
- Providing your feedback on the proposed features and designs
- Reviewing Pull Requests

If you wish to contribute code (features or bug fixes), see the [Submitting a patch](#submitting-a-patch) section.

### Submitting a patch

Feel free to contribute fixes or minor features, we love to receive Pull Requests! If you are planning to develop a larger feature, come talk to us first on [Slack](#where-to-seek-for-help)!

When contributing, please follow the guidelines provided in this document and [WRITING-DOCUMENTATION.md](WRITING-DOCUMENTATION.md). They will cover topics such as the different Git branches we use, the commit message format to use or the appropriate code style.

Once you have read them, and you are ready to submit your Pull Request, be sure to verify a few things:

- We do trunk based development so the only valid branch to open a PR against is `master`.
- Your commit history is clean: changes are atomic and the git message format was respected
- Rebase your work on top of the base branch (seek help online on how to use `git rebase`; this is important to ensure your commit history is clean and linear)

If the above guidelines are respected, your Pull Request will be reviewed by a maintainer.

If you are asked to update your patch by a reviewer, please do so! Remember: **you are responsible for pushing your patch forward**. If you contributed it, you are probably the one in need of it. You must be prepared to apply changes to it if necessary.

If your Pull Request was accepted and fixes a bug, adds functionality, or makes it significantly easier to use or understand Kuma's website, congratulations! You are now an official contributor to Kuma. Get in touch with us to receive your very own [Contributor T-shirt](#contributor-t-shirt)!

#### Sign Your Work

The sign-off is a simple line at the end of the explanation for a commit. All commits need to be signed. Your signature certifies that you wrote the patch or otherwise have the right to contribute the material. The rules are pretty simple, if you can certify the below (from [developercertificate.org](https://developercertificate.org/)):

To signify that you agree to the DCO for a commit, you add a line to the git commit message:

```txt
Signed-off-by: Jane Smith <jane.smith@example.com>
```

In most cases, you can add this signoff to your commit automatically with the `-s` flag to `git commit`. You must use your real name and a reachable email address (sorry, no pseudonyms or anonymous contributions).

### Running the site locally

Clone the repository and run:
```
make install
```
make sure you have the right ruby version installed (`cat .ruby-version`).
Jekyll is a static-site generator, so first we need to build the site and compile the assets:
```
make build
```
Note: If you face any issues, e.g. the asset don't look right, try cleaning the cache first and re-build the site:
```
make clean && make build
```

Next, run
```
make serve
```
which will run `Netlify` locally in a local dev server, similar to production, making all the redirects, env variables, etc.
available. You can visit http://localhost:8888/ and start reading the documentation.

#### Modifying files locally

If you want to make changes to the docs or the assets and see them reflected on the browser, you need to run the site with:
```
make run
```
This will run `jekyll serve` and `vite` in the background wich wil re-build the corresponding pages whenever a doc or asset changes,
while running `netlify dev` so that all the redirects work locally.
