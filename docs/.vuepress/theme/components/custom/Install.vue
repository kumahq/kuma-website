<template>
  <div class="theme-container theme-container--install">

    <header class="page-header">
      <h1>Install {{$site.title}}</h1>
      <div v-if="items.length" class="version-selector-wrapper">
        <form>
          <select name="version-selector" id="version-selector" @change="updateInstallPath($event)">
            <option v-for="tag in tags" :value="tag.version" :key="tag.version">
              {{tag.text}}
            </option>
          </select>
        </form>
        <p>You are viewing installation instructions for <strong>{{pathVersion == 'master' ? 'the latest version' : pathVersion}}</strong>.</p>
      </div>
    </header>

    <div v-if="items && items.length" class="install-methods-wrapper">
      <ul class="install-methods">
        <li v-for="item in items" class="install-methods__item">
          <router-link :to='`/${pathVersion}/installation-guide.html#${item.slug}`'>
            <img :src="item.logo" class="install-methods__item-logo">
            <h3 class="install-methods__item-title">{{item.label}}</h3>
          </router-link>
        </li>
      </ul>
    </div>
    <div v-else class="install-methods-wrapper">
      <p><strong>No install methods defined!</strong></p>
    </div>
    
  </div>
</template>

<script>
import Axios from 'axios'
import Navbar from '@theme/components/Navbar'
import Footer from '@theme/components/custom/Footer'

export default {
  data() {
    return {
      tags: Array,
      pathVersion: 'master',
      pathSegment: '#installation',
      helperText: '',
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
    Footer
  },
  methods: {
    updateInstallPath: function(ev) {
      this.pathVersion = ev.target.value
    }
  },
  mounted() {
    Axios
      .get('/releases.json')
      .then( response => {
        // setup the version array
        this.tags = response.data.tags.map( tag => ({
          text: (tag.latest === true) ? `${tag.version} (latest)` : tag.version,
          version: (tag.latest === true) ? tag.label : tag.version,
          latest: (tag.latest === true) ? true : false
        }))
      })
  }
};
</script>

<style lang="scss" scoped>
.page-header {
  text-align: center;
}

// temp styles grabbed from here https://www.filamentgroup.com/lab/select-css.html
select {
	// display: block;
	font-size: 16px;
	font-family: sans-serif;
	font-weight: 700;
	color: #444;
	line-height: 1.3;
	padding: .6em 1.4em .5em .8em;
	// width: 100%;
	max-width: 100%;
	box-sizing: border-box;
	margin: 0;
	border: 1px solid #aaa;
	box-shadow: 0 1px 0 1px rgba(0,0,0,.04);
	border-radius: .5em;
	-moz-appearance: none;
	-webkit-appearance: none;
	appearance: none;
	background-color: #fff;
	background-image: url('data:image/svg+xml;charset=US-ASCII,%3Csvg%20xmlns%3D%22http%3A%2F%2Fwww.w3.org%2F2000%2Fsvg%22%20width%3D%22292.4%22%20height%3D%22292.4%22%3E%3Cpath%20fill%3D%22%23007CB2%22%20d%3D%22M287%2069.4a17.6%2017.6%200%200%200-13-5.4H18.4c-5%200-9.3%201.8-12.9%205.4A17.6%2017.6%200%200%200%200%2082.2c0%205%201.8%209.3%205.4%2012.9l128%20127.9c3.6%203.6%207.8%205.4%2012.8%205.4s9.2-1.8%2012.8-5.4L287%2095c3.5-3.5%205.4-7.8%205.4-12.8%200-5-1.9-9.2-5.5-12.8z%22%2F%3E%3C%2Fsvg%3E'),
	  linear-gradient(to bottom, #ffffff 0%,#e5e5e5 100%);
	background-repeat: no-repeat, repeat;
	background-position: right .7em top 50%, 0 0;
	background-size: .65em auto, 100%;
}

select::-ms-expand {
	display: none;
}

select:hover {
	border-color: #888;
}

select:focus {
	border-color: #aaa;
	box-shadow: 0 0 1px 3px rgba(59, 153, 252, .7);
	box-shadow: 0 0 0 3px -moz-mac-focusring;
	color: #222;
	outline: none;
}

select option {
	font-weight:normal;
}
</style>
