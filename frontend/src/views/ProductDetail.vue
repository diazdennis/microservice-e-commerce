<template>
  <div class="max-w-4xl mx-auto">
    <!-- Loading State -->
    <div v-if="loading" class="animate-pulse">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
        <div class="loading-skeleton h-96 rounded-lg"></div>
        <div class="space-y-4">
          <div class="loading-skeleton h-8 w-3/4"></div>
          <div class="loading-skeleton h-6 w-1/2"></div>
          <div class="loading-skeleton h-4 w-full"></div>
          <div class="loading-skeleton h-4 w-full"></div>
          <div class="loading-skeleton h-12 w-32"></div>
        </div>
      </div>
    </div>

    <!-- Product Detail -->
    <div v-else-if="product" class="grid grid-cols-1 md:grid-cols-2 gap-8">
      <!-- Product Image -->
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <img
          :src="product.image_url"
          :alt="product.name"
          class="w-full h-96 object-cover"
          @error="handleImageError"
        />
      </div>

      <!-- Product Info -->
      <div class="space-y-6">
        <div>
          <h1 class="text-3xl font-bold text-gray-900 mb-2">{{ product.name }}</h1>
          <p class="text-xl text-gray-600 mb-4">{{ product.category?.name }}</p>
          <p class="text-3xl font-bold text-gray-900 mb-4">${{ parseFloat(product.price).toFixed(2) }}</p>
          <p class="text-gray-600">{{ product.description }}</p>
        </div>

        <!-- Stock Info -->
        <div class="bg-gray-50 rounded-lg p-4">
          <div class="flex justify-between items-center">
            <span class="text-sm font-medium text-gray-700">Availability:</span>
            <span
              :class="[
                'text-sm font-semibold',
                stockNumber > 10 ? 'text-green-600' : stockNumber > 0 ? 'text-yellow-600' : 'text-red-600'
              ]"
            >
              {{ stockNumber > 10 ? 'In Stock' : stockNumber > 0 ? `Only ${stockNumber} left` : 'Out of Stock' }}
            </span>
          </div>
        </div>

        <!-- Add to Cart -->
        <div class="space-y-4">
          <button
            @click="addToCart"
            :disabled="stockNumber === 0"
            class="w-full btn-primary py-3 text-lg disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {{ stockNumber === 0 ? 'Out of Stock' : 'Add to Cart' }}
          </button>

          <router-link
            to="/"
            class="w-full btn-secondary py-3 text-center block"
          >
            Continue Shopping
          </router-link>
        </div>

        <!-- Added to Cart Message -->
        <div
          v-if="showAddedMessage"
          class="bg-green-50 border border-green-200 rounded-md p-4 transition-opacity duration-300"
        >
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <p class="text-sm font-medium text-green-800">
                Added to cart successfully!
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Error State -->
    <div v-else class="text-center py-16">
      <div class="text-6xl mb-4">❌</div>
      <h1 class="text-2xl font-bold text-gray-900 mb-4">Product Not Found</h1>
      <p class="text-gray-600 mb-8">The product you're looking for doesn't exist.</p>
      <router-link to="/" class="btn-primary">
        Browse Products
      </router-link>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useCartStore } from '../stores/cart'
import { productService } from '../services/api'

export default {
  name: 'ProductDetail',
  props: {
    id: {
      type: [String, Number],
      required: true
    }
  },
  setup(props) {
    const route = useRoute()
    const cartStore = useCartStore()

    const product = ref(null)
    const loading = ref(true)
    const showAddedMessage = ref(false)

    // Convert stock to number for safe comparison
    const stockNumber = computed(() => {
      if (!product.value || product.value.stock === undefined || product.value.stock === null) {
        return 0
      }
      return parseInt(product.value.stock) || 0
    })

    const loadProduct = async () => {
      try {
        loading.value = true
        // Get ID from props or route params
        const productId = props.id || route.params.id
        const response = await productService.getProduct(productId)
        if (response.success && response.data) {
          product.value = response.data
        } else {
          product.value = null
        }
      } catch (error) {
        product.value = null
      } finally {
        loading.value = false
      }
    }

    const addToCart = () => {
      if (product.value && stockNumber.value > 0) {
        cartStore.addItem(product.value)
        showAddedMessage.value = true

        // Hide message after 3 seconds
        setTimeout(() => {
          showAddedMessage.value = false
        }, 3000)
      }
    }

    const handleImageError = (event) => {
      event.target.src = 'https://picsum.photos/400/400?blur=2'
    }

    onMounted(() => {
      loadProduct()
    })

    return {
      product,
      loading,
      showAddedMessage,
      stockNumber,
      addToCart,
      handleImageError
    }
  }
}
</script>
