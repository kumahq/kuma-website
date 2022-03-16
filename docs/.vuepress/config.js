/**
 * Tools
 */
require("dotenv").config();
const webpack = require("webpack");

/**
 * Product data
 */
// generate a random string for cache busting
const randStr = Math.random().toString(36).substring(2, 8)
const productData = {
  title: "Kuma",
  description: "Build, Secure and Observe your modern Service Mesh",
  twitter: "KumaMesh",
  author: "Kong",
  websiteRepo: "https://github.com/kumahq/kuma-website",
  repo: "https://github.com/kumahq/kuma",
  repoButtonLabel: "Star",
  logo: "/images/brand/kuma-logo-new.svg",
  hostname: "https://kuma.io",
  cliNamespace: "kumactl",
  slackInviteURL: "https://chat.kuma.io",
  slackChannelURL: "https://kuma-mesh.slack.com",
  gaCode: "UA-8499472-30",
  ogImage: "/images/social/og-image-1200-630.jpg",
  fbAppId: "682375632267551",
  cacheBuster: `cb=${randStr}`
}
const dirTree = require('directory-tree')
const path = require("path");
const fs = require("fs");
const versions = require("./versions.js");

/**
 * Site Configuration
 */
module.exports = {
  // theme configuration
  themeConfig: {
    domain: productData.hostname,
    gaCode: productData.gaCode,
    latestVersion: versions.latestMinor,
    versions: versions.allMinors,
    installMethods: require("./public/install-methods.json"),
    twitter: productData.twitter,
    author: productData.author,
    websiteRepo: productData.websiteRepo,
    repo: productData.repo,
    repoButtonLabel: productData.repoButtonLabel,
    cliNamespace: productData.cliNamespace,
    logo: productData.logo,
    slackInvite: productData.slackInviteURL,
    slackChannel: productData.slackChannelURL,
    docsDir: "docs",
    editLinks: false,
    sidebarDepth: 0,
    search: true,
    searchMaxSuggestions: 10,
    algolia: {
      apiKey: "",
      indexName: ""
    },
    sidebar: versions.allMinors.reduce((acc, v) => {
      acc[`/docs/${v}/`] = require(`../docs/${v}/sidebar.json`).map(sb => {
        // Add policy reference docs
        if (sb.title === "Reference docs") {
          const genPoliciesPath = path.resolve(__dirname, `../docs/${v}/generated/policies`);
          if (fs.existsSync(genPoliciesPath)) {
            const policies = fs.readdirSync(genPoliciesPath, {withFileTypes: true})
              .map(f => "generated/policies/" + f.name.replace(".md", ""));
            sb.children.push({"title": "Policies", "children": policies});
          }
          const genCmdPath = path.resolve(__dirname, `../docs/${v}/generated/cmd`);
          if (fs.existsSync(genCmdPath)) {
            const cmds = fs.readdirSync(genCmdPath, {withFileTypes: true})
              .filter(f => f.isDirectory())
              .map(f => `generated/cmd/${f.name}/${f.name}`);
            sb.children.push({"title": "Commands", "children": cmds});
          }
        }
        return sb;
      });
      return acc;
    }, {}),
    // displayAllHeaders: true,
    // main navigation
    nav: [
      {text: "Explore Policies", link: "/policies/"},
      {text: "Docs", link: "/docs/"},
      {text: "Community", link: "/community/"},
      {text: "Blog", link: "/blog/"},
      // { text: "Use Cases", link: "/use-cases/" },
      {text: "Enterprise", link: "/enterprise/"},
      {text: "Install", link: "/install/"}
    ]
  },
  title: productData.title,
  description: productData.description,
  host: "localhost",
  head: [
    // favicons, touch icons, web app stuff
    [
      "link",
      {
        rel: "apple-touch-icon",
        sizes: "180x180",
        href: `/images/apple-touch-icon.png?${productData.cacheBuster}`
      }
    ],
    [
      "link",
      {
        rel: "icon",
        href: `/images/favicon-32x32.png?${productData.cacheBuster}`
      }
    ],
    [
      "link",
      {
        rel: "icon",
        href: `/images/favicon-16x16.png?${productData.cacheBuster}`
      }
    ],
    [
      "link",
      {
        rel: "manifest", href: `/images/site.webmanifest?${productData.cacheBuster}`
      }
    ],
    [
      "link",
      {
        rel: "mask-icon", href: `/images/safari-pinned-tab.svg?${productData.cacheBuster}`,
        color: "#290b53"
      }
    ],
    [
      "link",
      {
        rel: "shortcut icon", href: `/images/favicon.ico?${productData.cacheBuster}`
      }
    ],
    [
      "meta",
      {
        name: "apple-mobile-web-app-title", content: productData.title
      }
    ],
    [
      "meta",
      {
        name: "application-name", content: productData.title
      }
    ],
    [
      "meta",
      {
        name: "msapplication-TileColor", content: "#2b5797"
      }
    ],
    [
      "meta",
      {
        name: "msapplication-config", content: `/images/browserconfig.xml?${productData.cacheBuster}`
      }
    ],
    [
      "meta",
      {
        name: "theme-color", content: "#290b53"
      }
    ],
    [
      "meta",
      {
        property: "fb:app_id", content: productData.fbAppId
      }
    ],
    // web fonts
    [
      "link",
      {
        rel: "stylesheet",
        href: "https://fonts.googleapis.com/css?family=Roboto+Mono|Roboto:400,500,700"
      }
    ],
    // [
    //   "script",
    //   {
    //     charset: "utf8",
    //     src: "/preloadPublicAssets.js",
    //     defer: "defer"
    //   }
    // ],
    // [
    //   "script",
    //   {
    //     charset: "utf8",
    //     src: "/unregisterServiceWorkers.js"
    //   }
    // ]
  ],
  // version release navigation
  additionalPages: [
    versions.allMinors.map(item => {
      return {
        path: `/install/${item}/`,
        meta: {
          version: item
        },
        frontmatter: {
          sidebar: false,
          layout: "Install"
        }
      };
    }),
  ],
  extendMarkdown: (md) => {
    md.use(require('markdown-it-include'), "docs/_snippets")
  },
  // plugin settings, build process, etc.
  markdown: {
    lineNumbers: true,
  },
  plugins: [
    (config = {}, ctx) => {
      // Plugin that will generate static assets from configuration
      const files = {
        "latest_version.html": versions.latestVersion,
        "releases.json": versions.allVersions,
        "images/docs/manifest.json": dirTree('./docs/.vuepress/public/images/docs', {
          extensions: /\.(jpg|png|gif)$/,
          normalizePath: true
        }),
        "robots.txt": `\
User-agent: *
Disallow: /latest_version
Disallow: /latest_version.html
${versions.oldMinors.map((v) => `Disallow: /docs/${v}`).join("\n")}

Sitemap: https://kuma.io/sitemap.xml
`
      };
      return {
        name: "static-files",
        generated() {
          for (let k in files) {
            fs.writeFileSync(path.resolve(ctx.outDir, k), k.endsWith(".json") ? JSON.stringify(files[k], null, 2) : files[k])
          }
        },
        beforeDevServer(app, _) {
          for (let k in files) {
            app.get("/" + k, (req, res) => res.send(files[k]))
          }
        }
      }
    },
    (config = {}, ctx) => {
      return {
        name: "netlify-configs",
        generated() {

          const redirects = [
            `/docs /docs/${versions.latestMinor} 301`,
            `/install /install/${versions.latestMinor} 200`,
            `/docs/latest/* /docs/${versions.latestMinor}/:splat 301`,
            `/install/latest/* /install/${versions.latestMinor}/:splat 301`,
            `/docs/:version/policies/ /docs/:version/policies/introduction 301`,
            `/docs/:version/overview/ /docs/:version/overview/what-is-kuma 301`,
            `/docs/:version/other/ /docs/:version/other/enterprise 301`,
            `/docs/:version/installation/ /docs/:version/installation/kubernetes 301`,
            `/docs/:version/api/ /docs/:version/documentation/http-api 301`,
            `/latest_version.html /latest_version 301`,
          ];
          // Add redirects for x.y.{0..5} to x.y.x
          versions.allMinors.forEach((minor) => {
            if (minor === "dev") {
              return;
            }
            versions.versions(minor).forEach(v => {
              redirects.push(
                `/docs/${v}/* /docs/${minor}/:splat 301`,
                `/install/${v}/* /install/${minor}/:splat 301`,
              )
            })
          });
          fs.writeFileSync(path.resolve(ctx.outDir, "_redirects"), redirects.join("\n"));
          fs.writeFileSync(path.resolve(ctx.outDir, "_headers"), `\
/latest_version
    Content-Type: text/plain
    Access-Control-Allow-Origin: *
          `);
        }

      }
    },
    (config = {}, ctx) => {
      return {
        name: "page-latest-version",
        extendPageData: (page) => {
          if (page.regularPath.startsWith("/docs")) {
            let v = page.regularPath.split("/")[2]
            if (!v) {
              return
            }
            let ver = versions.versions(v);
            if (ver) {
              page.latestVersion = ver[ver.length - 1];
            }
            let helmVersions = versions.helmVersions(v);
            if (helmVersions) {
              page.latestHelmVersion = helmVersions[helmVersions.length - 1];
            }
          }
        }
      }
    },
    ['code-copy', {color: "#4e1999", backgroundColor: '#4e1999'}],
    ["clean-urls", {normalSuffix: "/", indexSuffix: "/"}],
    ["sitemap", {hostname: productData.hostname}],
    ["seo", {
      customMeta: (add, context) => {
        const {$site, $page} = context;

        // Twitter and OpenGraph image URL string
        const ogImage = `${productData.hostname}${productData.ogImage}?cb=`

        // Twitter
        add("twitter:image", `${ogImage}${Math.random().toString(36).substring(2, 8)}`);
        add("twitter:image:alt", productData.description);
        add("twitter:description", productData.description);
        add("twitter:creator", `@${productData.twitter}`);

        // OpenGraph
        add("og:description", productData.description);
        add("og:image", `${ogImage}${Math.random().toString(36).substring(2, 8)}`);
        add("og:image:width", 1200);
        add("og:image:height", 630);
      }
    }],
    ["@vuepress/google-analytics", {ga: productData.gaCode}],
    // "@vuepress/plugin-pwa": {
    //   serviceWorker: false,
    //   updatePopup: false,
    //   generateSWConfig: {
    //     skipWaiting: true
    //   }
    // },
    ["@vuepress/nprogress"],
    ["tabs", {dedupeIds: true}],
    ["@vuepress/plugin-blog", {
      sitemap: {
        hostname: productData.hostname
      },
      directories: [
        {
          title: 'Blog',
          id: 'blog',
          dirname: '_blog',
          path: '/blog/',
          itemPermalink: '/blog/:year/:slug',
          layout: 'PostIndex',
          itemLayout: 'Post',
          pagination: {
            lengthPerPage: 5
          }
        }
      ]
    }],
    ["reading-time", {
      excludes: [
        "/policies",
        "/docs/.*",
        "/community",
        "/install",
        "/privacy",
        "/terms"
      ]
    }]
  ],
  postcss: {
    plugins: [
      require("tailwindcss"),
      require("autoprefixer")({
        grid: true
      })
    ]
  },
  // this is covered in the VuePress documentation
  // but it doesn't seem to work. Left here in case
  // that changes.
  extraWatchFiles: [
    "/public/install-methods.json",
  ],
  evergreen: false,
  configureWebpack: (config) => {
    return {
      plugins: [
        new webpack.EnvironmentPlugin({...process.env})
      ]
    }
  },
  shouldPrefetch: false,
  chainWebpack: (config, isServer) => {
    const jsRule = config.module.rule("js");
    jsRule
      .use("babel-loader")
      .loader("babel-loader")
      .options({
        presets: [
          [
            "@babel/preset-env",
            {
              useBuiltIns: "usage",
              corejs: 3,
              targets: {
                ie: 11,
                browsers: "last 2 versions"
              }
            }
          ]
        ]
      });
  }
};
