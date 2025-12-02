<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

class OrderController extends Controller
{
    /**
     * Store a newly created order.
     */
    public function store(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'items' => 'required|array|min:1',
            'items.*.product_id' => 'required|integer',
            'items.*.quantity' => 'required|integer|min:1',
        ]);

        try {
            DB::beginTransaction();

            // 1. Validate stock for all items
            $errors = [];
            foreach ($request->items as $item) {
                $product = $this->getProductFromCatalog($item['product_id']);

                if (!$product) {
                    $errorMsg = "Product with ID {$item['product_id']} not found";
                    $errors[] = $errorMsg;
                    continue;
                }

                // Convert stock to int if it's a string
                $stock = is_string($product['stock']) ? (int) $product['stock'] : $product['stock'];

                if ($stock < $item['quantity']) {
                    $errorMsg = "Insufficient stock for {$product['name']}. Available: {$stock}, Requested: {$item['quantity']}";
                    $errors[] = $errorMsg;
                }
            }

            if (!empty($errors)) {
                return response()->json([
                    'success' => false,
                    'error' => [
                        'code' => 'INSUFFICIENT_STOCK',
                        'message' => 'Some items are out of stock',
                        'details' => $errors
                    ]
                ], 422);
            }

            // 2. Calculate total and create order
            $totalAmount = 0;
            $orderItems = [];

            foreach ($request->items as $item) {
                $product = $this->getProductFromCatalog($item['product_id']);
                
                if (!$product) {
                    throw new \Exception("Product with ID {$item['product_id']} not found");
                }

                // Convert price to float if it's a string
                $price = is_string($product['price']) ? (float) $product['price'] : $product['price'];

                $subtotal = $price * $item['quantity'];
                $totalAmount += $subtotal;

                $orderItems[] = [
                    'product_id' => $item['product_id'],
                    'product_name' => $product['name'],
                    'quantity' => $item['quantity'],
                    'unit_price' => $price,
                ];
            }

            // 3. Create order
            $order = Order::create([
                'customer_email' => $request->email,
                'total_amount' => (float) $totalAmount,
                'status' => 'confirmed',
            ]);

            // 4. Create order items
            foreach ($orderItems as $itemData) {
                $order->orderItems()->create($itemData);
            }

            DB::commit();

            // 5. Send order confirmation email
            $this->sendOrderConfirmationEmail($order);

            return response()->json([
                'success' => true,
                'data' => [
                    'order_id' => $order->id,
                    'order_number' => '#'.$order->id,
                    'total_amount' => $order->total_amount,
                    'customer_email' => $order->customer_email,
                    'status' => $order->status,
                    'created_at' => $order->created_at,
                ],
                'message' => 'Order placed successfully'
            ], 201);

        } catch (\Exception $e) {
            DB::rollBack();

            $errorMessage = 'Failed to process order. Please try again.';
            
            // In development, include more details
            if (config('app.debug')) {
                $errorMessage .= ' Error: ' . $e->getMessage();
                $errorMessage .= ' (File: ' . basename($e->getFile()) . ':' . $e->getLine() . ')';
            }

            return response()->json([
                'success' => false,
                'error' => [
                    'code' => 'ORDER_FAILED',
                    'message' => $errorMessage,
                    'debug' => config('app.debug') ? [
                        'exception' => get_class($e),
                        'message' => $e->getMessage(),
                        'file' => $e->getFile(),
                        'line' => $e->getLine()
                    ] : null
                ]
            ], 500);
        }
    }

    /**
     * Display the specified order.
     */
    public function show($id)
    {
        // Explicitly find the order to ensure it's loaded correctly
        $order = Order::with('orderItems')->find($id);

        if (!$order) {
            return response()->json([
                'success' => false,
                'message' => 'Order not found'
            ], 404);
        }

        // Build response data explicitly to ensure relationships are included
        $orderData = [
            'id' => $order->id,
            'customer_email' => $order->customer_email,
            'total_amount' => (float) $order->total_amount,
            'status' => $order->status,
            'created_at' => $order->created_at,
            'updated_at' => $order->updated_at,
            'order_items' => $order->orderItems->map(function ($item) {
                return [
                    'id' => $item->id,
                    'order_id' => $item->order_id,
                    'product_id' => $item->product_id,
                    'product_name' => $item->product_name,
                    'quantity' => (int) $item->quantity,
                    'unit_price' => (float) $item->unit_price,
                    'created_at' => $item->created_at,
                    'updated_at' => $item->updated_at,
                ];
            })->toArray(),
        ];

        return response()->json([
            'success' => true,
            'data' => $orderData,
            'message' => 'Order retrieved successfully'
        ]);
    }

    /**
     * Get product data from Catalog Service.
     */
    private function getProductFromCatalog($productId)
    {
        try {
            $catalogUrl = env('CATALOG_SERVICE_URL', 'http://localhost:8001');
            $url = "{$catalogUrl}/api/products/{$productId}";

            $response = Http::timeout(10)->get($url);

            if ($response->successful()) {
                $responseData = $response->json();

                if (isset($responseData['data']) && $responseData['success']) {
                    return $responseData['data'];
                }
            }
        } catch (\Exception $e) {
            // Silently handle errors
        }

        return null;
    }

    /**
     * Send order confirmation email via Email Service.
     */
    private function sendOrderConfirmationEmail(Order $order)
    {
        try {
            $emailServiceUrl = env('EMAIL_SERVICE_URL', 'http://localhost:8003');
            $url = "{$emailServiceUrl}/api/send-order-confirmation";

            $emailData = [
                'order_id' => $order->id,
                'customer_email' => $order->customer_email,
                'order_data' => $order->load('orderItems')->toArray(),
            ];

            Http::timeout(10)->post($url, $emailData);
        } catch (\Exception $e) {
            // Don't fail the order if email fails - order is still valid
        }
    }
}
