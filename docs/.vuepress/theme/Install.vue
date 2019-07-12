<template>
  <div class="theme-container theme-container--install">
    <Navbar/>

    <h1>Install Konvoy</h1>
    <!--
      TODO
      instead of a navigation, this should be a version switcher.
      instead of going to a page, we want to switch out the version
      in the installation link URLs accordingly.
    -->
    <VersionNav/>

    <div v-if="items && items.length" class="install-methods-wrapper">
      <ul class="install-methods">
        <li v-for="item in items" class="install-methods__item">
          <a :href='`/${pathVersion}/installation-guide.html#${item.slug}`'>
            <img :src="item.logo" class="install-methods__item-logo">
            <h3 class="install-methods__item-title">{{item.label}}</h3>
          </a>
        </li>
      </ul>
    </div>
    <div v-else class="install-methods-wrapper">
      <p><strong>No install methods defined!</strong></p>
    </div>

    <Footer/>
  </div>
</template>

<script>
import Navbar from './components/Navbar'
import Footer from './components/custom/Footer'
import VersionNav from './components/custom/VersionNav'

export default {
  data() {
    return {
      pathVersion: 'master',
      pathSegment: '#installation',
      items: [
        {
          label: 'Docker',
          logo: '/platforms/logo-docker.png',
          slug: 'docker'
        },
        {
          label: 'Kubernetes',
          logo: '/platforms/logo-kubernetes.png',
          slug: 'kubernetes'
        },
        {
          label: 'DC/OS',
          logo: '/platforms/logo-mesosphere.png',
          slug: 'dc-os'
        },
        {
          label: 'Amazon Linux',
          logo: '/platforms/logo-amazon-linux.png',
          slug: 'amazon-linux'
        },
        {
          label: 'CentOS',
          logo: '/platforms/logo-centos.gif',
          slug: 'centos'
        },
        {
          label: 'RedHat',
          logo: '/platforms/logo-redhat.jpg',
          slug: 'redhat'
        },
        {
          label: 'Debian',
          logo: '/platforms/logo-debian.jpg',
          slug: 'debian'
        },
        {
          label: 'Ubuntu',
          logo: '/platforms/logo-ubuntu.png',
          slug: 'ubuntu'
        },
        {
          label: 'macOS',
          logo: '/platforms/logo-macos.png',
          slug: 'macos'
        },
        {
          label: 'AWS Marketplace',
          logo: '/platforms/logo-awscart.jpg',
          slug: 'aws-marketplace'
        },
        {
          label: 'AWS Cloud Formation',
          logo: '/platforms/logo-awscloudform.png',
          slug: 'aws-cloud-platform'
        },
        {
          label: 'Google Cloud Platform',
          logo: '/platforms/logo-googlecp.png',
          slug: 'google-cloud-platform'
        },
        {
          label: 'Vagrant',
          logo: '/platforms/logo-vagrant.png',
          slug: 'vagrant'
        },
        {
          label: 'Source',
          logo: '/platforms/logo-source.svg',
          slug: 'source'
        }
      ]
    }
  },
  components: {
    Navbar,
    Footer,
    VersionNav
  }
};
</script>