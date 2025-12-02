<template>
  <div class="max-w-2xl mx-auto">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">Checkout</h1>

    <!-- Order Summary -->
    <div class="bg-white rounded-lg shadow p-6 mb-6">
      <h2 class="text-xl font-semibold text-gray-900 mb-4">Order Summary</h2>

      <div class="space-y-3 mb-4">
        <div
          v-for="item in cartStore.items"
          :key="item.id"
          class="flex justify-between items-center"
        >
          <div class="flex items-center space-x-3">
            <div class="w-12 h-12 flex-shrink-0 bg-gray-100 rounded overflow-hidden">
              <img
                :src="item.image_url"
                :alt="item.name"
                class="w-full h-full object-contain"
                @error="handleImageError"
              />
            </div>
            <div>
              <p class="font-medium text-gray-900">{{ item.name }}</p>
              <p class="text-sm text-gray-600">Qty: {{ item.quantity }}</p>
            </div>
          </div>
          <p class="font-semibold text-gray-900">
            ${{ (parseFloat(item.price) * item.quantity).toFixed(2) }}
          </p>
        </div>
      </div>

      <div class="border-t pt-4">
        <div class="flex justify-between items-center text-xl font-bold text-gray-900">
          <span>Total:</span>
          <span>${{ cartStore.totalPrice.toFixed(2) }}</span>
        </div>
      </div>
    </div>

    <!-- Checkout Form -->
    <div class="bg-white rounded-lg shadow p-6">
      <h2 class="text-xl font-semibold text-gray-900 mb-4">Contact Information</h2>

      <form @submit.prevent="placeOrder" class="space-y-4">
        <div>
          <label for="email" class="block text-sm font-medium text-gray-700 mb-1">
            Email Address *
          </label>
          <input
            id="email"
            v-model="form.email"
            type="email"
            required
            placeholder="your@email.com"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
          <p class="text-sm text-gray-600 mt-1">
            We'll send your order confirmation to this email
          </p>
        </div>

        <div class="bg-blue-50 border border-blue-200 rounded-md p-4">
          <div class="flex">
            <div class="flex-shrink-0">
              <svg class="h-5 w-5 text-blue-400" viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clip-rule="evenodd" />
              </svg>
            </div>
            <div class="ml-3">
              <h3 class="text-sm font-medium text-blue-800">
                Guest Checkout
              </h3>
              <div class="mt-2 text-sm text-blue-700">
                <p>
                  No account required! We'll send your order confirmation to your email.
                  Your cart data is stored locally in your browser.
                </p>
              </div>
            </div>
          </div>
        </div>

        <div class="flex gap-4 pt-4">
          <router-link to="/cart" class="flex-1 btn-secondary text-center">
            Back to Cart
          </router-link>

          <button
            type="submit"
            :disabled="loading || cartStore.totalItems === 0"
            class="flex-1 btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <span v-if="loading" class="flex items-center justify-center">
              <LoadingSpinner size="md" color="white" class="-ml-1 mr-3" />
              Processing...
            </span>
            <span v-else>
              Place Order - ${{ cartStore.totalPrice.toFixed(2) }}
            </span>
          </button>
        </div>
      </form>
    </div>

    <!-- Error Message -->
    <div v-if="error" class="mt-6 bg-red-50 border border-red-200 rounded-md p-4">
      <div class="flex">
        <div class="flex-shrink-0">
          <svg class="h-5 w-5 text-red-400" viewBox="0 0 20 20" fill="currentColor">
            <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="ml-3">
          <h3 class="text-sm font-medium text-red-800">
            Order Failed
          </h3>
          <div class="mt-2 text-sm text-red-700">
            <p>{{ error }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useCartStore } from '../stores/cart'
import { orderService } from '../services/api'
import LoadingSpinner from '../components/LoadingSpinner.vue'

export default {
  name: 'Checkout',
  components: {
    LoadingSpinner
  },
  setup() {
    const router = useRouter()
    const cartStore = useCartStore()

    const form = ref({
      email: ''
    })

    const loading = ref(false)
    const error = ref('')

    const placeOrder = async () => {
      if (cartStore.totalItems === 0) {
        error.value = 'Your cart is empty'
        return
      }

      loading.value = true
      error.value = ''

      try {
        // Prepare order data
        const orderData = {
          email: form.value.email,
          items: cartStore.items.map(item => ({
            product_id: item.id,
            quantity: item.quantity
          }))
        }

        // Place the order
        const response = await orderService.createOrder(orderData)

        // Check if response is successful
        if (!response || !response.success) {
          throw new Error(response?.message || 'Order creation failed')
        }

        // Check if order_id exists in response
        const orderId = response.data?.order_id || response.data?.id
        if (!orderId) {
          throw new Error('Order created but order ID not found in response')
        }

        // Clear cart on success
        cartStore.clearCart()

        // Redirect to confirmation page
        router.push({
          name: 'OrderConfirmation',
          params: { orderId: orderId }
        })

      } catch (err) {

        if (err.response?.data?.error) {
          error.value = err.response.data.error.message || 'Failed to place order'
        } else if (err.message) {
          error.value = err.message
        } else {
          error.value = 'An unexpected error occurred. Please try again.'
        }
      } finally {
        loading.value = false
      }
    }

    const handleImageError = (event) => {
      event.target.src = 'https://picsum.photos/400/400?blur=2'
    }

    return {
      cartStore,
      form,
      loading,
      error,
      placeOrder,
      handleImageError
    }
  }
}
</script>
