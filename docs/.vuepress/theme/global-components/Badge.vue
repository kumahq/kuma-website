<script>
export default {
  functional: true,
  props: {
    type: {
      type: String,
      default: 'tip'
    },
    text: String,
    vertical: {
      type: String,
      default: 'top'
    }
  },
  render (h, { props, slots }) {
    return h('span', {
      class: ['badge', props.type],
      style: {
        verticalAlign: props.vertical
      }
    }, props.text || slots().default)
  }
}
</script>

<style lang="scss" scoped>
$default: #42b983;
$warning: #ffe564;
$danger: #DA5961;

.badge { 
  display: inline-block;
  font-size: 14px;
  height: 18px;
  line-height: 18px;
  border-radius: 3px;
  padding: 0 6px;
  color: white;
  background-color: $default;

  &.tip, &.green {
    background-color: $default;
  }

  &.error {
    background-color: $danger;
  }

  &.warning, &.warn, &.yellow {
    background-color: darken($warning, 35%);
  }

  & + & {
    margin-left: 5px;
  }
}
</style>
