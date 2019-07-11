#!/usr/bin/env node

// Update /public/releases.json for documentation versioning

const filePath =  `${__dirname}/.vuepress/public/releases.json`
const fs = require('fs')
const releases = require(filePath)
releases.tags.splice(0, 0, { name: process.env.npm_package_version })

try {
  const data = fs.writeFileSync( filePath, JSON.stringify(releases, null, 2 ))
} catch (err) {
  console.log(err)
}