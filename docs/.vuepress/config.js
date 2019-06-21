
module.exports = {
  title: 'Konvoy',
  description: 'Connect, Secure and Observe any traffic and Microservices',
  themeConfig: {
    repo: 'kong/konvoy',
    logo: 'https://2tjosk2rxzc21medji3nfn1g-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kong-logomark-color-64px.png',
    docsDir: 'vuepress',
    editLinks: false,
    sidebarDepth: 0,
    sidebar: [
      '/',
      {
        title: 'Getting Started',
        collapsable: true,
        children: [
          '/concepts',
          '/technology',
          '/dependencies',
          '/architectural-diagrams',
          '/quickstart'
        ]
      },
      {
        title: 'Documentation',
        collapsable: true,
        children: [
          '/running-in-kubernetes',
          '/running-on-other-platforms',
          '/ingress-traffic',
          '/service-mesh-traffic',
          '/installation',
          '/crd-reference',
          '/api-reference'
        ]
      },
    ],
    nav: [
      { text: 'Documentation', link: '/docs' },
      { text: 'Use Cases', link: '/use-cases' },
      { text: 'Enterprise', link: '/enterprise' },
      { text: 'Install', link: '/install' }
    ]
  },
  head: [
    ['link', { rel: 'icon', href: 'https://2tjosk2rxzc21medji3nfn1g-wpengine.netdna-ssl.com/wp-content/uploads/2018/08/kong-logomark-color-64px.png' }],
    ['link', { rel: 'stylesheet', href: 'https://fonts.googleapis.com/css?family=Roboto+Mono|Roboto:400,500,700' }]
  ],
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
