<template>
  <div class="space-y-6">
    <!-- Page Header -->
    <div class="text-center">
      <h1 class="text-3xl font-bold text-gray-900 mb-2">Our Products</h1>
      <p class="text-gray-600">Discover amazing products at great prices</p>
    </div>

    <!-- Filters -->
    <div class="bg-white rounded-lg shadow p-6">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <!-- Search -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Search</label>
          <input
            v-model="filters.search"
            type="text"
            placeholder="Search products..."
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            @input="debouncedSearch"
          />
        </div>

        <!-- Category Filter -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Category</label>
          <select
            v-model="filters.category"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="applyFilters"
          >
            <option value="">All Categories</option>
            <option v-for="category in categories" :key="category.id" :value="category.slug">
              {{ category.name }}
            </option>
          </select>
        </div>

        <!-- Sort Options -->
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Sort by</label>
          <select
            v-model="filters.sortBy"
            class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
            @change="applyFilters"
          >
            <option value="created_at">Newest</option>
            <option value="name">Name</option>
            <option value="price">Price</option>
          </select>
        </div>
      </div>

      <div class="mt-4">
        <button
          @click="clearFilters"
          class="px-4 py-2 text-sm text-blue-600 hover:text-blue-800 hover:underline"
        >
          Clear Filters
        </button>
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
      <ProductSkeleton v-for="n in 8" :key="n" />
    </div>

    <!-- Products Grid -->
    <div v-else-if="products.length > 0" class="space-y-6">
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        <ProductCard
          v-for="product in products"
          :key="product.id"
          :product="product"
          @added-to-cart="handleAddedToCart"
        />
      </div>

      <!-- Pagination -->
      <Pagination
        :current-page="pagination.current_page"
        :total-pages="pagination.total_pages"
        :has-next="pagination.has_next"
        :has-prev="pagination.has_prev"
        @page-change="goToPage"
      />

      <!-- Results Info -->
      <div class="text-center text-gray-600">
        Showing {{ (pagination.current_page - 1) * pagination.per_page + 1 }} to
        {{ Math.min(pagination.current_page * pagination.per_page, pagination.total_items) }}
        of {{ pagination.total_items }} products
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="text-center py-12">
      <div class="text-6xl mb-4">🔍</div>
      <h3 class="text-xl font-semibold text-gray-900 mb-2">No products found</h3>
      <p class="text-gray-600 mb-6">Try adjusting your filters or search terms.</p>
      <button @click="clearFilters" class="btn-primary">
        Clear Filters
      </button>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import ProductCard from '../components/ProductCard.vue'
import ProductSkeleton from '../components/ProductSkeleton.vue'
import Pagination from '../components/Pagination.vue'
import { productService } from '../services/api'

export default {
  name: 'ProductList',
  components: {
    ProductCard,
    ProductSkeleton,
    Pagination
  },
  setup() {
    const route = useRoute()
    const router = useRouter()
    
    const products = ref([])
    const categories = ref([])
    const loading = ref(false)
    const isUpdatingQuery = ref(false) // Flag to prevent infinite loops
    const pagination = ref({
      current_page: 1,
      per_page: 12,
      total_items: 0,
      total_pages: 0,
      has_next: false,
      has_prev: false
    })

    const filters = ref({
      search: '',
      category: '',
      minPrice: null,
      maxPrice: null,
      sortBy: 'created_at',
      sortOrder: 'desc'
    })

    // Initialize state from URL query parameters
    const initFromQuery = () => {
      const query = route.query
      
      if (query.page) {
        pagination.value.current_page = parseInt(query.page) || 1
      }
      
      if (query.search) {
        filters.value.search = query.search
      }
      
      if (query.category) {
        filters.value.category = query.category
      }
      
      if (query.sort_by) {
        filters.value.sortBy = query.sort_by
      }
      
      if (query.sort_order) {
        filters.value.sortOrder = query.sort_order
      }
      
      if (query.min_price) {
        filters.value.minPrice = parseFloat(query.min_price)
      }
      
      if (query.max_price) {
        filters.value.maxPrice = parseFloat(query.max_price)
      }
    }

    // Update URL query parameters
    const updateQueryParams = () => {
      isUpdatingQuery.value = true
      const query = {}
      
      if (pagination.value.current_page > 1) {
        query.page = pagination.value.current_page.toString()
      }
      
      if (filters.value.search) {
        query.search = filters.value.search
      }
      
      if (filters.value.category) {
        query.category = filters.value.category
      }
      
      if (filters.value.sortBy !== 'created_at') {
        query.sort_by = filters.value.sortBy
      }
      
      if (filters.value.sortOrder !== 'desc') {
        query.sort_order = filters.value.sortOrder
      }
      
      if (filters.value.minPrice) {
        query.min_price = filters.value.minPrice.toString()
      }
      
      if (filters.value.maxPrice) {
        query.max_price = filters.value.maxPrice.toString()
      }
      
      // Update URL without triggering navigation
      router.replace({ query }).then(() => {
        // Reset flag after a short delay to allow route watcher to process
        setTimeout(() => {
          isUpdatingQuery.value = false
        }, 100)
      })
    }

    // Debounced search
    let searchTimeout = null
    const debouncedSearch = () => {
      clearTimeout(searchTimeout)
      searchTimeout = setTimeout(() => {
        pagination.value.current_page = 1
        updateQueryParams()
        loadProducts()
      }, 500)
    }

    const loadProducts = async () => {
      loading.value = true
      try {
        const params = {
          page: pagination.value.current_page,
          per_page: pagination.value.per_page,
          ...filters.value
        }

        // Remove null/empty values
        Object.keys(params).forEach(key => {
          if (params[key] === null || params[key] === '') {
            delete params[key]
          }
        })

        const response = await productService.getProducts(params)
        products.value = response.data
        pagination.value = response.pagination
      } catch (error) {
        products.value = []
      } finally {
        loading.value = false
      }
    }

    const loadCategories = async () => {
      try {
        const response = await productService.getCategories()
        categories.value = response.data
      } catch (error) {
        // Silently handle category loading errors
      }
    }

    const applyFilters = () => {
      pagination.value.current_page = 1
      updateQueryParams()
      loadProducts()
    }

    const clearFilters = () => {
      filters.value = {
        search: '',
        category: '',
        minPrice: null,
        maxPrice: null,
        sortBy: 'created_at',
        sortOrder: 'desc'
      }
      pagination.value.current_page = 1
      updateQueryParams()
      loadProducts()
    }

    const goToPage = (page) => {
      if (page >= 1 && page <= pagination.value.total_pages) {
        pagination.value.current_page = page
        updateQueryParams()
        loadProducts()
        window.scrollTo({ top: 0, behavior: 'smooth' })
      }
    }

    const handleAddedToCart = (product) => {
      // Could show a toast notification here
    }

    // Watch for route query changes (browser back/forward)
    watch(() => route.query, (newQuery) => {
      // Skip if we're updating the query ourselves
      if (isUpdatingQuery.value) {
        return
      }
      initFromQuery()
      loadProducts()
    }, { deep: true })

    onMounted(() => {
      initFromQuery()
      loadCategories()
      loadProducts()
    })

    return {
      products,
      categories,
      loading,
      pagination,
      filters,
      debouncedSearch,
      applyFilters,
      clearFilters,
      goToPage,
      handleAddedToCart
    }
  }
}
</script>
