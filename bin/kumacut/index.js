#!/usr/bin/env node

// required tools
const fs = require("fs-extra");
const path = require("path");
const replace = require("replace-in-file");
const program = require("commander");
const chalk = require("chalk");
const LatestSemver = require("latest-semver");

// script meta
const namespace = "Kuma";
const scriptVer = "0.0.1";

// app version info
const releases = path.resolve(
  __dirname,
  "../../docs/.vuepress/public/releases.json"
);
const sidebarNav = path.resolve(
  __dirname,
  "../../docs/.vuepress/site-config/sidebar-nav.js"
);
const latest = LatestSemver(require(releases));
const sourcVersionDir = path.resolve(__dirname, `../../docs/docs/${latest}`);

// this is the token we replace in the documentation
// markdown files when cutting a new release
const verToken = new RegExp(latest, "gm");

/**
 * @function replaceVerToken
 *
 * @description This will search for the version token in our source docs folder
 * and replace it with the version number specified by our release type
 */
replaceVerToken = (token, ver, dest) => {
  const options = {
    files: dest,
    from: token,
    to: ver
  };

  try {
    const results = replace.sync(options);
    console.log(
      `${chalk.green.bold("✔")} Version number updated to ${chalk.blue.bold(
        ver
      )} in all Markdown files!`
    );
    console.log(`${chalk.green.bold("✔")} ${chalk.black.bgYellow('Please make sure to update "sidebar-nav.js" accordingly!')}`);
  } catch (err) {
    console.log(chalk.red.bold(err));
  }
};

/**
 * @function cloneDirAndReplace
 *
 * @description Copy the base version directory to a new one and then replace
 * the version token in the doc files
 */
cloneDirAndReplace = (source, dest, ver) => {
  fs.copy(source, dest)
    .then(() => {
      // let the user know that their folder has been created
      console.log(`${chalk.green.bold("✔")} New version folder created!`);
    })
    .then(() => {
      // replace the version token in the documentation markdown files accordingly
      replaceVerToken(verToken, ver, `${dest}/**/*.md`);
      console.log(dest);
    })
    .catch(err => {
      console.log(chalk.red.bold(err));
    });

    // console.log(latest)
};

/**
 * @function updateReleaseList
 *
 * @description Updates the release list JSON file to include the new version
 */
updateReleaseList = (list, ver) => {
  const listSrc = require(list);
  let versions = listSrc;

  // update the release object
  versions.push(ver);

  // write the new object to the release list
  fs.writeFileSync(list, JSON.stringify(versions, null, 2), err => {
    if (err) {
      console.log(chalk.red.bold(err));
    }

    console.log(
      `${chalk.green.bold("✔")} ${chalk.blue.bold(
        ver
      )} added to release list file!`
    );
  });
};

/**
 * @function bumpVersion
 *
 * @description Bump the version based on the release type or a custom value.
 */
bumpVersion = (type, val) => {
  let currentVer = latest.split(".");
  let major = parseInt(currentVer[0]);
  let minor = parseInt(currentVer[1]);
  let patch = parseInt(currentVer[2]);
  let label, version;

  switch (type) {
    case "major":
      version = `${major + 1}.${minor}.${patch}`;
      label = "major";
      break;
    case "minor":
      version = `${major}.${minor + 1}.${patch}`;
      label = "minor";
      break;
    case "custom":
      version = val.replace("v", "");
      label = "custom";
      break;
    default:
      version = `${major}.${minor}.${patch + 1}`;
      label = "patch";
      break;
  }

  console.log(
    `${chalk.green.bold("✔")} New Release: ${chalk.blue.bold(
      label
    )}, ${chalk.green.bold(latest)} ➜ ${chalk.green.bold(version)}`
  );

  // create the new version folder accordingly
  cloneDirAndReplace(
    sourcVersionDir,
    path.resolve(__dirname, `../../docs/docs/${version}`),
    version
  );

  // update the release list
  updateReleaseList(releases, version);

  /**
   * DEPRECATED: this function is disabled for now because of how complex
   * the sidebar has become. a new approach is needed to automating its
   * construction.
   */
  // update the sidebar configuration
  // updateSidebarConfig(sidebarNav, version);
};

/**
 * @function updateSidebarConfig
 *
 * @description Updates the sidebar config file based on the
 * structure of our documentation folder
 */
updateSidebarConfig = (source, version) => {
  let sourceFile = require(source);
  let lastItem = Object.keys(sourceFile).slice(-1);
  let newParentItem = `/docs/${version}/`;

  let subItems = [];
  let coupledItems = [];
  let finalItemGroup = [];

  lastItem.forEach(key => {
    subItems = sourceFile[key];
    coupledItems[newParentItem] = subItems;
    finalItemGroup = Object.assign(sourceFile, coupledItems);
    finalItemGroup = `module.exports = ${JSON.stringify(
      finalItemGroup,
      null,
      2
    )}`;
  });

  // write the new nav structure to the config file
  fs.writeFileSync(source, finalItemGroup, err => {
    if (err) {
      console.log(chalk.red.bold(err));
    }

    console.log(
      `${chalk.green.bold("✔")} ${chalk.blue.bold(
        version
      )} added to release list file!`
    );
  });
};

// all of our program's option and functionality couplings
program.version(
  scriptVer,
  "-v, --version",
  "Output the current version of this script."
);

program
  .command("latest")
  .description(`display the latest version of ${namespace}`)
  .action(() => {
    console.log(
      `The latest version of ${namespace} in these docs is ${chalk.green.bold(
        latest
      )}`
    );
  });

// simple command for cutting a new patch
program
  .command("bump")
  .description(
    "this will simply cut a new patch and bump the patch number up by 1"
  )
  .action(() => {
    bumpVersion("patch");
  });

// command for cutting a new version
program
  .command("new <type> [ver]")
  .description(
    "options: major, minor, custom <version>"
  )
  .action((type, ver) => {
    if (ver && type === "custom") {
      bumpVersion(type, ver);
    } else if (!ver && type === "custom") {
      console.log(
        chalk.red.bold("A version must be supplied with the custom option!")
      );
    } else {
      bumpVersion("patch");
    }
  });

program.parse(process.argv);
