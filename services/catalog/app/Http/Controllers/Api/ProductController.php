<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Product;
use Illuminate\Http\Request;

class ProductController extends Controller
{
    /**
     * Display a listing of products with filtering and pagination.
     */
    public function index(Request $request)
    {
        $query = Product::with('category');

        // Apply filters
        if ($request->has('category')) {
            $query->byCategory($request->category);
        }

        if ($request->has('min_price') || $request->has('max_price')) {
            $query->byPriceRange($request->min_price, $request->max_price);
        }

        if ($request->has('search')) {
            $query->search($request->search);
        }

        // Apply sorting - accept both camelCase and snake_case
        $sortBy = $request->get('sort_by') ?? $request->get('sortBy', 'created_at');
        $sortOrder = $request->get('sort_order') ?? $request->get('sortOrder', 'desc');
        
        // Normalize sort order
        $sortOrder = strtolower($sortOrder);
        $sortOrder = in_array($sortOrder, ['asc', 'desc']) ? $sortOrder : 'desc';
        
        // Apply sorting with explicit table name to avoid ambiguity
        $allowedSortFields = ['name', 'price', 'created_at'];
        if (in_array($sortBy, $allowedSortFields)) {
            $query->orderBy('products.' . $sortBy, $sortOrder);
        } else {
            $query->orderBy('products.created_at', $sortOrder);
        }

        // Paginate
        $perPage = $request->get('per_page', 12);
        $perPage = min(max($perPage, 1), 50); // Limit between 1-50

        $products = $query->paginate($perPage);

        // Format response
        $response = [
            'success' => true,
            'data' => $products->items(),
            'pagination' => [
                'current_page' => $products->currentPage(),
                'per_page' => $products->perPage(),
                'total_items' => $products->total(),
                'total_pages' => $products->lastPage(),
                'has_next' => $products->hasMorePages(),
                'has_prev' => $products->currentPage() > 1,
            ],
            'message' => 'Products retrieved successfully'
        ];

        return response()->json($response);
    }

    /**
     * Display the specified product.
     */
    public function show($id)
    {
        $product = Product::with('category')->find($id);

        if (!$product) {
            return response()->json([
                'success' => false,
                'message' => 'Product not found'
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $product,
            'message' => 'Product retrieved successfully'
        ]);
    }
}
