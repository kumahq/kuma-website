// const glob = require('glob')
const installLogoPath = '/platforms';

module.exports = {
  title: 'Konvoy',
  description: 'Connect, Secure and Observe any traffic and Microservices',
  host: 'localhost',
  themeConfig: {
    repo: 'kong/konvoy',
    logo: '/konvoy-logo.svg',
    footer: 'Konvoy by Kong',
    docsDir: 'vuepress',
    editLinks: true,
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
          '/master/getting-started/quickstart'
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
          '/master/documentation/api-reference'
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
          '/master/tutorials/segmenting-traffic'
        ]
      }
    ],
    nav: [
      { text: 'Documentation', link: '/documentation' },
      { text: 'Use Cases', link: '/use-cases' },
      { text: 'Enterprise', link: '/enterprise' },
      { text: 'Install', link: '/install' }
    ],
    installMethods: [
      {
        label: 'Docker',
        logo: `${installLogoPath}/logo-docker.png`,
        url: '#'
      },
      {
        label: 'Kubernetes',
        logo: `${installLogoPath}/logo-kubernetes.png`,
        url: '#'
      },
      {
        label: 'DC/OS',
        logo: `${installLogoPath}/logo-mesosphere.png`,
        url: '#'
      },
      {
        label: 'Amazon Linux',
        logo: `${installLogoPath}/logo-amazon-linux.png`,
        url: '#'
      },
      {
        label: 'CentOS',
        logo: `${installLogoPath}/logo-centos.gif`,
        url: '#'
      },
      {
        label: 'RedHat',
        logo: `${installLogoPath}/logo-redhat.jpg`,
        url: '#'
      },
      {
        label: 'Debian',
        logo: `${installLogoPath}/logo-debian.jpg`,
        url: '#'
      },
      {
        label: 'Ubuntu',
        logo: `${installLogoPath}/logo-ubuntu.png`,
        url: '#'
      },
      {
        label: 'macOS',
        logo: `${installLogoPath}/logo-macos.png`,
        url: '#'
      },
      {
        label: 'AWS Marketplace',
        logo: `${installLogoPath}/logo-awscart.jpg`,
        url: '#'
      },
      {
        label: 'AWS Cloud Formation',
        logo: `${installLogoPath}/logo-awscloudform.png`,
        url: '#'
      },
      {
        label: 'Google Cloud Platform',
        logo: `${installLogoPath}/logo-googlecp.png`,
        url: '#'
      },
      {
        label: 'Vagrant',
        logo: `${installLogoPath}/logo-vagrant.png`,
        url: '#'
      },
      {
        label: 'Source',
        logo: `${installLogoPath}/logo-source.svg`,
        url: '#'
      }
    ]
  },
  head: [
    [
      'link',
      {
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
    plugins: [require('tailwindcss'), require('autoprefixer')]
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
