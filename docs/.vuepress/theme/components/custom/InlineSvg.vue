<template>
  <div
    class="inline-svg"
    :style="svgStyles"
  ></div>
</template>

<script>
let cache = new Map()

export default {
  name: 'InlineSvg',
  props: {
    src: {
      type: String,
      required: true
    },
    width: String,
    height: String
  },
  async mounted() {
    if ( !cache.has(this.src) ) {
      try {
        cache.set(this.src, fetch(this.src).then(r => r.text()))
      } 
      catch (e) {
        cache.delete(this.src)
      }
    }
    
    if ( cache.has(this.src) ) {
      this.$el.innerHTML = await cache.get(this.src)
    }
  },
  computed: {
    svgStyles() {
      return {
        height: `${this.height}px`,
        width: `${this.width}px`
      }
    }
  }
}
</script>

<style lang="scss">
.inline-svg {
  display: block;
  position: relative;

  > svg {
    width: 100% !important;
    height: auto !important;
    display: block;
    position: absolute;
    top: 0;
    left: 0;
  }
}
</style>


