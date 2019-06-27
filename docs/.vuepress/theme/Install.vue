<template>
  <div class="theme-container theme-container--install">
    <Navbar/>
    <InstallMethods :items="installMethodItems"/>
    <Footer/>
  </div>
</template>

<script>
import Navbar from "@vuepress/theme-default/components/Navbar";
import Footer from "./components/Footer";
import InstallMethods from "./components/InstallMethods";

export default {
  components: {
    Navbar,
    Footer,
    InstallMethods
  }
};
</script>

