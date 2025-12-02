<template>
  <div class="max-w-4xl mx-auto">
    <h1 class="text-3xl font-bold text-gray-900 mb-8">Shopping Cart</h1>

    <!-- Empty Cart -->
    <div v-if="cartStore.totalItems === 0" class="text-center py-16">
      <div class="text-6xl mb-4">🛒</div>
      <h2 class="text-2xl font-semibold text-gray-900 mb-4">Your cart is empty</h2>
      <p class="text-gray-600 mb-8">Looks like you haven't added anything yet.</p>
      <router-link to="/" class="btn-primary">
        Browse Products
      </router-link>
    </div>

    <!-- Cart Items -->
    <div v-else class="space-y-6">
      <div class="bg-white rounded-lg shadow overflow-hidden">
        <div class="divide-y divide-gray-200">
          <div
            v-for="item in cartStore.items"
            :key="item.id"
            class="p-6 flex items-center space-x-4"
          >
            <div class="w-20 h-20 flex-shrink-0 bg-gray-100 rounded-md overflow-hidden">
              <img
                :src="item.image_url"
                :alt="item.name"
                class="w-full h-full object-contain"
                @error="handleImageError"
              />
            </div>

            <div class="flex-1">
              <h3 class="text-lg font-semibold text-gray-900">{{ item.name }}</h3>
              <p class="text-gray-600">${{ parseFloat(item.price).toFixed(2) }} each</p>
            </div>

            <div class="flex items-center space-x-3">
              <button
                @click="updateQuantity(item.id, item.quantity - 1)"
                class="w-8 h-8 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center text-gray-600"
              >
                -
              </button>

              <span class="w-12 text-center font-medium">{{ item.quantity }}</span>

              <button
                @click="updateQuantity(item.id, item.quantity + 1)"
                class="w-8 h-8 rounded-full bg-gray-200 hover:bg-gray-300 flex items-center justify-center text-gray-600"
              >
                +
              </button>
            </div>

            <div class="text-right">
              <p class="text-lg font-semibold text-gray-900">
                ${{ (parseFloat(item.price) * item.quantity).toFixed(2) }}
              </p>
            </div>

            <button
              @click="removeItem(item.id)"
              class="text-red-600 hover:text-red-800 p-2"
            >
              <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"></path>
              </svg>
            </button>
          </div>
        </div>
      </div>

      <!-- Cart Summary -->
      <div class="bg-white rounded-lg shadow p-6">
        <div class="flex justify-between items-center mb-4">
          <span class="text-lg font-medium text-gray-900">Total Items:</span>
          <span class="text-lg font-semibold">{{ cartStore.totalItems }}</span>
        </div>

        <div class="flex justify-between items-center text-xl font-bold text-gray-900 border-t pt-4">
          <span>Total:</span>
          <span>${{ cartStore.totalPrice.toFixed(2) }}</span>
        </div>

        <div class="mt-6 flex gap-4">
          <router-link to="/" class="flex-1 btn-secondary text-center">
            Continue Shopping
          </router-link>

          <router-link to="/checkout" class="flex-1 btn-primary text-center">
            Proceed to Checkout
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { useCartStore } from '../stores/cart'

export default {
  name: 'Cart',
  setup() {
    const cartStore = useCartStore()

    const updateQuantity = (productId, newQuantity) => {
      cartStore.updateQuantity(productId, newQuantity)
    }

    const removeItem = (productId) => {
      cartStore.removeItem(productId)
    }

    const handleImageError = (event) => {
      event.target.src = 'https://picsum.photos/400/400?blur=2'
    }

    return {
      cartStore,
      updateQuantity,
      removeItem,
      handleImageError
    }
  }
}
</script>
