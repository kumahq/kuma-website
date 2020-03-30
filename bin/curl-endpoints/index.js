#!/usr/bin/env node

const fs = require("fs");
const latestSemver = require("latest-semver");
const releases = "./docs/.vuepress/public/releases.json";

// the target file we are writing to
const targetFile = './docs/.vuepress/public/latest_version.html';

// read the releases file so we can parse the data
fs.readFile(releases, "utf8", (err, data) => {
  if (err) throw err;

  // find the latest version in the releases JSON file
  const output = latestSemver(JSON.parse(data));

  // write the version to our bare HTML file
  // for use with cURL and similar tools
  fs.writeFile(targetFile, output, { flag: "w" }, err => {
    if (err) throw err;
    console.log("cURL version endpoint created!");
  });
});
