<template>
  <ul v-if="items" class="install-methods">
    <li v-for="item in items" class="install-methods__item">
      <a :href="item.url">
        <img :src="item.logo" class="install-methods__item-logo">
        <h3 class="install-methods__item-title">{{item.label}}</h3>
      </a>
    </li>
  </ul>
</template>

<script>
export default {
  props: {
    items: []
  }
};
</script>
