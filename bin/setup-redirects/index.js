#!/usr/bin/env node

const fs = require("fs");
const latestSemver = require("latest-semver");
const releases = "./docs/.vuepress/public/releases.json";
const tomlFile = "./netlify.toml";

// read the releases file so we can parse the data
fs.readFile(releases, "utf8", (err, data) => {
  if (err) throw err;

  // find the latest version in the releases JSON file
  const latest = latestSemver(JSON.parse(data));
  const docRedirectType = 301;

  // setup the content template
  const template = `# Proper Vue routing
# Docs redirect
[[redirects]]
from = "/docs/"
to = "/docs/${latest}/"
status = ${docRedirectType}
force = false

# Install redirect
[[redirects]]
from = "/install/"
to = "/install/${latest}/"
status = 200
force = false

# Docs: Latest redirect
[[redirects]]
from = "/docs/latest/*"
to = "/docs/${latest}/:splat"
status = ${docRedirectType}
force = false

# Install: Latest redirect
[[redirects]]
from = "/install/latest/*"
to = "/install/${latest}/:splat"
status = 200
force = false`;

  // write our redirects to the TOML file
  // this will write to the end of the file
  fs.writeFile(tomlFile, template, { flag: "a+" }, err => {
    if (err) throw err;
    console.log("Netlify redirects created successfully!");
  });
});
