<template>
  <div class="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300">
    <div class="aspect-w-1 aspect-h-1">
      <img
        :src="product.image_url"
        :alt="product.name"
        class="w-full h-48 object-cover"
        @error="handleImageError"
      />
    </div>

    <div class="p-4">
      <h3 class="text-lg font-semibold text-gray-900 mb-2 line-clamp-2">
        {{ product.name }}
      </h3>

      <p class="text-gray-600 text-sm mb-3 line-clamp-2">
        {{ product.description }}
      </p>

      <div class="flex justify-between items-center mb-3">
        <span class="text-2xl font-bold text-gray-900">
          ${{ parseFloat(product.price).toFixed(2) }}
        </span>

        <span class="text-sm text-gray-500">
          {{ product.stock }} in stock
        </span>
      </div>

      <div class="flex gap-2">
        <router-link
          :to="`/products/${product.id}`"
          class="flex-1 btn-secondary text-center text-sm"
        >
          View Details
        </router-link>

        <button
          @click="addToCart"
          :disabled="product.stock === 0"
          class="flex-1 btn-primary text-sm disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ product.stock === 0 ? 'Out of Stock' : 'Add to Cart' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { useCartStore } from '../stores/cart'

export default {
  name: 'ProductCard',
  props: {
    product: {
      type: Object,
      required: true
    }
  },
  emits: ['added-to-cart'],
  setup(props, { emit }) {
    const cartStore = useCartStore()

    const addToCart = () => {
      cartStore.addItem(props.product)
      emit('added-to-cart', props.product)
    }

    const handleImageError = (event) => {
      // Fallback to a placeholder image if the original fails to load
      event.target.src = 'https://picsum.photos/400/400?blur=2'
    }

    return {
      addToCart,
      handleImageError
    }
  }
}
</script>

<style scoped>
.line-clamp-2 {
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}
</style>
