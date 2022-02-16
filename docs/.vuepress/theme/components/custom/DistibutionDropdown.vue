<template>
  <div
    class="btn btn--bright btn--large dropdown"
    @mouseover="showList"
    @mouseleave="hideList"
    @click="handleAnimation"
  >
    {{ $page.frontmatter.startText }}

    <span class="ml-2">
      <svg
        :class="['distibution-icon', {
        rotated: isListOpen
      }]"
        width="18"
        height="14"
        xmlns="http://www.w3.org/2000/svg"
        version="1.1"
      >
        <polyline
          points="4,1 10,7 4,13"
          stroke="#fff"
          stroke-width="2"
          stroke-linecap="butt"
          fill="none"
          stroke-linejoin="miter"
        />
      </svg>
    </span>

    <ul
      :class="['options-list', {'shake': hasAnimationClass}]"
      v-show="isListOpen"
    >
      <li>
        <router-link :to="$page.frontmatter.enterpriseUrl">
          Enterprise
          <span class="ml-2">
            <svg
              width="18"
              height="14"
              xmlns="http://www.w3.org/2000/svg"
              version="1.1"
            >
              <polyline
                points="4,1 10,7 4,13"
                stroke="#000"
                stroke-width="2"
                stroke-linecap="butt"
                fill="none"
                stroke-linejoin="miter"
              />
            </svg>
          </span>
        </router-link>
      </li>
      <li>
        <router-link :to="$page.frontmatter.OOSUrl">
          OSS
          <span class="ml-2">
            <svg
              width="18"
              height="14"
              xmlns="http://www.w3.org/2000/svg"
              version="1.1"
            >
              <polyline
                points="4,1 10,7 4,13"
                stroke="#000"
                stroke-width="2"
                stroke-linecap="butt"
                fill="none"
                stroke-linejoin="miter"
              />
            </svg>

          </span>
        </router-link>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: "DistibutionDropdown",
  data() {
    return {
      isListOpen: false,
      hasAnimationClass: false,
      shakeTimeout: null,
    };
  },

  methods: {
    showList() {
      this.isListOpen = true;
    },
    hideList() {
      this.isListOpen = false;
      this.hasAnimationClass = false;

      clearTimeout(this.shakeTimeout);
    },
    handleAnimation() {
      clearTimeout(this.shakeTimeout);
      this.hasAnimationClass = true;

      this.shakeTimeout = setTimeout(() => {
        this.hasAnimationClass = false;
      }, 1001);
    },
  },
  beforeDestroy() {
    clearTimeout(this.shakeTimeout);
  },
};
</script>

<style lang="scss" scoped>
@import "../../../theme/styles/custom/config/_variables.scss";

.dropdown {
  margin-right: 16px;
  position: relative;
  z-index: 5;

  @media (max-width: $MQMobileNarrow) {
    margin-right: 0px;
    margin-bottom: 16px;
  }
}

@keyframes shake {
  10%,
  90% {
    transform: translate3d(-1px, 0, 0);
  }

  20%,
  80% {
    transform: translate3d(2px, 0, 0);
  }

  30%,
  50%,
  70% {
    transform: translate3d(-4px, 0, 0);
  }

  40%,
  60% {
    transform: translate3d(4px, 0, 0);
  }
}

.options-list {
  position: absolute;
  border: 1px solid #777;
  box-shadow: 3px 3px 5px 0px rgba(0, 0, 0, 0.29);
  border-top: 0;
  border-bottom-left-radius: 8px;
  border-bottom-right-radius: 8px;
  width: 75%;
  top: 100%;
  left: 0;
  right: 0;
  margin: 0 auto;

  background: white;
  padding: 10px 0;
  list-style: none;

  li {
    a {
      text-align: right;
      background: white;
      display: block;
      padding: 10px 12px;
      font-size: 16px;
      color: #000;
      &:hover {
        background-color: $color-7;
      }
    }
    svg {
      position: relative;
      top: 2px;
    }
  }

  &.shake {
    animation: shake 1s cubic-bezier(0.36, 0.07, 0.19, 0.97) both;
    transform: translate3d(0, 0, 0);
    backface-visibility: hidden;
    perspective: 1000px;
  }
}

.distibution-icon {
  transition: all 200ms;
  position: relative;
  top: 2px;

  &.rotated {
    transform: rotate(90deg);
  }
}
</style>