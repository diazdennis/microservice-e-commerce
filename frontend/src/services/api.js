import axios from 'axios'

// API base URLs - use relative paths for production (nginx will proxy)
// For local development, set VITE_CATALOG_API and VITE_CHECKOUT_API in .env
const CATALOG_API = import.meta.env.VITE_CATALOG_API || '/api'
const CHECKOUT_API = import.meta.env.VITE_CHECKOUT_API || '/api'

// Create axios instances
const catalogApi = axios.create({
  baseURL: CATALOG_API,
  timeout: 10000,
})

const checkoutApi = axios.create({
  baseURL: CHECKOUT_API,
  timeout: 30000, // Increased timeout for order creation (email sending may take time)
})

// Add response interceptor for error handling
const addResponseInterceptor = (instance) => {
  instance.interceptors.response.use(
    (response) => response,
    (error) => {
      return Promise.reject(error)
    }
  )
}

addResponseInterceptor(catalogApi)
addResponseInterceptor(checkoutApi)

// Product services
export const productService = {
  // Get products with filtering and pagination
  async getProducts(params = {}) {
    const response = await catalogApi.get('/products', { params })
    return response.data
  },

  // Get single product
  async getProduct(id) {
    const response = await catalogApi.get(`/products/${id}`)
    return response.data
  },

  // Get categories
  async getCategories() {
    const response = await catalogApi.get('/categories')
    return response.data
  }
}

// Order services
export const orderService = {
  // Create new order
  async createOrder(orderData) {
    const response = await checkoutApi.post('/orders', orderData)
    return response.data
  },

  // Get order details
  async getOrder(orderId) {
    const response = await checkoutApi.get(`/orders/${orderId}`)
    return response.data
  }
}

export default {
  productService,
  orderService
}
