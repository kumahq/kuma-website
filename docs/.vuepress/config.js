/**
 * Release data
 */
const releases = require('./public/releases.json')

/**
 * Product data
 * 
 * Change these values as needed
 */

const productData = {
  title: 'Konvoy',
  description: 'Connect, Secure and Observe any traffic and Microservices',
  twitter: 'konvoy',
  author: 'Kong',
  repo: 'https://github.com/kong/konvoy',
  repoButtonLabel: 'Star',
  logo: '/konvoy-logo.svg',
  hostname: 'https://getkonvoy.com'
}

/**
 * Sidebar navigation structure
 * 
 * Always include a trailing slash but
 * avoid a slash at the front of the
 * directory.
 * 
 * Correct: 'getting-started/'
 * Incorrect: '/getting-started/'
 * 
 */
const sidebarNav = {
  '/docs/0.1.0/': [
    '',
    'getting-started/',
    'documentation/',
    'tutorials/',
    'installation/',
    'community/'
  ],
  '/docs/0.2.0/': [
    '',
    'getting-started/',
    'documentation/',
    'tutorials/',
    'installation/',
    'community/'
  ]
}

/**
 * Install page version URL builder
 * 
 * This pulls all of the versions from the releases
 * JSON and builds the routes accordingly.
 * 
 * @todo figure out how to get this to work via
 * `router.addRoutes` instead (ran into problems
 * with it in VuePress)
 * 
 */
function buildInstallReleaseURLs() {
  // build the release route array
  const releaseArray = []

  for ( let i = 0; i < releases.length; i++ ) { 
    releaseArray.push({
      path: `/install/${releases[i]}/`,
      meta: {
        version: releases[i]
      },
      frontmatter: {
         sidebar: false,
         layout: 'Install'
      }
   })
  }

  return releaseArray
}

/**
 * Site Configuration
 */
module.exports = {
  title: productData.title,
  description: productData.description,
  host: productData.hostname,
  themeConfig: {
    twitter: productData.twitter,
    author: productData.author,
    repo: productData.repo,
    repoButtonLabel: productData.repoButtonLabel,
    logo: productData.logo,
    footer: productData.title,
    docsDir: 'docs',
    editLinks: true,
    search: true,
    searchMaxSuggestions: 10,
    algolia: {
      apiKey: '',
      indexName: ''
    },
    sidebar: sidebarNav,
    displayAllHeaders: true,
    nav: [
      { text: 'Documentation', link: '/docs/' },
      { text: 'Community', link: '/community/' },
      { text: 'Use Cases', link: '/use-cases/' },
      { text: 'Request Demo', link: '/request-demo/' },
      { text: 'Install', link: '/install/' }
    ]
  },
  markdown: {
    lineNumbers: true,
    extendMarkdown: md => {
      md.use(require('markdown-it-include'), {
        root: __dirname
      })
    }
  },
  plugins: {
    'clean-urls': {
      normalSuffix: '/',
      indexSuffix: '/'
    },
    'seo': {
      customMeta: (add, context) => {
        const {
          $site,
          $page,
          siteTitle, title, description, author, tags,
          twitterCard, type, url, image, publishedAt, modifiedAt,
        } = context

        add( 'twitter:site', $site.themeConfig.twitter )
      }
    },
    'sitemap': {
      hostname: productData.hostname
    }
  },
  additionalPages: [buildInstallReleaseURLs],
  head: [
    [
      'link',
      {
        // TODO change this to a Konvoy-specific one (or move this locally?)
        rel: 'icon',
        href:
          'https://2tjosk2rxzc21medji3nfn1g-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kong-logomark-color-64px.png'
      }
    ],
    [
      'link',
      {
        rel: 'stylesheet',
        href:
          'https://fonts.googleapis.com/css?family=Roboto+Mono|Roboto:400,500,700'
      }
    ]
  ],
  postcss: {
    plugins: [
      require('tailwindcss'),
      require('autoprefixer')
    ]
  },
  chainWebpack: config => {
    const svgRule = config.module.rule('svg');

    svgRule.uses.clear();
    svgRule
      .oneOf('external')
      .resourceQuery(/external/)
      .use('url')
      .loader('url-loader')
      .options({
        limit: 10000,
        name: 'public/[name].[hash:7].[ext]'
      })
      .end()
      .end()
      .oneOf('normal')
      .use('raw')
      .loader('raw-loader')
      .end()
      .end();
  }
};
