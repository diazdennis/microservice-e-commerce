<template>
  <div class="bg-white rounded-lg shadow-md overflow-hidden">
    <div class="loading-skeleton h-48"></div>
    <div class="p-4 space-y-3">
      <div class="loading-skeleton h-6 w-3/4"></div>
      <div class="loading-skeleton h-4 w-full"></div>
      <div class="loading-skeleton h-4 w-2/3"></div>
      <div class="flex gap-2">
        <div class="loading-skeleton h-8 flex-1"></div>
        <div class="loading-skeleton h-8 flex-1"></div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ProductSkeleton'
}
</script>

<style scoped>
.loading-skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
  border-radius: 4px;
}

@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}
</style>

