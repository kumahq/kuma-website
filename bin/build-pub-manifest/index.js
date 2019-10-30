const fs = require('fs')
const path = require('path')
const dirTree = require('directory-tree')

const srcDir = './docs/.vuepress/public/images/docs'
const manifest = './docs/.vuepress/public/images/docs/manifest.json'

const files = dirTree(srcDir, {
  extensions: /\.(jpg|png|gif)$/,
  normalizePath: true
})

fs.writeFile( manifest, JSON.stringify(files, null, 2), err => {
  if (err) throw err
  console.log('Public asset data written to the public assets manifest!')
})