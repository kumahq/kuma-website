module.exports = {
  title: 'Konvoy',
  description: 'Connect, Secure and Observe any traffic and Microservices',
  host: 'localhost',
  themeConfig: {
    extend: '@vuepress/theme-default',
    repo: 'kong/konvoy',
    logo: 'konvoy-logo.svg',
    docsDir: 'vuepress',
    editLinks: false,
    sidebarDepth: 0,
    algolia: {
      apiKey: '',
      indexName: ''
    },
    sidebar: [
      '/',
      {
        title: 'Getting Started',
        collapsable: true,
        children: [
          '/master/getting-started/concepts',
          '/master/getting-started/technology',
          '/master/getting-started/dependencies',
          '/master/getting-started/architectural-diagrams',
          '/master/getting-started/quickstart',
        ]
      },
      {
        title: 'Documentation',
        collapsable: true,
        children: [
          '/master/documentation/running-in-kubernetes',
          '/master/documentation/running-on-other-platforms',
          '/master/documentation/ingress-traffic',
          '/master/documentation/service-mesh-traffic',
          '/master/documentation/installation',
          '/master/documentation/crd-reference',
          '/master/documentation/api-reference',
        ]
      },
      {
        title: 'Tutorials',
        collapsable: true,
        children: [
          '/master/tutorials/multi-tenancy',
          '/master/tutorials/observing-traffic',
          '/master/tutorials/platform-agnostic-service-mesh',
          '/master/tutorials/routing-ingress-traffic',
          '/master/tutorials/routing-traffic',
          '/master/tutorials/securing-traffic',
          '/master/tutorials/segmenting-traffic',
        ]
      },
    ],
    nav: [
      { text: 'Documentation', link: '/documentation' },
      { text: 'Use Cases', link: '/use-cases' },
      { text: 'Enterprise', link: '/enterprise' },
      { text: 'Install', link: '/install' }
    ]
  },
  head: [
    ['link', { rel: 'icon', href: 'https://2tjosk2rxzc21medji3nfn1g-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kong-logomark-color-64px.png' }],
    ['link', { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css?family=Roboto+Mono|Roboto:400,500,700' }]
  ],
  postcss: {
    plugins: [
      require('tailwindcss'),
      require('autoprefixer')
    ]
  },
  chainWebpack: config => {
    const svgRule = config.module.rule('svg')

    svgRule.uses.clear()
    svgRule
      .oneOf('external')
      .resourceQuery(/external/)
      .use('url')
      .loader('url-loader')
      .options({
        limit: 10000,
        name: 'img/[name].[hash:7].[ext]'
      }).end().end()
      .oneOf('normal')
      .use('raw')
      .loader('raw-loader')
      .end().end()
  }
}
