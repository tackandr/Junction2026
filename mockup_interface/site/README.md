# VisioSense static concept site

This folder contains the static landing page and two read-only dashboard concept pages for GitHub Pages. It has no build step, data service, live telemetry, or external frontend dependency. Dashboard values and chart shapes are illustrative examples only.

Before the first deployment, a repository admin must enable Pages in **Settings → Pages → Build and deployment → Source → GitHub Actions**. The workflow's `GITHUB_TOKEN` can deploy an enabled Pages site, but it cannot enable Pages for the repository.

The GitHub Actions workflow at `.github/workflows/pages.yml` publishes this folder on pushes to `master` and can also be run manually. It uses current Node.js 24 compatible GitHub Actions.

For the implemented prototype and setup steps, see the [VisioSense README](https://github.com/tackandr/Junction2026/blob/master/visiosense/README.md).
