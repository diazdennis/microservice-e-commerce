<template>
  <header class="bg-white shadow-sm border-b sticky top-0 z-50">
    <div class="container mx-auto px-4 py-4">
      <div class="flex justify-between items-center">
        <router-link to="/" class="text-2xl font-bold text-gray-800 hover:text-blue-600 transition-colors">
          E-Commerce Store
        </router-link>

        <nav class="flex items-center space-x-6">
          <router-link
            to="/"
            class="text-gray-600 hover:text-gray-900 transition-colors"
            :class="{ 'text-blue-600 font-medium': $route.name === 'ProductList' }"
          >
            Products
          </router-link>

          <router-link
            to="/cart"
            class="text-gray-600 hover:text-gray-900 transition-colors flex items-center"
            :class="{ 'text-blue-600 font-medium': $route.name === 'Cart' }"
          >
            <span class="relative mr-1">
              <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
                <!-- Shopping Cart Basket -->
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z"></path>
              </svg>
              <span
                v-if="cartItemCount > 0"
                class="absolute -top-2 -right-2 bg-blue-600 text-white text-xs rounded-full h-5 w-5 flex items-center justify-center font-semibold"
              >
                {{ cartItemCount }}
              </span>
            </span>
            Cart
          </router-link>
        </nav>
      </div>
    </div>
  </header>
</template>

<script>
import { useCartStore } from '../stores/cart'
import { computed } from 'vue'

export default {
  name: 'Header',
  setup() {
    const cartStore = useCartStore()

    const cartItemCount = computed(() => {
      return cartStore.items.reduce((total, item) => total + item.quantity, 0)
    })

    return {
      cartItemCount
    }
  }
}
</script>
