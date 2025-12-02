<template>
  <div class="max-w-2xl mx-auto text-center">
    <!-- Success Message -->
    <div class="bg-green-50 border border-green-200 rounded-lg p-8 mb-8">
      <div class="text-6xl mb-4">✅</div>
      <h1 class="text-3xl font-bold text-green-900 mb-4">Order Confirmed!</h1>
      <p class="text-green-700 mb-4">
        Thank you for your order. We've sent a confirmation email to <strong>{{ order?.customer_email }}</strong>
      </p>
      <div class="bg-white rounded-lg p-4 inline-block">
        <p class="text-sm text-gray-600">Order Number</p>
        <p class="text-2xl font-bold text-gray-900">#{{ order?.id }}</p>
      </div>
    </div>

    <!-- Order Details -->
    <div v-if="order" class="bg-white rounded-lg shadow p-6 text-left mb-8">
      <h2 class="text-xl font-semibold text-gray-900 mb-4">Order Summary</h2>

      <div class="space-y-3 mb-4">
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">Order Date:</span>
          <span class="font-medium">{{ formatDate(order.created_at) }}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">Email:</span>
          <span class="font-medium">{{ order.customer_email }}</span>
        </div>
        <div class="flex justify-between text-sm">
          <span class="text-gray-600">Status:</span>
          <span class="font-medium capitalize text-green-600">{{ order.status }}</span>
        </div>
      </div>

      <div class="border-t pt-4">
        <h3 class="font-semibold text-gray-900 mb-3">Items Ordered:</h3>
        <div class="space-y-2">
          <div
            v-for="item in order.order_items"
            :key="item.id"
            class="flex justify-between items-center py-2"
          >
            <div class="flex items-center space-x-3">
              <div class="w-12 h-12 flex-shrink-0 bg-gray-100 rounded overflow-hidden">
                <img
                  :src="item.product_image || 'https://picsum.photos/400/400?blur=2'"
                  :alt="item.product_name"
                  class="w-full h-full object-contain"
                  @error="handleImageError"
                />
              </div>
              <div>
                <p class="font-medium text-gray-900">{{ item.product_name }}</p>
                <p class="text-sm text-gray-600">Qty: {{ item.quantity }}</p>
              </div>
            </div>
            <div class="text-right">
              <p class="font-semibold text-gray-900">
                ${{ (item.unit_price * item.quantity).toFixed(2) }}
              </p>
              <p class="text-sm text-gray-600">${{ item.unit_price.toFixed(2) }} each</p>
            </div>
          </div>
        </div>

        <div class="border-t pt-4 mt-4">
          <div class="flex justify-between items-center text-xl font-bold text-gray-900">
            <span>Total:</span>
            <span>${{ order.total_amount.toFixed(2) }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- Actions -->
    <div class="flex gap-4 justify-center">
      <router-link to="/" class="btn-primary">
        Continue Shopping
      </router-link>

      <router-link to="/cart" class="btn-secondary">
        View Cart
      </router-link>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="text-center py-16">
      <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
      <p class="text-gray-600">Loading order details...</p>
    </div>

    <!-- Error State -->
    <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg p-8">
      <div class="text-6xl mb-4">❌</div>
      <h1 class="text-2xl font-bold text-red-900 mb-4">Order Not Found</h1>
      <p class="text-red-700 mb-6">
        We couldn't find the order details. Please check your email for the confirmation.
      </p>
      <router-link to="/" class="btn-primary">
        Go Home
      </router-link>
    </div>
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { orderService } from '../services/api'

export default {
  name: 'OrderConfirmation',
  props: {
    orderId: {
      type: [String, Number],
      required: true
    }
  },
  setup(props) {
    const route = useRoute()
    const order = ref(null)
    const loading = ref(true)
    const error = ref(false)

    const loadOrder = async () => {
      try {
        loading.value = true
        const response = await orderService.getOrder(props.orderId)
        order.value = response.data
      } catch (err) {
        error.value = true
      } finally {
        loading.value = false
      }
    }

    const formatDate = (dateString) => {
      return new Date(dateString).toLocaleDateString('en-US', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }

    const handleImageError = (event) => {
      event.target.src = 'https://picsum.photos/400/400?blur=2'
    }

    onMounted(() => {
      loadOrder()
    })

    return {
      order,
      loading,
      error,
      formatDate,
      handleImageError
    }
  }
}
</script>
