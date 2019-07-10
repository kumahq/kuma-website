<template>
  <div class="theme-container theme-container--install">
    <Navbar/>

    <!-- TODO wire the installation methods up with actual URL paths -->
    <!-- TODO version switching mechanism for installation instructions -->
    <InstallMethods :items="installMethodItems"/>

    <VersionNav/>

    <Footer/>
  </div>
</template>

<script>
import Navbar from '../default-theme/components/Navbar'
import Footer from './components/Footer'
import InstallMethods from './components/InstallMethods'
import VersionNav from './components/VersionNav'

export default {
  components: {
    Navbar,
    Footer,
    InstallMethods,
    VersionNav
  }
};
</script>

