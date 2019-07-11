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
import Navbar from './components/Navbar'
import Footer from './components/custom/Footer'
import InstallMethods from './components/custom/InstallMethods'
import VersionNav from './components/custom/VersionNav'

export default {
  components: {
    Navbar,
    Footer,
    InstallMethods,
    VersionNav
  }
};
</script>

