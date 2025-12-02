<template>
  <svg
    :class="[sizeClasses, colorClass, 'animate-spin']"
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
  >
    <circle
      class="opacity-25"
      cx="12"
      cy="12"
      r="10"
      stroke="currentColor"
      stroke-width="4"
    ></circle>
    <path
      class="opacity-75"
      fill="currentColor"
      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
    ></path>
  </svg>
</template>

<script>
import { computed } from 'vue'

export default {
  name: 'LoadingSpinner',
  props: {
    size: {
      type: String,
      default: 'md',
      validator: (value) => ['sm', 'md', 'lg', 'xl'].includes(value)
    },
    color: {
      type: String,
      default: 'white'
    }
  },
  setup(props) {
    const sizeClasses = computed(() => {
      const sizes = {
        sm: 'h-4 w-4',
        md: 'h-5 w-5',
        lg: 'h-8 w-8',
        xl: 'h-12 w-12'
      }
      return sizes[props.size] || sizes.md
    })

    const colorClass = computed(() => {
      const colors = {
        white: 'text-white',
        blue: 'text-blue-600',
        gray: 'text-gray-600',
        primary: 'text-blue-600'
      }
      return colors[props.color] || `text-${props.color}`
    })

    return {
      sizeClasses,
      colorClass
    }
  }
}
</script>

