<template>
    <div :id="id">
        <slot></slot>
    </div>
</template>

<script>
import tinytabs from './tinytabs'

export default {
    name: 'VueTinyTabs',
    components: {
      tinytabs
    },
    props: {
        id: {
            type: String,
            required: true
        },
        anchor: {
            type: Boolean,
            default: false,
            required: false
        },
        closable: {
            type: Boolean,
            default: false,
            required: false
        },
        hideTitle: {
            type: Boolean,
            default: false,
            required: false
        },
        sectionClass: {
            type: String,
            default: 'section',
            required: false
        },
        titleClass: {
            type: String,
            default: 'title',
            required: false
        },
        tabsClass: {
            type: String,
            default: 'tabs',
            required: false
        },
        tabClass: {
            type: String,
            default: 'tab',
            required: false
        }
    },
    mounted() {
        let self = this
        tinytabs(document.querySelector("#"+this.id), {
            anchor: this.anchor,
            hideTitle: this.hideTitle,
            closable: this.closable,
            sectionClass: this.sectionClass,
            titleClass: this.titleClass,
            tabsClass: this.tabsClass,
            tabClass: this.tabClass,
            onClose: function (id) {
                self.handleClose(id)
            },
            onBefore: function (id, tab) {
                self.handleOnBefore(id, tab)
            },
            onAfter: function (id, tab) {
                self.handleOnAfter(id, tab)
            }
		})
	},
    methods: {
        handleClose(id) {
            this.$emit('on-close', id)
        },
        handleOnBefore(id, tab) {
            this.$emit('on-before', id, tab)
        },
        handleOnAfter(id, tab) {
            this.$emit('on-after', id, tab)
        }
    },
}
</script>
