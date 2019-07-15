<template>
  <div v-if="items && items.length" class="install-methods-wrapper">
    <ul class="install-methods">
      <li v-for="item in items" class="install-methods__item">
        <a :href="item.url">
          <img :src="item.logo" class="install-methods__item-logo">
          <h3 class="install-methods__item-title">{{item.label}}</h3>
        </a>
      </li>
    </ul>
  </div>
  <div v-else class="install-methods-wrapper">
    <p><strong>No install methods defined!</strong></p>
  </div>
</template>

<script>
export default {
  props: {
    items: []
  }
};
</script>
