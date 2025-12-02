<template>
  <div v-if="totalPages > 1" class="flex justify-center">
    <div class="flex items-center space-x-2">
      <!-- Previous Button -->
      <button
        @click="$emit('page-change', currentPage - 1)"
        :disabled="!hasPrev"
        class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Previous
      </button>

      <!-- Page Numbers -->
      <template v-for="page in visiblePages" :key="page">
        <button
          v-if="page !== '...'"
          @click="$emit('page-change', page)"
          :class="[
            'px-3 py-2 text-sm font-medium border rounded-md',
            page === currentPage
              ? 'bg-blue-600 text-white border-blue-600'
              : 'text-gray-500 bg-white border-gray-300 hover:bg-gray-50'
          ]"
        >
          {{ page }}
        </button>
        <span v-else class="px-2 py-2 text-gray-500">...</span>
      </template>

      <!-- Next Button -->
      <button
        @click="$emit('page-change', currentPage + 1)"
        :disabled="!hasNext"
        class="px-3 py-2 text-sm font-medium text-gray-500 bg-white border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        Next
      </button>
    </div>
  </div>
</template>

<script>
import { computed } from 'vue'

export default {
  name: 'Pagination',
  props: {
    currentPage: {
      type: Number,
      required: true
    },
    totalPages: {
      type: Number,
      required: true
    },
    hasNext: {
      type: Boolean,
      default: false
    },
    hasPrev: {
      type: Boolean,
      default: false
    }
  },
  emits: ['page-change'],
  setup(props) {
    const visiblePages = computed(() => {
      const current = props.currentPage
      const total = props.totalPages
      const pages = []

      if (total <= 7) {
        for (let i = 1; i <= total; i++) {
          pages.push(i)
        }
      } else {
        pages.push(1)

        if (current > 4) {
          pages.push('...')
        }

        const start = Math.max(2, current - 1)
        const end = Math.min(total - 1, current + 1)

        for (let i = start; i <= end; i++) {
          pages.push(i)
        }

        if (current < total - 3) {
          pages.push('...')
        }

        if (total > 1) {
          pages.push(total)
        }
      }

      return pages
    })

    return {
      visiblePages
    }
  }
}
</script>

