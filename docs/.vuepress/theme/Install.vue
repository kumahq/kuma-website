<template>
  <div class="theme-container theme-container--install">
    <Navbar/>

    <!-- TODO wire the installation methods up with actual URL paths -->
    <!-- TODO version switching mechanism for installation instructions -->
    <InstallMethods :items="installMethodItems"/>

    <div>
      <h1>Items</h1>
      <ul v-for="item in getVersionDirs">
        <li>{{item}}</li>
      </ul>
    </div>

    <div>
      {{testVersionRegEx}}
    </div>

    <Footer/>
  </div>
</template>

<script>
import Navbar from '@vuepress/theme-default/components/Navbar'
import Footer from './components/Footer'
import InstallMethods from './components/InstallMethods'

export default {
  components: {
    Navbar,
    Footer,
    InstallMethods
  }
};
</script>

