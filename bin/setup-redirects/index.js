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

  // setup the content template
  const template = `# Docs redirect
[[redirects]]
from = "/docs/"
to = "/docs/${latest}/"
status = 301
force = false

# Forms queries
from = "/"
query = {form_success = ":query"}
to = "/form_success=:query"
status = 301
force = false

# Install redirect
[[redirects]]
from = "/install/"
to = "/install/${latest}/"
status = 301
force = false

# Docs: Latest redirect
[[redirects]]
from = "/docs/latest/*"
to = "/docs/${latest}/:splat"
status = 301
force = false

# Install: Latest redirect
[[redirects]]
from = "/install/latest/*"
to = "/install/${latest}/:splat"
status = 301
force = false`;

  // write our redirects to the TOML file
  // this will write to the end of the file
  fs.writeFile(tomlFile, template, { flag: "a+" }, err => {
    if (err) throw err;
    console.log("Netlify redirects created successfully!");
  });
});
