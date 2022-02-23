const fs = require("fs");
const path = require("path");

/**
 * Create an object of which describes all the versions available and their meta from the list
 * of version directories and the presence of `versions.json` in each of these directories.
 * This should only be used in config.js
 */
let _versions = {};
let latestMinor = "";
fs.readdirSync(path.resolve(__dirname, "../../docs/docs"), {withFileTypes: true})
  .filter((file) => {
    return file.isDirectory()
  })
  .forEach((v) => {
    let fName = path.resolve(__dirname, `../../docs/docs/${v.name}/versions.json`);
    let meta = JSON.parse(fs.readFileSync(fName));
    if (!Array.isArray(meta.kuma) || meta.kuma.length === 0) {
      throw Error(`file ${fName} doesn't contain an entry "kuma" with an array of released versions`)
    }
    if (meta.helm && (!Array.isArray(meta.helm) || meta.helm.length === 0)) {
      throw Error(`file ${fName} has a "helm" entry that's not an array or it's empty`)
    }
    if (meta.latest) {
      if (latestMinor) {
        throw new Error(`Got 2 version marked as latest: ${v.name} and ${latestMinor}`)
      }
      latestMinor = v.name;
    }
    _versions[v.name] = meta;
  });

if (!latestMinor) {
  throw Error('No versions.json file is marked with "latest": true')
}

module.exports = {
  latestMinor,
  /// The latest patch version among all versions
  latestVersion: _versions[latestMinor].kuma.slice(-1)[0],
  /// All X.Y.x versions
  allMinors: Object.keys(_versions),
  /// All existing versions (across minor and patch)
  allVersions: [...new Set(Object.values(_versions).flatMap(obj => obj.kuma))],
  /// All minor versions that are not marked as "latest"
  oldMinors: Object.keys(_versions).reduce((acc, curr) => {
    if (!_versions[curr].latest) {
      acc.push(curr);
    }

    return acc;
  }, []),
  /// All patch versions of a minor version
  versions: (minor) => {
    return _versions[minor].kuma;
  },
  /// All helm chart versions of a minor version
  helmVersions: (minor) => {
    return _versions[minor].helm;
  },
};
