/**
 * Tools
 */
const path = require("path");
require("dotenv").config();
const webpack = require("webpack");

/**
 * Releases
 */
const LatestSemver = require("latest-semver");
const releases = require("./public/releases.json");
const latestVersion = LatestSemver(releases);

/**
 * Product data
 */
const productData = require("./site-config/product-info");

/**
 * Sidebar navigation structure
 */
const sidebarNav = require("./site-config/sidebar-nav");

/**
 * Install methods route builder
 */
const releaseArray = require("./site-config/install-route-builder");

/**
 * Site Configuration
 */
module.exports = {
  // theme configuration
  themeConfig: {
    domain: productData.hostname,
    gaCode: productData.gaCode,
    latestVer: latestVersion,
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
    sidebar: sidebarNav,
    // displayAllHeaders: true,
    // main navigation
    nav: [
      { text: "Explore Policies", link: "/policies/" },
      { text: "Docs", link: "/docs/" },
      { text: "Community", link: "/community/" },
      { text: "Blog", link: "/blog/" },
      // { text: "Use Cases", link: "/use-cases/" },
      { text: "Enterprise", link: "/enterprise/" },
      { text: "Install", link: "/install/" }
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
  additionalPages: [releaseArray],
  // plugin settings, build process, etc.
  markdown: {
    lineNumbers: true,
    extendMarkdown: md => {
      // include files in markdown
      md.use(require("markdown-it-include"), "./docs/.partials/");
    }
  },
  plugins: {
    "clean-urls": {
      normalSuffix: "/",
      indexSuffix: "/"
    },
    sitemap: {
      hostname: productData.hostname
    },
    seo: {
      customMeta: (add, context) => {
        const { $site, $page } = context;

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
    },
    "@vuepress/google-analytics": {
      ga: productData.gaCode
    },
    // "@vuepress/plugin-pwa": {
    //   serviceWorker: false,
    //   updatePopup: false,
    //   generateSWConfig: {
    //     skipWaiting: true
    //   }
    // },
    "@vuepress/nprogress": {},
    "tabs": {
      dedupeIds: true
    },
    "@vuepress/plugin-blog": {
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
    },
    "vuepress-plugin-reading-time": {
      excludes: [
        "/policies",
        "/docs/.*",
        "/community",
        "/install",
        "/privacy",
        "/terms"
      ]
    }
  },
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
    "/docs/.partials/*",
    "/site-config/product-info.js",
    "/site-config/sidebar-nav.js",
    "/public/install-methods.json",
    "/public/releases.json"
  ],
  evergreen: false,
  configureWebpack: (config) => {
    return {
      plugins: [
        new webpack.EnvironmentPlugin({ ...process.env })
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
