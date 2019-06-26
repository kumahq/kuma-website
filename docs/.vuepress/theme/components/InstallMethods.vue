<template>
  <div v-if="items" class="install-methods">
    <div v-for="item in items" class="install-methods__item">
      <a :href="item.url">
        <img :src="item.logo">
      </a>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    items: Array
  }
};
</script>
